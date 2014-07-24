//
//  MPMessagePackTest.m
//
#import <GHUnit/GHUnit.h>

#import "MPMessagePack.h"

@interface MPMessagePackTest : GHTestCase
@end

@implementation MPMessagePackTest

- (NSData *)dataFromHexString:(NSString *)str {
  const char* chars = [str UTF8String];
  NSMutableData* data = [NSMutableData dataWithCapacity:str.length / 2];
  char byteChars[3] = {0, 0, 0};
  unsigned long wholeByte;
  for (int i = 0; i < str.length; i += 2) {
    byteChars[0] = chars[i];
    byteChars[1] = chars[i + 1];
    wholeByte = strtoul(byteChars, NULL, 16);
    [data appendBytes:&wholeByte length:1];
  }
  return data;
}


- (void)testEmpty {
  NSData *data1 = [MPMessagePackWriter writeObject:@[] error:nil];
  NSArray *read1 = [MPMessagePackReader readData:data1 options:0 error:nil];
  GHAssertEqualObjects(@[], read1, nil);
}

- (void)testPackUnpack {
  NSDictionary *obj =
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
    @"dataEmpty": [NSData data],
    @"dataShort": [self dataFromHexString:@"ff"],
    @"data": [self dataFromHexString:@"d696a4a60717b53162e89b5b41e2c5016929b7eb7dc4ef6286619c140b4fb7531d89989aa28ef6a82b97d2230461f8fa4c8"],
    @"null": [NSNull null],
    @"str": @"🍆😗😂😰",
    };
  GHTestLog(@"Obj: %@", obj);
  
  NSData *data2 = [obj mp_messagePack];
  NSDictionary *read2 = [MPMessagePackReader readData:data2 options:0 error:nil];
  GHAssertEqualObjects(obj, read2, nil);
  
  NSData *data3 = [MPMessagePackWriter writeObject:obj options:MPMessagePackWriterOptionsSortDictionaryKeys error:nil];
  NSDictionary *read3 = [MPMessagePackReader readData:data3 options:0 error:nil];
  GHAssertEqualObjects(obj, read3, nil);
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
