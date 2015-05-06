//
//  MPMessagePack.h
//  MPMessagePack
//
//  Created by Gabriel on 7/3/14.
//  Copyright (c) 2014 Gabriel Handford. All rights reserved.
//

#ifdef TARGET_OS_X
#import <Cocoa/Cocoa.h>

//! Project version number for MPMessagePack.
FOUNDATION_EXPORT double MPMessagePackVersionNumber;

//! Project version string for Testing.
FOUNDATION_EXPORT const unsigned char MPMessagePackVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <MPMessagePack/PublicHeader.h>

#import <MPMessagePack/MPMessagePackWriter.h>
#import <MPMessagePack/MPMessagePackReader.h>

#import <MPMessagePack/NSDictionary+MPMessagePack.h>
#import <MPMessagePack/NSArray+MPMessagePack.h>
#import <MPMessagePack/NSData+MPMessagePack.h>

#import <MPMessagePack/MPOrderedDictionary.h>

#else

#import <Foundation/Foundation.h>

#import "MPMessagePackWriter.h"
#import "MPMessagePackReader.h"

#import "NSDictionary+MPMessagePack.h"
#import "NSArray+MPMessagePack.h"
#import "NSData+MPMessagePack.h"

#import "MPOrderedDictionary.h"

#endif


