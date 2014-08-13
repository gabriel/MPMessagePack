//
//  GRTestRunner.h
//
//  Created by Gabriel Handford on 1/16/09.
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

#import "GRTestGroup.h"
#import "GRTestSuite.h"

@class GRTestRunner;

/*!
 Notifies about the test run.
 Delegates can be guaranteed to be notified on the main thread.
 */
@protocol GRTestRunnerDelegate <NSObject>
@optional

/*!
 Test run started.
 @param runner Runner
 */
- (void)testRunnerDidStart:(GRTestRunner *)runner;

/*!
 Test run did start test.
 @param runner Runner
 @param test Test
 */
- (void)testRunner:(GRTestRunner *)runner didStartTest:(id<GRTest>)test;

/*!
 Test run did update test.
 @param runner Runner
 @param test Test
 */
- (void)testRunner:(GRTestRunner *)runner didUpdateTest:(id<GRTest>)test;

/*!
 Test run did end test.
 @param runner Runner
 @param test Test
 */
- (void)testRunner:(GRTestRunner *)runner didEndTest:(id<GRTest>)test;

/*!
 Test run did cancel.
 @param runner Runner
 */
- (void)testRunnerDidCancel:(GRTestRunner *)runner;

/*!
 Test run did end.
 @param runner Runner
 */
- (void)testRunnerDidEnd:(GRTestRunner *)runner;

/*!
 Test run test did log message.
 @param runner Runner
 @param test Test
 @param didLog Message
 */
- (void)testRunner:(GRTestRunner *)runner test:(id<GRTest>)test didLog:(NSString *)didLog;

@end

/*!
 Runs the tests.
 Tests are run on a dispatch queue. Delegate methods are called on the main thread.
 
 For example,
 
    GRTestRunner *runner = [[GRTestRunner alloc] initWithTest:suite];
    runner.delegate = self;
    [runner run:^(id<GRTest> test) { }];
 
 */
@interface GRTestRunner : NSObject <GRTestDelegate>

@property (strong) id<GRTest> test; // The test to run; Could be a GRTestGroup (suite), GRTestGroup (test case), or GRTest (target/selector)
@property (weak) id<GRTestRunnerDelegate> delegate;
@property (readonly) GRTestStats stats;
@property (readonly, getter=isRunning) BOOL running;
@property (readonly, getter=isCancelling) BOOL cancelling;
@property (readonly) NSTimeInterval interval;
@property dispatch_queue_t dispatchQueue;
@property (nonatomic, getter=isInParallel) BOOL inParallel;

/*!
 Create runner for test.
 @param test Test
 */
- (instancetype)initWithTest:(id<GRTest>)test;

/*!
 Create runner for test.
 @param test Test
 */
+ (instancetype)runnerForTest:(id<GRTest>)test;

/*!
 Create runner for all tests.
 @see [GRTesting loadAllTestCases].
 @result Runner
 */
+ (instancetype)runnerForAllTests;

/*!
 Create runner for test suite.
 @param suite Suite
 @result Runner
 */
+ (instancetype)runnerForSuite:(GRTestSuite *)suite;

/*!
 Create runner for class and method.
 @param testClassName Test class name
 @param methodName Test method
 @result Runner
 */
+ (instancetype)runnerForTestClassName:(NSString *)testClassName methodName:(NSString *)methodName;

/*!
 Get the runner from the environment.
 If the TEST env is set, then we will only run that test case or test method.
 */
+ (instancetype)runnerFromEnv;

/*!
 Run the tests in a dispatch queue.
 */
- (BOOL)run:(GRTestCompletionBlock)completion;

/*!
 Cancel test run.
 */
- (void)cancel;

/*!
 Write message to console.
 @param message Message to log
 */
- (void)log:(NSString *)message;

@end

//! @endcond

