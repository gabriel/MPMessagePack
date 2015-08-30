//
//  MPRPCProtocol.m
//  MPMessagePack
//
//  Created by Gabriel on 8/30/15.
//  Copyright (c) 2015 Gabriel Handford. All rights reserved.
//

#import "MPRPCProtocol.h"

@implementation MPRPCProtocol

- (NSData *)encodeRequestWithMethod:(NSString *)method params:(NSArray *)params messageId:(NSInteger)messageId options:(MPMessagePackWriterOptions)options encodeError:(NSError **)encodeError {
  NSArray *request = @[@(0), @(messageId), method, params ? params : NSNull.null];
  return [MPMessagePackWriter writeObject:request options:options error:encodeError];
}

- (NSData *)encodeResponseWithResult:(id)result error:(id)error messageId:(NSInteger)messageId options:(MPMessagePackWriterOptions)options encodeError:(NSError **)encodeError {
  NSArray *response = @[@(1), @(messageId), error ? error : NSNull.null, result ? result : NSNull.null];
  return [MPMessagePackWriter writeObject:response options:options error:encodeError];
}

@end
