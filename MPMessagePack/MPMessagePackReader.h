//
//  MPMessagePackReader.h
//  MPMessagePack
//
//  Created by Gabriel on 7/3/14.
//  Copyright (c) 2014 Gabriel Handford. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, MPMessagePackReaderOptions) {
  MPMessagePackReaderOptionsUseOrderedDictionary = 1 << 0,
};


@interface MPMessagePackReader : NSObject

@property (readonly) size_t index;

- (instancetype)initWithData:(NSData *)data;
- (instancetype)initWithData:(NSData *)data options:(MPMessagePackReaderOptions)options;

- (id)readObject:(NSError * __autoreleasing *)error;

+ (id)readData:(NSData *)data error:(NSError * __autoreleasing *)error;

+ (id)readData:(NSData *)data options:(MPMessagePackReaderOptions)options error:(NSError * __autoreleasing *)error;

@end
