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
@property NSString *name;
@property MPMessagePackOptions options;

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
  return [self initWithName:@"" options:0];
}

- (instancetype)initWithName:(NSString *)name options:(MPMessagePackOptions)options {
  if ((self = [super init])) {
    _name = name;
    _options = options;
    _queue = [NSMutableArray array];
    _readBuffer = [NSMutableData data];
    _requests = [NSMutableDictionary dictionary];
  }
  return self;
}

- (void)setInputStream:(NSInputStream *)inputStream outputStream:(NSOutputStream *)outputStream {
  _inputStream = inputStream;
  _outputStream = outputStream;
  _inputStream.delegate = self;
  _outputStream.delegate = self;
  [_inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
  [_outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
  MPDebug(@"[%@] Opening streams", _name);
  self.status = MPMessagePackClientStatusOpening;
  [_inputStream open];
  [_outputStream open];
}

- (void)openWithHost:(NSString *)host port:(UInt32)port completion:(MPCompletion)completion {
  _openCompletion = completion;
  if (_status == MPMessagePackClientStatusOpen || _status == MPMessagePackClientStatusOpening) {
    MPErr(@"[%@] Already open", _name);
    completion(nil); // TODO: Maybe something better to do here
    return;
  }
  CFReadStreamRef readStream;
  CFWriteStreamRef writeStream;
  CFStreamCreatePairWithSocketToHost(NULL, (__bridge CFStringRef)host, port, &readStream, &writeStream);
  
  [self setInputStream:(__bridge NSInputStream *)(readStream) outputStream:(__bridge NSOutputStream *)(writeStream)];
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
  [self writeObject:request completion:^(NSError *error) { completion(error, nil); }];
}

- (void)sendResponseWithResult:(id)result error:(id)error messageId:(NSUInteger)messageId completion:(MPErrorHandler)completion {
  id request = @[@(1), @(messageId), error ? error : NSNull.null, result ? result : NSNull.null];
  [self writeObject:request completion:completion];
}

- (void)writeObject:(id)object completion:(MPErrorHandler)completion {
  NSError *error = nil;
  NSData *data = [MPMessagePackWriter writeObject:object options:0 error:&error];
  if (error) {
    completion(error);
    return;
  }
  if (_options & MPMessagePackOptionsFramed) {
    NSData *frameSize = [MPMessagePackWriter writeObject:@(data.length) options:0 error:&error];
    NSAssert(frameSize, @"Error packing frame size");
    [_queue addObject:frameSize];
  }
  NSAssert(data.length > 0, @"Data was empty");
  [_queue addObject:data];
  [self checkQueue];
}

- (void)checkQueue {
  MPDebug(@"[%@] Checking write; hasSpaceAvailable:%d, queue.count:%d, writeIndex:%d", _name, (int)[_outputStream hasSpaceAvailable], (int)_queue.count, (int)_writeIndex);
  
  if (![_outputStream hasSpaceAvailable]) return;
  
  NSMutableData *data = [_queue firstObject];
  if (!data) return;
  
  // TODO: Buffer size
  NSUInteger length = (((data.length - _writeIndex) >= 1024) ? 1024 : (data.length - _writeIndex));
  if (length == 0) return;
  
  uint8_t buffer[length];
  [data getBytes:buffer length:length];
  NSInteger bytesLength = [_outputStream write:(const uint8_t *)buffer maxLength:length];
  //MPDebug(@"[%@] Wrote %d", _name, (int)bytesLength);
  _writeIndex += bytesLength;
  
  if (_writeIndex == data.length) {
    [_queue removeObjectAtIndex:0];
    _writeIndex = 0;
    [self checkQueue];
  }
}

- (void)checkReadBuffer {
  MPDebug(@"[%@] Checking read buffer: %d", _name, (int)_readBuffer.length);
  MPMessagePackReader *reader = [[MPMessagePackReader alloc] initWithData:_readBuffer]; // TODO: Fix init every check
  
  if (_options & MPMessagePackOptionsFramed) {
    NSNumber *frameSize = [reader readObject:nil];
    if (!frameSize) return;
    if (![frameSize isKindOfClass:NSNumber.class]) {
      [self handleError:MPMakeError(502, @"[%@] Expected number for frame size. You need to have framing on for both sides?", _name) fatal:YES];
      return;
    }
    if (_readBuffer.length < (frameSize.unsignedIntegerValue + reader.index)) return;
  }
  id obj = [reader readObject:nil];
  if (!obj) return;
  if (![obj isKindOfClass:NSArray.class] || [(NSArray *)obj count] != 4) {
    [self handleError:MPMakeError(500, @"[%@] Received an invalid response: %@", _name, obj) fatal:YES];
    return;
  }
  
  NSArray *message = (NSArray *)obj;
  NSInteger type = [message[0] integerValue];
  NSNumber *messageId = message[1];
  
  if (type == 0) {
    NSString *method = message[2];
    id params = message[3];
    self.requestHandler(method, params, ^(NSError *error, id result) {
      [self sendResponseWithResult:result error:error messageId:messageId.unsignedIntegerValue completion:^(NSError *error) {
        if (error) [self.delegate client:self didError:error fatal:YES];
      }];
    });
  } else if (type == 1) {
    id error = message[2];
    id result = message[3];
    MPRequestCompletion completion = _requests[messageId];
    if (!completion) {
      [self handleError:MPMakeError(501, @"[%@] Got response for unknown request", _name) fatal:NO];
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
  MPErr(@"[%@] Error: %@", _name, error);
  [self.delegate client:self didError:error fatal:fatal];
  if (fatal) {
    [self close];
  }
}

NSString *MPNSStringFromNSStreamEvent(NSStreamEvent e) {
  NSMutableString *str = [[NSMutableString alloc] init];
  if (e & NSStreamEventOpenCompleted) [str appendString:@"NSStreamEventOpenCompleted"];
  if (e & NSStreamEventHasBytesAvailable) [str appendString:@"NSStreamEventHasBytesAvailable"];
  if (e & NSStreamEventHasSpaceAvailable) [str appendString:@"NSStreamEventHasSpaceAvailable"];
  if (e & NSStreamEventErrorOccurred) [str appendString:@"NSStreamEventErrorOccurred"];
  if (e & NSStreamEventEndEncountered) [str appendString:@"NSStreamEventEndEncountered"];
  return str;
}

- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)event {
  //MPDebug(@"[%@] Stream event: %@ (%@)", _name, MPNSStringFromNSStreamEvent(event), NSStringFromClass(stream.class));
  switch (event) {
    case NSStreamEventNone:
      break;
      
    case NSStreamEventOpenCompleted: {
      if ([stream isKindOfClass:NSOutputStream.class]) {
        if (_status != MPMessagePackClientStatusOpening) {
          MPErr(@"[%@] Status wasn't opening and we got an open completed event", _name);
        }
        self.status = MPMessagePackClientStatusOpen;
        if (self.openCompletion) {
          self.openCompletion(nil);
          self.openCompletion = nil;
        }
      }
      break;
    }
    case NSStreamEventHasSpaceAvailable: {
      [self checkQueue];
      break;
    }
    case NSStreamEventHasBytesAvailable: {
      if (stream == _inputStream) {
        // TODO: Buffer size
        uint8_t buffer[1024];
        NSInteger length = [_inputStream read:buffer maxLength:1024];
        MPDebug(@"[%@] Bytes: %d", _name, (int)length);
        [_readBuffer appendBytes:buffer length:length];
        [self checkReadBuffer];
      }
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
//      NSData *data = [_inputStream propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
//      if (!data) {
//        MPErr(@"[%@] No data from end event", _name);
//      } else {
//        [_readBuffer appendData:data];
//        [self checkReadBuffer];
//      }
      [self close];
      break;
    }
  }
}

@end
