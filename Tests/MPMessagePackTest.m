//
//  MPMessagePackTest.m
//
#import <GRUnit/GRUnit.h>

#import "MPMessagePack.h"

@interface MPMessagePackTest : GRTestCase
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
  GRAssertEqualObjects(@[], read1);
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
    @"data": [self dataFromHexString:@"1c94d7de0000000344b409a81eafc66993cbe5fd885b5f6975a3f1f03c7338452116f7200a46412437007b65304528a314756bc701cec7b493cab44b3971b18c1137c1b1ba63d6a61119a5a2298b447d0cba89071320fc2c0f66b8f8056cd043d1ac6c0e983903355310e794ddd4a532729b3c2d65d71ebff32219f2f1759b3952d686149780c8e20f6bc912e5ba44701cdb165fcf5ab266c4295bf84796f9ac01c4e2ddf91ac7932d7ed71ee6187aa5fc3177b1abefdc29d8dec5098465b31f17511f65d38285f213724fcc98fe9cc6842c28d5"],
    @"null": [NSNull null],
    @"str": @"🍆😗😂😰",
    };
  GRTestLog(@"Obj: %@", obj);
  
  NSData *data2 = [obj mp_messagePack];
  NSDictionary *read2 = [MPMessagePackReader readData:data2 options:0 error:nil];
  GRAssertEqualObjects(obj, read2);
  
  NSData *data3 = [MPMessagePackWriter writeObject:obj options:MPMessagePackWriterOptionsSortDictionaryKeys error:nil];
  NSDictionary *read3 = [MPMessagePackReader readData:data3 options:0 error:nil];
  GRAssertEqualObjects(obj, read3);
}

- (void)testRandomData {
  NSUInteger length = 1024 * 32;
  NSMutableData *data = [NSMutableData dataWithLength:length];
  SecRandomCopyBytes(kSecRandomDefault, length, [data mutableBytes]);
  
  NSError *error = nil;
  [MPMessagePackReader readData:data options:0 error:&error];
  GRTestLog(@"Error: %@", error);
  // Just don't crash
}

@end
