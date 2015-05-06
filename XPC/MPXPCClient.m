//
//  MPXPCClient.m
//  MPMessagePack
//
//  Created by Gabriel on 5/5/15.
//  Copyright (c) 2015 Gabriel Handford. All rights reserved.
//

#import "MPXPCClient.h"

#import "MPDefines.h"
#import "NSArray+MPMessagePack.h"
#import "NSData+MPMessagePack.h"
#import "MPXPCProtocol.h"
#import "MPMessagePackClient.h"

@interface MPXPCClient ()
@property NSString *serviceName;
@property BOOL priviledged;

@property xpc_connection_t connection;
@property NSInteger messageId;
@end

@implementation MPXPCClient

- (instancetype)initWithServiceName:(NSString *)serviceName priviledged:(BOOL)priviledged {
  if ((self = [super init])) {
    _serviceName = serviceName;
    _priviledged = priviledged;
  }
  return self;
}

- (BOOL)connect:(NSError **)error {
  _connection = xpc_connection_create_mach_service([_serviceName UTF8String], NULL, _priviledged ? XPC_CONNECTION_MACH_SERVICE_PRIVILEGED : 0);

  if (!_connection) {
    if (error) *error = MPMakeError(-1, @"Failed to create XPC connection");
    return NO;
  }

  MPWeakSelf wself = self;
  xpc_connection_set_event_handler(_connection, ^(xpc_object_t event) {
    xpc_type_t type = xpc_get_type(event);
    if (type == XPC_TYPE_ERROR) {
      if (event == XPC_ERROR_CONNECTION_INTERRUPTED) {
        // Interrupted
      } else if (event == XPC_ERROR_CONNECTION_INVALID) {
        wself.connection = nil;
      } else {
        // Unknown error
      }
    } else {
      // Unexpected event
    }
  });

  xpc_connection_resume(_connection);
  return YES;
}

- (void)sendRequest:(NSString *)method params:(NSArray *)params completion:(void (^)(NSError *error, id value))completion {
  if (!_connection) {
    NSError *error = nil;
    if (![self connect:&error]) {
      completion(error, nil);
      return;
    }
  }

  NSError *error = nil;
  xpc_object_t message = [MPXPCProtocol XPCObjectFromRequestWithMethod:method messageId:++_messageId params:params error:&error];
  if (!message) {
    completion(error, nil);
    return;
  }

  xpc_connection_send_message_with_reply(_connection, message, dispatch_get_main_queue(), ^(xpc_object_t event) {
    //DDLogDebug(@"Reply: %@", event);
    NSError *error = nil;
    size_t length = 0;
    const void *buffer = xpc_dictionary_get_data(event, "data", &length);
    NSData *dataResponse = [NSData dataWithBytes:buffer length:length];

    id response = [dataResponse mp_array:&error];

    if (!response) {
      completion(error, nil);
      return;
    }
    if (!MPVerifyResponse(response, &error)) {
      completion(error, nil);
      return;
    }
    NSDictionary *errorDict = MPIfNull(response[2], nil);
    if (errorDict) {
      error = MPErrorFromErrorDict(_serviceName, errorDict);
      completion(error, nil);
    } else {
      completion(nil, MPIfNull(response[3], nil));
    }
  });
}

@end