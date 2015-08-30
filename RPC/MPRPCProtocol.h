//
//  MPRPCProtocol.h
//  MPMessagePack
//
//  Created by Gabriel on 8/30/15.
//  Copyright (c) 2015 Gabriel Handford. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "MPMessagePackWriter.h"

@interface MPRPCProtocol : NSObject

- (NSData *)encodeRequestWithMethod:(NSString *)method params:(NSArray *)params messageId:(NSInteger)messageId options:(MPMessagePackWriterOptions)options encodeError:(NSError **)encodeError;

- (NSData *)encodeResponseWithResult:(id)result error:(id)error messageId:(NSInteger)messageId options:(MPMessagePackWriterOptions)options encodeError:(NSError **)encodeError;

@end
