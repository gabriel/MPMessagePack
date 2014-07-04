//
//  NSDictionary+MPMessagePack.m
//  MPMessagePack
//
//  Created by Gabriel on 7/3/14.
//  Copyright (c) 2014 Gabriel Handford. All rights reserved.
//

#import "NSDictionary+MPMessagePack.h"

#import "MPMessagePackWriter.h"

@implementation NSDictionary (MPMessagePack)

- (NSData *)mp_messagePack {
  return [MPMessagePackWriter writeObject:self error:nil];
}

@end
