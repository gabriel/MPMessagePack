//
//  MPMessagePack
//
//  Created by Gabriel on 5/5/15.
//  Copyright (c) 2015 Gabriel Handford. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>

#import "MPOrderedDictionary.h"

@interface MPOrderedDictionaryTest : XCTestCase
@end

@implementation MPOrderedDictionaryTest

- (void)testDict {
  MPOrderedDictionary *dict = [[MPOrderedDictionary alloc] init];
  NSMutableArray *keys = [NSMutableArray array];
  for (NSInteger i = 0; i < 1024; i++) {
    [keys addObject:@(i)];
    dict[@(i)] = @(i);
  }
  
  NSMutableArray *keysIterated = [NSMutableArray array];
  for (id key in dict) {
    [keysIterated addObject:key];
  }
  
  XCTAssertEqualObjects(keysIterated, keys);
  
  MPOrderedDictionary *dictCopy = [dict copy];
  dictCopy[@(1)] = @"test";
  
  //GHTestLog(@"Description: %@", [dictCopy description]);
}

- (void)testSort {
  MPOrderedDictionary *dict = [[MPOrderedDictionary alloc] init];
  dict[@"a"] = @(1);
  dict[@"c"] = @(2);
  dict[@"d"] = @(3);
  dict[@"b"] = @(4);
  dict[@"e"] = @(5);
  
  MPOrderedDictionary *subdict = [[MPOrderedDictionary alloc] init];
  subdict[@"y"] = @(6);
  subdict[@"x"] = @(7);
  subdict[@"z"] = @(8);
  dict[@"sub"] = subdict;
  
  NSArray *expected = @[@"a", @"b", @"c", @"d", @"e", @"sub"];
  NSArray *expected2 = @[@"x", @"y", @"z"];
  NSLog(@"Dict: %@", dict);
  
  XCTAssertNotEqualObjects(expected, [dict allKeys]);
  [dict sortKeysUsingSelector:@selector(localizedCaseInsensitiveCompare:) deepSort:YES];
  XCTAssertEqualObjects(expected, [dict allKeys]);
  XCTAssertEqualObjects(expected, [[dict keyEnumerator] allObjects]);
  XCTAssertEqualObjects(expected2, [dict[@"sub"] allKeys]);
}

@end
