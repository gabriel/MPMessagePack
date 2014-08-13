//
//  GRTestSuite.m
//  GRUnit
//
//  Created by Gabriel Handford on 1/25/09.
//  Copyright 2009. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

//! @cond DEV

#import "GRTestSuite.h"

#import "GRTesting.h"

NSString *GRUnitTest = NULL;

@interface GRTestSuite (CLIDisabled)
- (BOOL)isCLIDisabled;
@end

@implementation GRTestSuite

- (id)initWithName:(NSString *)name testCases:(NSArray *)testCases delegate:(id<GRTestDelegate>)delegate {
  if ((self = [super initWithName:name delegate:delegate])) {
    for(id testCase in testCases) {
      [self addTestCase:testCase];
    }
  }
  return self;
}

+ (GRTestSuite *)allTests {
  NSArray *testCases = [[GRTesting sharedInstance] loadAllTestCases];
  GRTestSuite *allTests = [[self alloc] initWithName:@"Tests" testCases:nil delegate:nil];  
  for(id testCase in testCases) {
    // Ignore test cases that can't be run at the command line
    if (!([testCase respondsToSelector:@selector(isCLIDisabled)] && [testCase isCLIDisabled] && getenv("GRUNIT_CLI"))) [allTests addTestCase:testCase];
  }
  return allTests;
}

+ (GRTestSuite *)suiteWithTestCaseClass:(Class)testCaseClass method:(SEL)method { 
  NSString *name = [NSString stringWithFormat:@"%@/%@", NSStringFromClass(testCaseClass), NSStringFromSelector(method)];
  GRTestSuite *testSuite = [[GRTestSuite alloc] initWithName:name testCases:nil delegate:nil];
  id testCase = [[testCaseClass alloc] init];
  if (!testCase) {
    NSLog(@"Couldn't instantiate test: %@", NSStringFromClass(testCaseClass));
    return nil;
  }
  GRTestGroup *group = [[GRTestGroup alloc] initWithTestCase:testCase selector:method delegate:nil];
  [testSuite addTestGroup:group];
  return testSuite;
}

+ (GRTestSuite *)suiteWithPrefix:(NSString *)prefix options:(NSStringCompareOptions)options {
  if (!prefix || [prefix isEqualToString:@""]) return [self allTests];
  
  NSArray *testCases = [[GRTesting sharedInstance] loadAllTestCases];
  NSString *name = [NSString stringWithFormat:@"Tests (%@)", prefix];
  GRTestSuite *testSuite = [[self alloc] initWithName:name testCases:nil delegate:nil]; 
  for(id testCase in testCases) {
    NSString *className = NSStringFromClass([testCase class]);    
    if ([className compare:prefix options:options range:NSMakeRange(0, [prefix length])] == NSOrderedSame)
      [testSuite addTestCase:testCase];
  }
  return testSuite;
  
}

+ (GRTestSuite *)suiteWithTestFilter:(NSString *)testFilterString {
  NSArray *testFilters = [testFilterString componentsSeparatedByString:@","];
  GRTestSuite *testSuite = [[GRTestSuite alloc] initWithName:testFilterString testCases:nil delegate:nil];

  for(NSString *testFilter in testFilters) {
    NSArray *components = [testFilter componentsSeparatedByString:@"/"];
    if ([components count] == 2) {    
      NSString *testCaseClassName = components[0];
      Class testCaseClass = NSClassFromString(testCaseClassName);
      id testCase = [[testCaseClass alloc] init];
      if (!testCase) {
        NSLog(@"Couldn't find test: %@", testCaseClassName);
        continue;
      }
      NSString *methodName = components[1];
      GRTestGroup *group = [[GRTestGroup alloc] initWithTestCase:testCase selector:NSSelectorFromString(methodName) delegate:nil];
      [testSuite addTestGroup:group];
    } else {
      Class testCaseClass = NSClassFromString(testFilter);
      id testCase = [[testCaseClass alloc] init];
      if (!testCase) {
        NSLog(@"Couldn't find test: %@", testFilter);
        continue;
      }   
      [testSuite addTestCase:testCase];
    }
  }
  
  return testSuite;
}

+ (GRTestSuite *)suiteFromEnv {
  const char* cTestFilter = getenv("TEST");
  if (cTestFilter) {
    NSString *testFilter = @(cTestFilter);
    return [GRTestSuite suiteWithTestFilter:testFilter];
  } else {  
    if (GRUnitTest != NULL) return [GRTestSuite suiteWithTestFilter:GRUnitTest];
    return [GRTestSuite allTests];
  }
}

@end

//! @endcond
