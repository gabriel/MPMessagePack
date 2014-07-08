//
//  MPOrderedDictionary.m
//  MPMessagePack
//
//  Created by Gabriel on 7/8/14.
//  Copyright (c) 2014 Gabriel Handford. All rights reserved.
//

#import "MPOrderedDictionary.h"

#import "MPMessagePackWriter.h"

@interface MPOrderedDictionary ()
@property NSMutableArray *array;
@property NSMutableDictionary *dictionary;
@end

@implementation MPOrderedDictionary

- (instancetype)init {
  return [self initWithCapacity:10];
}

- (instancetype)initWithCapacity:(NSUInteger)capacity {
  if ((self = [super init])) {
    _array = [NSMutableArray arrayWithCapacity:capacity];
    _dictionary = [NSMutableDictionary dictionaryWithCapacity:capacity];
  }
  return self;
}

- (id)mutableCopyWithZone:(NSZone *)zone {
  MPOrderedDictionary *mutableCopy = [[MPOrderedDictionary allocWithZone:zone] init];
  mutableCopy.array = [_array mutableCopy];
  mutableCopy.dictionary = [_dictionary mutableCopy];
  return mutableCopy;
}

- (instancetype)copy {
  return [self mutableCopy];
}

- (id)objectForKey:(id)key {
  return [_dictionary objectForKey:key];
}

- (void)setObject:(id)object forKey:(id)key {
  if (![_dictionary objectForKey:key]) {
    [_array addObject:key];
  }
  [_dictionary setObject:object forKey:key];
}

- (void)removeObjectForKey:(id)key {
  [_dictionary removeObjectForKey:key];
  [_array removeObject:key];
}

- (void)sortUsingSelector:(SEL)selector {
  [_array sortUsingSelector:selector];
}

- (NSEnumerator *)keyEnumerator {
  return [_array objectEnumerator];
}

- (NSEnumerator *)reverseKeyEnumerator {
  return [_array reverseObjectEnumerator];
}

- (void)insertObject:(id)object forKey:(id)key atIndex:(NSUInteger)index {
  if ([_dictionary objectForKey:key]) {
    [self removeObjectForKey:key];
  }
  [_array insertObject:key atIndex:index];
  [self setObject:object forKey:key];
}

- (id)keyAtIndex:(NSUInteger)index {
  return [_array objectAtIndex:index];
}

- (void)setObject:(id)obj forKeyedSubscript:(id<NSCopying>)key {
  [self setObject:obj forKey:key];
}

- (id)objectForKeyedSubscript:(id)key {
  return [self objectForKey:key];
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained [])buffer count:(NSUInteger)len {
  return [_array countByEnumeratingWithState:state objects:buffer count:len];
}

- (NSData *)mp_messagePack {
  return [MPMessagePackWriter writeObject:self error:nil];
}

@end
