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
}

@end
