#import <GHUnit/GHUnit.h>

#import "MPOrderedDictionary.h"

@interface MPOrderedDictionaryTest : GHTestCase
@end

@implementation MPOrderedDictionaryTest

- (void)test {
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
  
  GHAssertEqualObjects(keysIterated, keys, nil);
  
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
  GHTestLog(@"Dict: %@", dict);
  
  GHAssertNotEqualObjects(expected, [dict allKeys], nil);
  [dict sortKeysUsingSelector:@selector(localizedCaseInsensitiveCompare:) deepSort:YES];
  GHAssertEqualObjects(expected, [dict allKeys], nil);
  GHAssertEqualObjects(expected, [[dict keyEnumerator] allObjects], nil);
  GHAssertEqualObjects(expected2, [dict[@"sub"] allKeys], nil);
}

@end
