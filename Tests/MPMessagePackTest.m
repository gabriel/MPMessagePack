//
//  MPMessagePackTest.m
//
#import <GHUnit/GHUnit.h>

#import "MPMessagePack.h"

@interface MPMessagePackTest : GHTestCase
@end

@implementation MPMessagePackTest

- (void)test {
  NSData *data1 = [MPMessagePackWriter writeObject:@[] error:nil];
  NSArray *read1 = [MPMessagePackReader readData:data1 error:nil];
  GHAssertEqualObjects(@[], read1, nil);
  
  NSDictionary *obj2 =
  @{
    @"n": @(32134123),
    @"bool": @(YES),
    @"array": @[@(1.1f), @(2.1)],
    @"body": [NSData data],
    };
  GHTestLog(@"Obj2: %@", obj2);
  
  NSData *data2 = [obj2 mp_messagePack];
  NSDictionary *read2 = [MPMessagePackReader readData:data2 error:nil];
  GHAssertEqualObjects(obj2, read2, nil);
}

- (void)testRandomData {
  NSUInteger length = 1024 * 32;
  NSMutableData *data = [NSMutableData dataWithLength:length];
  SecRandomCopyBytes(kSecRandomDefault, length, [data mutableBytes]);
  
  NSError *error = nil;
  [MPMessagePackReader readData:data error:&error];
  GHTestLog(@"Error: %@", error);
  // Just don't crash
}

@end
