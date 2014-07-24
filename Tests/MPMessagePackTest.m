//
//  MPMessagePackTest.m
//
#import <GHUnit/GHUnit.h>

#import "MPMessagePack.h"

@interface MPMessagePackTest : GHTestCase
@end

@implementation MPMessagePackTest

- (void)testEmpty {
  NSData *data1 = [MPMessagePackWriter writeObject:@[] error:nil];
  NSArray *read1 = [MPMessagePackReader readData:data1 options:0 error:nil];
  GHAssertEqualObjects(@[], read1, nil);
}

- (void)testPackUnpack {
  NSDictionary *obj2 =
  @{
    @"z": @(0),
    @"p": @(1),
    @"n": @(-1),
    @"u8": @(UINT8_MAX),
    @"u16": @(UINT16_MAX),
    @"u32": @(UINT32_MAX),
    @"u64": @(UINT64_MAX),
    @"s8": @(INT8_MAX),
    @"s16": @(INT16_MAX),
    @"s32": @(INT32_MAX),
    @"s64": @(INT64_MAX),
    @"n8": @(INT8_MIN),
    @"n16": @(INT16_MIN),
    @"n32": @(INT32_MIN),
    @"n64": @(INT64_MIN),
    @"bool": [NSNumber numberWithBool:YES],
    @"arrayFloatDouble": @[@(1.1f), @(2.1)],
    @"body": [NSData data],
    @"null": [NSNull null],
    @"str": @"🍆😗😂😰",
    };
  GHTestLog(@"Obj2: %@", obj2);
  
  NSData *data2 = [obj2 mp_messagePack];
  NSDictionary *read2 = [MPMessagePackReader readData:data2 options:0 error:nil];
  GHAssertEqualObjects(obj2, read2, nil);
}

- (void)testRandomData {
  NSUInteger length = 1024 * 32;
  NSMutableData *data = [NSMutableData dataWithLength:length];
  SecRandomCopyBytes(kSecRandomDefault, length, [data mutableBytes]);
  
  NSError *error = nil;
  [MPMessagePackReader readData:data options:0 error:&error];
  GHTestLog(@"Error: %@", error);
  // Just don't crash
}

@end
