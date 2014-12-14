//
//  MPMessagePackServer.m
//  MPMessagePack
//
//  Created by Gabriel on 12/13/14.
//  Copyright (c) 2014 Gabriel Handford. All rights reserved.
//

#import "MPMessagePackServer.h"

#import "MPMessagePackClient.h"

#include <sys/socket.h>
#include <netinet/in.h>
#include <unistd.h>

NSString *const MPMessagePackServerErrorDomain = @"MPMessagePackServerErrorDomain";

@interface MPMessagePackServer ()
@property CFSocketRef socket;
@property MPMessagePackClient *client;
//@property NSNetService *netService;
@end

@implementation MPMessagePackServer

- (void)connectionFromAddress:(NSData *)addr inputStream:(NSInputStream *)inputStream outputStream:(NSOutputStream *)outputStream {
  _client = [[MPMessagePackClient alloc] initWithInputStream:inputStream outputStream:outputStream options:1];
  _client.requestHandler = _requestHandler;
}

- (void)setRequestHandler:(MPRequestHandler)requestHandler {
  _requestHandler = requestHandler;
  _client.requestHandler = requestHandler;
}

static void MPMessagePackServerAcceptCallBack(CFSocketRef socket, CFSocketCallBackType type, CFDataRef address, const void *data, void *info) {
  MPMessagePackServer *server = (__bridge MPMessagePackServer *)info;
  MPDebug(@"Accept callback type: %d", (int)type);
  if (kCFSocketAcceptCallBack == type) {
    CFSocketNativeHandle nativeSocketHandle = *(CFSocketNativeHandle *)data;
    uint8_t name[SOCK_MAXADDRLEN];
    socklen_t namelen = sizeof(name);
    NSData *peer = nil;
    if (0 == getpeername(nativeSocketHandle, (struct sockaddr *)name, &namelen)) {
      peer = [NSData dataWithBytes:name length:namelen];
    }
    CFReadStreamRef readStream = NULL;
    CFWriteStreamRef writeStream = NULL;
    CFStreamCreatePairWithSocket(kCFAllocatorDefault, nativeSocketHandle, &readStream, &writeStream);
    if (readStream && writeStream) {
      CFReadStreamSetProperty(readStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
      CFWriteStreamSetProperty(writeStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
      [server connectionFromAddress:peer inputStream:(__bridge NSInputStream *)readStream outputStream:(__bridge NSOutputStream *)writeStream];
    } else {
      close(nativeSocketHandle);
    }
    if (readStream) {
      CFRelease(readStream);
      readStream = nil;
    }
    if (writeStream) {
      CFRelease(writeStream);
      writeStream = nil;
    }
  }
}

- (BOOL)openWithPort:(uint16_t)port error:(NSError **)error {
  CFSocketContext socketContext = {0, (__bridge void *)(self), NULL, NULL, NULL};
  _socket = CFSocketCreate(kCFAllocatorDefault, PF_INET, SOCK_STREAM, IPPROTO_TCP, kCFSocketAcceptCallBack, (CFSocketCallBack)&MPMessagePackServerAcceptCallBack, &socketContext);
  
  if (!_socket) {
    if (_socket) CFRelease(_socket);
    _socket = NULL;
    *error = MPMakeError(errno, @"Couldn't create socket");
    return NO;
  }
  
  int yes = 1;
  setsockopt(CFSocketGetNative(_socket), SOL_SOCKET, SO_REUSEADDR, (void *)&yes, sizeof(yes));
  
  // Set up the IPv4 endpoint; if port is 0, this will cause the kernel to choose a port for us
  struct sockaddr_in addr4;
  memset(&addr4, 0, sizeof(addr4));
  addr4.sin_len = sizeof(addr4);
  addr4.sin_family = AF_INET;
  addr4.sin_port = htons(port);
  addr4.sin_addr.s_addr = htonl(INADDR_ANY);
  NSData *address4 = [NSData dataWithBytes:&addr4 length:sizeof(addr4)];
  
  if (kCFSocketSuccess != CFSocketSetAddress(_socket, (CFDataRef)address4)) {
    if (_socket) {
      CFRelease(_socket);
      _socket = NULL;
    }
    *error = MPMakeError(501, @"Couldn't bind socket");
    return NO;
  }
  
  CFRunLoopSourceRef source4 = CFSocketCreateRunLoopSource(kCFAllocatorDefault, _socket, 0);
  CFRunLoopAddSource(CFRunLoopGetCurrent(), source4, kCFRunLoopCommonModes);
  CFRelease(source4);
  
//  _netService = [[NSNetService alloc] initWithDomain: @"local." type:@"_keybase._tcp." name:@"Keybase" port:port];
//  if (_netService) {
//    //_netService.delegate = self;
//    //_netService publishWithOptions:
//  } else {
//    // Error
//  }
  
  MPDebug(@"Created socket");
  return YES;
}

- (void)close {
  if (_socket) {
    CFSocketInvalidate(_socket);
    _socket = NULL;
  }
}

@end
