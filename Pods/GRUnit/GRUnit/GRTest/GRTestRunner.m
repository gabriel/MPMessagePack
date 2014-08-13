//
//  GRTestRunner.m
//
//  Copyright 2008 Gabriel Handford
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

//
// Portions of this file fall under the following license, marked with:
// GTM_BEGIN : GTM_END
//
//  Copyright 2008 Google Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not
//  use this file except in compliance with the License.  You may obtain a copy
//  of the License at
// 
//  http://www.apache.org/licenses/LICENSE-2.0
// 
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
//  WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
//  License for the specific language governing permissions and limitations under
//  the License.
//

#import "GRTestRunner.h"
#import "GRTestSuite.h"
#import "GRTesting.h"

#import <stdio.h>

@interface GRTestRunner ()
@property NSTimeInterval startInterval;
@property dispatch_queue_t queue;
@property dispatch_group_t group;
@end

@implementation GRTestRunner

- (instancetype)initWithTest:(id<GRTest>)test {
  if ((self = [self init])) {
    _test = test;
    _test.delegate = self;
  }
  return self;
}

+ (instancetype)runnerForTest:(id<GRTest>)test {
  return [[self alloc] initWithTest:test];
}

+ (instancetype)runnerForAllTests {
  GRTestSuite *suite = [GRTestSuite allTests];
  return [self runnerForSuite:suite];
}

+ (instancetype)runnerForSuite:(GRTestSuite *)suite {
  GRTestRunner *runner = [[GRTestRunner alloc] initWithTest:suite];
  return runner;
}

+ (instancetype)runnerForTestClassName:(NSString *)testClassName methodName:(NSString *)methodName {
  return [self runnerForSuite:[GRTestSuite suiteWithTestCaseClass:NSClassFromString(testClassName) 
                                                           method:NSSelectorFromString(methodName)]];
}

+ (instancetype)runnerFromEnv {
  GRTestSuite *suite = [GRTestSuite suiteFromEnv];
  GRTestRunner *runner = [GRTestRunner runnerForSuite:suite];
  return runner;
} 

+ (void)run:(GRTestCompletionBlock)completion {
  GRTestRunner *testRunner = [GRTestRunner runnerFromEnv];
  [testRunner run:completion];
}

- (void)setInParallel:(BOOL)inParallel {
  NSAssert(!_running, @"Can't change while running");
  _inParallel = inParallel;
  _queue = nil; // Reset queue
}

- (BOOL)run:(GRTestCompletionBlock)completion {
  if (_cancelling || _running) return NO;
  
  _running = YES;
  _startInterval = [NSDate timeIntervalSinceReferenceDate];
  [self _notifyStart];

  if (_inParallel) {
    _queue = dispatch_queue_create("GRUnit", DISPATCH_QUEUE_CONCURRENT);
  } else {
    _queue = dispatch_queue_create("GRUnit", 0);
  }
  _group = dispatch_group_create();
  
  dispatch_group_async(_group, _queue, ^{
    [_test run:^(id<GRTest> test) {
      dispatch_async(dispatch_get_main_queue(), ^{
        if (completion) completion(test);
      });
    }];
  });
  return YES;
}

- (NSTimeInterval)interval {
  return ([NSDate timeIntervalSinceReferenceDate] - _startInterval);
}

- (void)cancel {
  if (_cancelling) return;
  _cancelling = YES;
  [_test cancel];
}

- (GRTestStats)stats {
  return [_test stats];
}
    
- (void)log:(NSString *)message {
  fputs([message UTF8String], stderr);
  fflush(stderr);
}

- (void)dispatch:(dispatch_block_t)block {
  dispatch_async(dispatch_get_main_queue(), block);
}

#pragma mark Delegates (GRTest)

- (void)testDidStart:(id<GRTest>)test source:(id<GRTest>)source {
  if (![source conformsToProtocol:@protocol(GRTestGroup)]) {
    [self log:[NSString stringWithFormat:@"Starting %@\n", [source identifier]]];
  }
  
  GRWeakSelf blockSelf = self;
  [self dispatch:^{
    if ([blockSelf.delegate respondsToSelector:@selector(testRunner:didStartTest:)])
    [blockSelf.delegate testRunner:self didStartTest:source]; 
  }];
}

- (void)testDidUpdate:(id<GRTest>)test source:(id<GRTest>)source {
  GRWeakSelf blockSelf = self;
  [self dispatch:^{
    if ([blockSelf.delegate respondsToSelector:@selector(testRunner:didUpdateTest:)])
      [blockSelf.delegate testRunner:self didUpdateTest:source];  
  }];
}

- (void)testDidEnd:(id<GRTest>)test source:(id<GRTest>)source { 
  
  if ([source status] != GRTestStatusCancelled) {
    if (![source conformsToProtocol:@protocol(GRTestGroup)]) {      
      NSString *message = [NSString stringWithFormat:@" %@ (%0.3fs)\n\n", 
                           ([source stats].failureCount > 0 ? @"FAIL" : @"OK"), [source interval]]; 
      [self log:message];
    }
    
    GRWeakSelf blockSelf = self;
    [self dispatch:^{
      if ([blockSelf.delegate respondsToSelector:@selector(testRunner:didEndTest:)])
        [blockSelf.delegate testRunner:self didEndTest:source];
    }];

  } else {
    [self log:@"Cancelled\n"];
  }
    
  if (_cancelling) {
    [self _notifyCancelled];
  } else if (_test == source && [source status] != GRTestStatusCancelled) {
    // If the test associated with this runner ended then notify
    [self _notifyFinished];
  } 
}

- (void)test:(id<GRTest>)test didLog:(NSString *)message source:(id<GRTest>)source {
  NSLog(@"%@: %@", source, message);
  GRWeakSelf blockSelf = self;
  [self dispatch:^{
    if ([blockSelf.delegate respondsToSelector:@selector(testRunner:test:didLog:)])
      [blockSelf.delegate testRunner:self test:source didLog:message];
  }];
}

#pragma mark Notifications (Private)

- (void)_notifyStart {  
  NSString *message = [NSString stringWithFormat:@"Test Suite '%@' started.\n", [_test name]];
  [self log:message];
  
  GRWeakSelf blockSelf = self;
  [self dispatch:^{
    if ([blockSelf.delegate respondsToSelector:@selector(testRunnerDidStart:)])
      [blockSelf.delegate testRunnerDidStart:self];
  }];
}

- (void)_notifyCancelled {
  NSString *message = [NSString stringWithFormat:@"Test Suite '%@' cancelled.\n", [_test name]];
  [self log:message];
  
  _cancelling = NO;
  _running = NO;
  
  GRWeakSelf blockSelf = self;
  [self dispatch:^{
    if ([blockSelf.delegate respondsToSelector:@selector(testRunnerDidCancel:)])
      [blockSelf.delegate testRunnerDidCancel:self];
  }];
}

- (void)_notifyFinished {
  NSString *message = [NSString stringWithFormat:@"Test Suite '%@' finished.\n"
                       "Executed %@ of %@ tests, with %@ failures in %0.3f seconds (%@ disabled).\n",
                       [_test name], 
                       @([_test stats].succeedCount + [_test stats].failureCount),
                       @([_test stats].testCount),
                       @([_test stats].failureCount),
                       [_test interval],
                       @([_test disabledCount])];
  [self log:message];
  
  if ([_test isKindOfClass:[GRTestGroup class]]) {
    GRTestGroup *testGroup = (GRTestGroup *)_test;
    NSArray *failedTests = [testGroup failedTests];
    if ([failedTests count] > 0) {
      [self log:@"\nFailed tests:\n"];
      for(id<GRTest> test in failedTests) {
        [self log:[NSString stringWithFormat:@"\t%@\n", [test identifier]]];
      }
      [self log:@"\n"];
    }
  }
  
  _cancelling = NO;
  _running = NO;

  GRWeakSelf blockSelf = self;
  [self dispatch:^{
    if ([blockSelf.delegate respondsToSelector:@selector(testRunnerDidEnd:)])
      [blockSelf.delegate testRunnerDidEnd:self];   
  }];
}

@end

//! @endcond
