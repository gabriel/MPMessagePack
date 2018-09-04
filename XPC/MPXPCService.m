//
//  MPMessagePackXPC.m
//  MPMessagePack
//
//  Created by Gabriel on 5/5/15.
//  Copyright (c) 2015 Gabriel Handford. All rights reserved.
//

#import "MPXPCService.h"

#import "NSData+MPMessagePack.h"
#import "NSArray+MPMessagePack.h"
#import "MPXPCProtocol.h"
#import "MPDefines.h"

@interface MPXPCService () <NSXPCListenerDelegate>
@property xpc_connection_t connection;
@end

#import <syslog.h>

void MPSysLog(NSString *msg, ...) {
  va_list args;
  va_start(args, msg);

  NSString *string = [[NSString alloc] initWithFormat:msg arguments:args];

  va_end(args);

  NSLog(@"%@", string);
  syslog(LOG_NOTICE, "%s", [string UTF8String]);
}

@implementation MPXPCService

- (void)listen:(xpc_connection_t)service {
  [self listen:service codeRequirement:nil];
}

- (void)listen:(xpc_connection_t)service codeRequirement:(NSString *)codeRequirement {
  xpc_connection_set_event_handler(service, ^(xpc_object_t connection) {
    if (codeRequirement) {
      pid_t pid = xpc_connection_get_pid(connection);
      NSError *error = nil;
      BOOL ok = [self checkCodeRequirement:codeRequirement pid:pid error:&error];
      if (!ok) {
        MPSysLog(@"Failed to pass code requirement: %@", error);
        xpc_connection_cancel(connection);
        return;
      }
    }
    [self setEventHandler:connection];
  });

  xpc_connection_resume(service);
}

- (void)setEventHandler:(xpc_object_t)connection {
  xpc_connection_set_event_handler(connection, ^(xpc_object_t event) {
    xpc_type_t type = xpc_get_type(event);

    if (type == XPC_TYPE_ERROR) {
      if (event == XPC_ERROR_CONNECTION_INVALID) {
        // The client process on the other end of the connection has either
        // crashed or cancelled the connection. After receiving this error,
        // the connection is in an invalid state, and you do not need to
        // call xpc_connection_cancel(). Just tear down any associated state
        // here.
      } else if (event == XPC_ERROR_TERMINATION_IMMINENT) {
        // Handle per-connection termination cleanup.
      } else {
        MPSysLog(@"Error: %@", event);
      }
    } else {
      xpc_connection_t remote = xpc_dictionary_get_remote_connection(event);
      [self handleEvent:event remote:remote completion:^(NSError *error, NSData *data) {
        if (error) {
          xpc_object_t reply = xpc_dictionary_create_reply(event);
          xpc_dictionary_set_string(reply, "error", [[error localizedDescription] UTF8String]);
          xpc_connection_send_message(remote, reply);
        } else {
          xpc_object_t reply = xpc_dictionary_create_reply(event);
          xpc_dictionary_set_data(reply, "data", [data bytes], [data length]);
          xpc_connection_send_message(remote, reply);
        }
      }];
    }
  });

  xpc_connection_resume(connection);
}

- (void)handleEvent:(xpc_object_t)event remote:(xpc_connection_t)remote completion:(void (^)(NSError *error, NSData *data))completion {
  [MPXPCProtocol requestFromXPCObject:event completion:^(NSError *error, NSNumber *messageId, NSString *method, NSArray *params) {
    if (error) {
      MPSysLog(@"Request error: %@", error);
      completion(error, nil);
    } else {
      [self handleRequestWithMethod:method params:params messageId:messageId remote:remote completion:^(NSError *error, id value) {
        if (error) {
          NSDictionary *errorDict = @{@"code": @(error.code), @"desc": error.localizedDescription};
          NSArray *response = @[@(1), messageId, errorDict, NSNull.null];
          NSData *dataResponse = [response mp_messagePack];
          completion(nil, dataResponse);
        } else {
          NSArray *response = @[@(1), messageId, NSNull.null, (value ? value : NSNull.null)];
          NSData *dataResponse = [response mp_messagePack];
          completion(nil, dataResponse);
        }
      }];
    }
  }];
}

- (void)handleRequestWithMethod:(NSString *)method params:(NSArray *)params messageId:(NSNumber *)messageId remote:(xpc_connection_t)remote completion:(void (^)(NSError *error, id value))completion {
  completion(MPMakeError(MPXPCErrorCodeUnknownRequest, @"Unkown request"), nil);
}

- (BOOL)checkCodeRequirement:(NSString *)codeRequirement path:(NSURL *)path error:(NSError **)error {
  SecStaticCodeRef staticCode = NULL;
  OSStatus statusCodePath = SecStaticCodeCreateWithPath((__bridge CFURLRef)path, kSecCSDefaultFlags, &staticCode);
  if (statusCodePath != errSecSuccess) {
    *error = MPMakeError(statusCodePath, @"Failed to create code path");
    return NO;
  }
  // Code requirement must start with 'anchor apple'.
  // See https://www.okta.com/security-blog/2018/06/issues-around-third-party-apple-code-signing-checks/
  if (![codeRequirement hasPrefix:@"anchor apple"]) {
    *error = MPMakeError(-1, @"Code requirement must start with 'anchor apple'");
    return NO;
  }
  SecRequirementRef requirement = NULL;
  OSStatus statusCreate = SecRequirementCreateWithString((__bridge CFStringRef)codeRequirement, kSecCSDefaultFlags, &requirement);
  if (statusCreate != errSecSuccess) {
    *error = MPMakeError(statusCreate, @"Failed to create requirement");
    return NO;
  }
  // It is important to have all these flags present.
  // See https://www.okta.com/security-blog/2018/06/issues-around-third-party-apple-code-signing-checks/
  OSStatus statusCheck = SecStaticCodeCheckValidityWithErrors(staticCode, kSecCSDefaultFlags | kSecCSCheckNestedCode | kSecCSCheckAllArchitectures | kSecCSEnforceRevocationChecks, requirement, NULL);
  if (statusCheck != errSecSuccess) {
    *error = MPMakeError(statusCheck, @"Binary failed code requirement");
    return NO;
  }
  return YES;
}

/*!
 Check code requirement for process id (from an xpc connection).

 "The OS’s process ID space is relatively small, which means that process IDs are commonly reused.
 There is a recommended alternative to process IDs, namely audit tokens (audit_token_t), but you can’t use this because a critical piece of public API is missing.
 While you can do step 2 with an audit token (using kSecGuestAttributeAudit), there’s no public API to get an audit token from an XPC connection.
 Fortunately, process ID wrapping problems aren’t a real threat in this context because, if you create an XPC connection per process, you can do your checking based on the process ID of that process. If the process dies, the connection goes away and you’ll end up rechecking the process ID on the new connection."
  -- https://forums.developer.apple.com/thread/72881
 */
- (BOOL)checkCodeRequirement:(NSString *)codeRequirement pid:(pid_t)pid error:(NSError **)error {
  CFNumberRef value = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &pid);
  if (!value) {
    *error = MPMakeError(-1, @"Failed to alloc pid ref");
    return NO;
  }
  CFDictionaryRef attributes = CFDictionaryCreate(kCFAllocatorDefault, (const void **)&kSecGuestAttributePid, (const void **)&value, 1, NULL, NULL);
  if (!value) {
    *error = MPMakeError(-1, @"Failed to create sec guest attributes");
    return NO;
  }
  SecCodeRef code = NULL;
  OSStatus statusGuest = SecCodeCopyGuestWithAttributes(NULL, attributes, kSecCSDefaultFlags, &code);
  if (statusGuest != errSecSuccess) {
    *error = MPMakeError(-1, @"Failed to sec copy guest");
    return NO;
  }
  CFURLRef path = NULL;
  OSStatus statusCopy = SecCodeCopyPath(code, kSecCSDefaultFlags, &path);
  if (statusCopy != errSecSuccess) {
    *error = MPMakeError(-1, @"Failed to sec copy path");
  }

  return [self checkCodeRequirement:codeRequirement path:(__bridge NSURL *)path error:error];
}

@end
