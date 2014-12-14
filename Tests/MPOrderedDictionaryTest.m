#import <GRUnit/GRUnit.h>

#import "MPOrderedDictionary.h"

@interface MPOrderedDictionaryTest : GRTestCase
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
  
  GRAssertEqualObjects(keysIterated, keys);
  
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
  GRTestLog(@"Dict: %@", dict);
  
  GRAssertNotEqualObjects(expected, [dict allKeys]);
  [dict sortKeysUsingSelector:@selector(localizedCaseInsensitiveCompare:) deepSort:YES];
  GRAssertEqualObjects(expected, [dict allKeys]);
  GRAssertEqualObjects(expected, [[dict keyEnumerator] allObjects]);
  GRAssertEqualObjects(expected2, [dict[@"sub"] allKeys]);
}

@end
