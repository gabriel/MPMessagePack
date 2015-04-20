//
//  NSString+MPMessagePack.h
//  MPMessagePack
//
//  Created by Gabriel on 1/5/15.
//  Copyright (c) 2015 Gabriel Handford. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (MPMessagePack)

- (NSString *)mp_hexString;

- (NSArray *)mp_array:(NSError **)error;

- (NSDictionary *)mp_dict:(NSError **)error;

@end
