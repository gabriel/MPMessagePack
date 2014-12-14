//
//  MPMessagePackRPClient.m
//  MPMessagePack
//
//  Created by Gabriel on 12/12/14.
//  Copyright (c) 2014 Gabriel Handford. All rights reserved.
//

#import "MPMessagePackClient.h"

#import "MPMessagePack.h"

@interface MPMessagePackClient ()
@property MPMessagePackClientOptions options;
@property (nonatomic) MPMessagePackClientStatus status;
@property NSInputStream *inputStream;
@property NSOutputStream *outputStream;

@property NSMutableArray *queue;
@property NSUInteger writeIndex;

@property NSMutableDictionary *requests;

@property NSMutableData *readBuffer;
@property NSUInteger messageId;

@property (copy) MPCompletion openCompletion;
@end

@implementation MPMessagePackClient

- (instancetype)init {
  return [self initWithOptions:0];
}

- (instancetype)initWithOptions:(MPMessagePackClientOptions)options {
  if ((self = [super init])) {
    _options = options;
    _queue = [NSMutableArray array];
    _readBuffer = [NSMutableData data];
    _requests = [NSMutableDictionary dictionary];
  }
  return self;
}

- (instancetype)initWithInputStream:(NSInputStream *)inputStream outputStream:(NSOutputStream *)outputStream options:(MPMessagePackClientOptions)options {
  if ((self = [self initWithOptions:options])) {
    _inputStream = inputStream;
    _outputStream = outputStream;
    _inputStream.delegate = self;
    _outputStream.delegate = self;
    self.status = MPMessagePackClientStatusOpen;
  }
  return self;
}

- (void)openWithHost:(NSString *)host port:(UInt32)port completion:(MPCompletion)completion {
  _openCompletion = completion;
  if (_status == MPMessagePackClientStatusOpen || _status == MPMessagePackClientStatusOpening) {
    MPErr(@"Already open");
    completion(nil); // TODO: Maybe something better to do here
    return;
  }
  self.status = MPMessagePackClientStatusOpening;
  CFReadStreamRef readStream;
  CFWriteStreamRef writeStream;
  CFStreamCreatePairWithSocketToHost(NULL, (__bridge CFStringRef)host, port, &readStream, &writeStream);
  
  _inputStream = (__bridge_transfer NSInputStream *)readStream;
  _outputStream = (__bridge_transfer NSOutputStream *)writeStream;
  _inputStream.delegate = self;
  _outputStream.delegate = self;
  [_inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
  [_outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
  [_inputStream open];
  [_outputStream open];
  MPDebug(@"Opening streams");
}

- (void)close {
  [_inputStream close];
  [_inputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
  _inputStream = nil;
  [_outputStream close];
  [_outputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
  _outputStream = nil;
  
  self.status = MPMessagePackClientStatusClosed;
}

- (void)sendRequestWithMethod:(NSString *)method params:(id)params completion:(MPRequestCompletion)completion {
  NSNumber *messageId = @(++_messageId);
  id request = @[@(0), messageId, method, params];
  _requests[messageId] = completion;
  [self writeObject:request];
}

- (void)sendResponseWithResult:(id)result error:(id)error messageId:(NSUInteger)messageId {
  id request = @[@(1), @(messageId), error, result];
  [self writeObject:request];
}

- (void)writeObject:(id)object {
  NSError *error = nil;
  NSData *data = [MPMessagePackWriter writeObject:object options:0 error:&error];
  [_queue addObject:data];
  [self checkQueue];
}

- (void)checkQueue {
  if (![_outputStream hasSpaceAvailable]) return;
  
  NSMutableData *data = [_queue firstObject];
  if (!data) return;
  
  // TODO: Buffer size
  NSUInteger length = (((data.length - _writeIndex) >= 1024) ? 1024 : (data.length - _writeIndex));
  uint8_t buffer[length];
  [data getBytes:buffer length:length];
  _writeIndex += [_outputStream write:(const uint8_t *)buffer maxLength:length];
}

- (void)checkReadBuffer {
  MPMessagePackReader *reader = [[MPMessagePackReader alloc] initWithData:_readBuffer]; // TODO: Fix init every check
  
  if ((_options & MPMessagePackClientOptionsFramed) != 0) {
    NSNumber *frameSize = [reader readObject:nil];
    if (!frameSize) return;
    if (_readBuffer.length < (frameSize.unsignedIntegerValue + reader.index)) return;
  }
  id obj = [reader readObject:nil];
  if (!obj) return;
  if (![obj isKindOfClass:NSArray.class] || [(NSArray *)obj count] != 4) {
    [self handleError:MPMakeError(500, @"Received an invalid response: %@", obj) fatal:YES];
    return;
  }
  
  NSArray *message = (NSArray *)obj;
  NSInteger type = [message[0] integerValue];
  NSNumber *messageId = message[1];
  
  if (type == 0) {
    NSString *method = message[1];
    id params = message[2];
    self.requestHandler(method, params, ^(NSError *error, id result) {
      [self sendResponseWithResult:result error:error messageId:messageId.unsignedIntegerValue];
    });
  } else if (type == 1) {
    id error = message[2];
    id result = message[3];
    MPRequestCompletion completion = _requests[messageId];
    if (!completion) {
      [self handleError:MPMakeError(501, @"Got response for unknown request") fatal:NO];
    } else {
      [_requests removeObjectForKey:messageId];
      completion(error, result);
    }
  } else if (type == 2) {
    
  }
  
  _readBuffer = [[_readBuffer subdataWithRange:NSMakeRange(reader.index, _readBuffer.length - reader.index)] mutableCopy]; // TODO: Fix mutable copy
  [self checkReadBuffer];
}

- (void)setStatus:(MPMessagePackClientStatus)status {
  if (_status != status) {
    _status = status;
    [self.delegate client:self didChangeStatus:_status];
  }
}

- (void)handleError:(NSError *)error fatal:(BOOL)fatal {
  MPErr(@"Error: %@", error);
  [self.delegate client:self didError:error fatal:fatal];
  if (fatal) {
    [self close];
  }
}

- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)event {
  MPDebug(@"Stream event: %d", (int)event);
  switch (event) {
    case NSStreamEventNone: break;
    case NSStreamEventOpenCompleted: {
      if (_status != MPMessagePackClientStatusOpening) {
        MPErr(@"Status wasn't opening and we got an open completed event");
      }
      self.status = MPMessagePackClientStatusOpen;
      if (self.openCompletion) {
        self.openCompletion(nil);
        self.openCompletion = nil;
      }
      break;
    }
    case NSStreamEventHasSpaceAvailable: {
      [self checkQueue];
      break;
    }
    case NSStreamEventHasBytesAvailable: {
      // TODO: Buffer size
      uint8_t buffer[1024];
      NSInteger length = [_inputStream read:buffer maxLength:1024];
      [_readBuffer appendBytes:buffer length:length];
      [self checkReadBuffer];
      break;
    }
    case NSStreamEventErrorOccurred: {
      if (self.openCompletion) {
        self.openCompletion(stream.streamError);
        self.openCompletion = nil;
      } else {
        [self handleError:stream.streamError fatal:YES];
      }
      break;
    }
    case NSStreamEventEndEncountered: {
      NSData *data = [_outputStream propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
      if (!data) {
        MPErr(@"No data from end event");
      } else {
        [_readBuffer appendData:data];
        [self checkReadBuffer];
      }
      [self close];
      break;
    }
  }
}

@end
