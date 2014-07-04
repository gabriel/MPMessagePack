//
//  MPMessagePackTest.m
//
#import <GHUnit/GHUnit.h>

#import "MPMessagePack.h"

@interface MPMessagePackTest : GHTestCase
@end

@implementation MPMessagePackTest

- (void)test {
  NSData *data1 = [MPMessagePackWriter writeObject:@[]];
  NSArray *read1 = [MPMessagePackReader readData:data1];
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
  NSDictionary *read2 = [MPMessagePackReader readData:data2];
  GHAssertEqualObjects(obj2, read2, nil);
}

@end
