//
//  GRTestGroup.m
//
//  Created by Gabriel Handford on 1/16/09.
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

#import "GRTestGroup.h"
#import "GRTestCase.h"

#import "GRTesting.h"

@interface GRTestGroup ()
@property NSString *name;
@property NSMutableArray *children;
@end

@implementation GRTestGroup

- (id)initWithName:(NSString *)name delegate:(id<GRTestDelegate>)delegate {
  if ((self = [super init])) {
    _name = name;
    _children = [NSMutableArray array];
    _delegate = delegate;
  } 
  return self;
}

- (id)initWithTestCase:(id)testCase delegate:(id<GRTestDelegate>)delegate {
  if ((self = [self initWithName:NSStringFromClass([testCase class]) delegate:delegate])) {
    _testCase = testCase;
    [self _addTestsFromTestCase:testCase];
  }
  return self;
}

- (id)initWithTestCase:(id)testCase selector:(SEL)selector delegate:(id<GRTestDelegate>)delegate {
  if ((self = [self initWithName:NSStringFromClass([testCase class]) delegate:delegate])) {
    _testCase = testCase;
    [self addTest:[[GRTest alloc] initWithTarget:testCase selector:selector delegate:self]];
  }
  return self;
}

+ (GRTestGroup *)testGroupFromTestCase:(id)testCase delegate:(id<GRTestDelegate>)delegate {
  return [[GRTestGroup alloc] initWithTestCase:testCase delegate:delegate];
}

- (NSString *)description {
  return [NSString stringWithFormat:@"%@, %d %0.3f %@/%@ (%@ failures)", 
                 _name, (int)_status, _interval, @(_stats.succeedCount), @(_stats.testCount), @(_stats.failureCount)];
}

- (void)_addTestsFromTestCase:(id)testCase {
  NSArray *tests = [[GRTesting sharedInstance] loadTestsFromTarget:testCase delegate:self];
  [self addTests:tests];
}

- (void)addTestCase:(id)testCase {
  GRTestGroup *testCaseGroup = [[GRTestGroup alloc] initWithTestCase:testCase delegate:self];
  [self addTestGroup:testCaseGroup];
}

- (void)addTestGroup:(GRTestGroup *)testGroup {
  [self addTest:testGroup];
  [testGroup setParent:self];   
}

- (void)addTests:(NSArray *)tests {
  for(GRTest *test in tests)
    [self addTest:test];
}

- (void)addTest:(id<GRTest>)test {
  test.delegate = self;
  _stats.testCount += [test stats].testCount;
  [_children addObject:test]; 
}

- (NSString *)identifier {
  return _name;
}

- (NSArray *)log {
  // Not supported for group (though may be an aggregate of child test logs in the future?)
  return nil;
}

- (void)reset {
  [self _reset];
  for(id<GRTest> test in _children) {
    [test reset];   
  }
  [_delegate testDidUpdate:self source:self];
}

- (void)_reset {
  _status = GRTestStatusNone;
  _stats = GRTestStatsMake(0, 0, _stats.testCount);
  _interval = 0;
}

- (void)_failedTests:(NSMutableArray *)tests testGroup:(id<GRTestGroup>)testGroup {  
  for(id<GRTest> test in [testGroup children]) {
    if ([test conformsToProtocol:@protocol(GRTestGroup)]) 
      [self _failedTests:tests testGroup:(id<GRTestGroup>)test];
    else if (test.status == GRTestStatusErrored) [tests addObject:test];
  }
}

- (NSArray */*of id<GRTest>*/)failedTests {
  NSMutableArray *tests = [NSMutableArray array];
  [self _failedTests:tests testGroup:self];
  return tests;
}

- (void)cancel {
  _status = GRTestStatusCancelling;
  for (id<GRTest> test in _children) {
    [test cancel];
  }
  [_testCase cancel];
  [_delegate testDidUpdate:self source:self];
}

- (void)setDisabled:(BOOL)disabled {
  for (id<GRTest> test in _children) {
    [test setDisabled:disabled];
  }
  [_delegate testDidUpdate:self source:self];
}

- (BOOL)isDisabled {
  for (id<GRTest> test in _children) {
    if (![test isDisabled]) return NO;
  }
  return YES;
}

- (void)setHidden:(BOOL)hidden {
  for(id<GRTest> test in _children) {
    [test setHidden:hidden];
  }
  [_delegate testDidUpdate:self source:self];
}

- (BOOL)isHidden {
  for (id<GRTest> test in _children) {
    if (![test isHidden]) return NO;
  }
  return YES;
}

- (NSInteger)disabledCount {
  NSInteger disabledCount = 0;
  for (id<GRTest> test in _children) {
    disabledCount += [test disabledCount];
  }
  return disabledCount;
}

- (void)_testDidEnd:(GRTestCompletionBlock)groupCompletion {
  if (_status == GRTestStatusCancelling) {
    _status = GRTestStatusCancelled;
  } else if (_stats.failureCount > 0) {
    _status = GRTestStatusErrored;
  } else {
    _status = GRTestStatusSucceeded;
  }
  [_delegate testDidEnd:self source:self];
  if (groupCompletion) groupCompletion(self);
}

- (void)_nextTest:(NSInteger)index groupCompletion:(GRTestCompletionBlock)groupCompletion {
  if (index >= [_children count] || _status == GRTestStatusCancelling) {
    [self _testDidEnd:groupCompletion];
    return;
  }
  
  id<GRTest> test = _children[index];
  GRTestGroup *blockSelf __weak = self;
  GRTestCompletionBlock testCompletion = ^(id<GRTest> test) {
    [blockSelf _nextTest:index+1 groupCompletion:groupCompletion];
  };
  
  [test run:testCompletion];  
}

- (void)_run:(GRTestCompletionBlock)groupCompletion {
//  NSInteger enabledCount = ([_children count] - [self disabledCount]);
//  if (_status == GRTestStatusCancelled || enabledCount <= 0) {
//    return;
//  }
  _status = GRTestStatusRunning;
  [_delegate testDidStart:self source:self];
  
  [self _nextTest:0 groupCompletion:groupCompletion];
}

- (void)run:(GRTestCompletionBlock)completion {
  [self _reset];
  
  BOOL shouldRunOnMainThread = NO;
  
  // Run on main thread (and wait) if the test case wants it
  if ([_testCase respondsToSelector:@selector(shouldRunOnMainThread)]) {
    shouldRunOnMainThread = [_testCase shouldRunOnMainThread];
  }
    
  if (shouldRunOnMainThread) {
    GRTestGroup *blockSelf __weak = self;
    dispatch_sync(dispatch_get_main_queue(), ^{
      [blockSelf _run:completion];
    });
  } else {
    [self _run:completion];
  }
}

#pragma mark Delegates (GRTestDelegate)

- (void)testDidStart:(id<GRTest>)test source:(id<GRTest>)source {
  [_delegate testDidStart:self source:source];
  [_delegate testDidUpdate:self source:self]; 
}

- (void)testDidUpdate:(id<GRTest>)test source:(id<GRTest>)source {
  [_delegate testDidUpdate:self source:source]; 
  [_delegate testDidUpdate:self source:self]; 
}

- (void)testDidEnd:(id<GRTest>)test source:(id<GRTest>)source { 
  if (source == test) {
    if ([test interval] >= 0)
      _interval += [test interval]; 
    _stats.failureCount += [test stats].failureCount;
    _stats.succeedCount += [test stats].succeedCount;
  }
  [_delegate testDidEnd:self source:source];
  [_delegate testDidUpdate:self source:self]; 
}

// Bubble up
- (void)test:(id<GRTest>)test didLog:(NSString *)message source:(id<GRTest>)source {
  [_delegate test:self didLog:message source:source];
}

#pragma mark NSCoding

- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeObject:self.identifier forKey:@"identifier"];
  [coder encodeInteger:self.status forKey:@"status"];
  [coder encodeDouble:self.interval forKey:@"interval"];
}

- (id)initWithCoder:(NSCoder *)coder {
  GRTestGroup *test = [self initWithName:[coder decodeObjectForKey:@"identifier"] delegate:nil];
  test.status = [coder decodeIntegerForKey:@"status"];
  test.interval = [coder decodeDoubleForKey:@"interval"];
  return test;
}

#pragma mark NSCopying

- (id)copyWithZone:(NSZone *)zone {
  NSMutableArray *tests = [NSMutableArray arrayWithCapacity:[_children count]];
  for(id<GRTest> test in _children) {
    id<GRTest> testCopy = [test copyWithZone:zone];
    [tests addObject:testCopy];
  }
  GRTestGroup *testGroup = [[GRTestGroup alloc] initWithName:_name delegate:nil];
  [testGroup addTests:tests];
  return testGroup;
}

@end

//! @endcond
