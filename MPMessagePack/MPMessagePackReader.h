//
//  MPMessagePackReader.h
//  MPMessagePack
//
//  Created by Gabriel on 7/3/14.
//  Copyright (c) 2014 Gabriel Handford. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MPMessagePackReader : NSObject

+ (id)readData:(NSData *)data;

@end
