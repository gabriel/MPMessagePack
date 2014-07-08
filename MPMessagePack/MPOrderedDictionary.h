//
//  MPOrderedDictionary.h
//  MPMessagePack
//
//  Created by Gabriel on 7/8/14.
//  Copyright (c) 2014 Gabriel Handford. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MPOrderedDictionary : NSObject <NSFastEnumeration>

- (instancetype)initWithCapacity:(NSUInteger)capacity;

@property (readonly) NSUInteger count;

- (void)setObject:(id)object forKey:(id)key;
- (id)objectForKey:(id)key;

- (void)setObject:(id)obj forKeyedSubscript:(id<NSCopying>)key;
- (id)objectForKeyedSubscript:(id)key;

- (NSData *)mp_messagePack;

@end
