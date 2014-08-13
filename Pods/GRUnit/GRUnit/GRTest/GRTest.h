//
//  GRTest.h
//  GRUnit
//
//  Created by Gabriel Handford on 1/18/09.
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

#import <Foundation/Foundation.h>


/*!
 Test status.
 */
typedef NS_ENUM (NSUInteger, GRTestStatus) {
  GRTestStatusNone = 0,
  GRTestStatusRunning, //! Test is running
  GRTestStatusCancelling, //! Test is being cancelled
  GRTestStatusCancelled, //! Test was cancelled
  GRTestStatusSucceeded, //! Test finished and succeeded
  GRTestStatusErrored, //! Test finished and errored
};

/*!
 Generate string from GRTestStatus
 @param status
 */
extern NSString *NSStringFromGRTestStatus(GRTestStatus status);

/*!
 Check if test is running (or trying to cancel).
 */
extern BOOL GRTestStatusIsRunning(GRTestStatus status);

/*!
 Check if test has succeeded, errored or cancelled.
 */
extern BOOL GRTestStatusEnded(GRTestStatus status);

/*!
 Test stats.
 */
typedef struct {
  NSInteger succeedCount; // Number of succeeded tests
  NSInteger failureCount; // Number of failed tests
  NSInteger testCount; // Total number of tests 
} GRTestStats;

/*!
 Create GRTestStats.
 */
extern GRTestStats GRTestStatsMake(NSInteger succeedCount, NSInteger failureCount, NSInteger testCount);

extern const GRTestStats GRTestStatsEmpty;

/*!
 Description from test stats.
 */
extern NSString *NSStringFromGRTestStats(GRTestStats stats);

@protocol GRTest;
@protocol GRTestDelegate;

typedef void (^GRTestCompletionBlock)(id<GRTest> test);

/*!
 The base interface for a runnable test.

 A runnable with a unique identifier, display name, stats, timer, delegate, log and error handling.
 */
@protocol GRTest <NSObject, NSCoding, NSCopying>

/*!
 Unique identifier for test.
 */
@property (readonly) NSString *identifier;

/*!
 Name (readable) for test.
 */
@property (readonly) NSString *name;

/*!
 How long the test took to run. Defaults to -1, if not run.
 */
@property (nonatomic) NSTimeInterval interval;

/*!
 Test status.
 */
@property (nonatomic) GRTestStatus status;

/*!
 Test stats.
 */
@property (nonatomic) GRTestStats stats;

/*!
 Exception that occurred.
 */
@property (nonatomic) NSException *exception;

/*!
 Whether test is disabled.
 */
@property (nonatomic, getter=isDisabled) BOOL disabled;

/*!
 Whether test is hidden.
 */
@property (nonatomic, getter=isHidden) BOOL hidden;

/*!
 Delegate for test.
 */
@property (weak, nonatomic) id<GRTestDelegate> delegate; // weak

/*!
 Run the test.
 @param options Options
 */
- (void)run:(GRTestCompletionBlock)completion;

/*!
 @result Messages logged during this test run
 */
- (NSArray *)log;

/*!
 Reset the test.
 */
- (void)reset;

/*!
 Cancel the test.
 */
- (void)cancel;

/*!
 @result The number of disabled tests
 */
- (NSInteger)disabledCount;

@end

/*!
 Test delegate for notification when a test starts and ends.
 */
@protocol GRTestDelegate <NSObject>

/*!
 Test started.
 @param test Test
 @param source If tests are nested, than source corresponds to the originator of the delegate call
 */
- (void)testDidStart:(id<GRTest>)test source:(id<GRTest>)source;

/*!
 Test updated.
 @param test Test
 @param source If tests are nested, than source corresponds to the originator of the delegate call
 */
- (void)testDidUpdate:(id<GRTest>)test source:(id<GRTest>)source;

/*!
 Test ended.
 @param test Test
 @param source If tests are nested, than source corresponds to the originator of the delegate call
 */
- (void)testDidEnd:(id<GRTest>)test source:(id<GRTest>)source;

/*!
 Test logged a message.
 @param test Test
 @param didLog Message
 @param source If tests are nested, than source corresponds to the originator of the delegate call
 */
- (void)test:(id<GRTest>)test didLog:(NSString *)didLog source:(id<GRTest>)source;

@end

/*!
 Delegate which is notified of log messages from inside a test case.
 */
@protocol GRTestCaseLogWriter <NSObject>

/*!
 Log message.
 @param message Message
 @param testCase Test case
 */
- (void)log:(NSString *)message testCase:(id)testCase;

@end

/*!
 Default test implementation with a target/selector pair.

 - Tests a target and selector
 - Notifies a test delegate
 - Keeps track of status, running time and failures
 - Stores any test specific logging

 */
@interface GRTest : NSObject <GRTest, GRTestCaseLogWriter>

@property (readonly) id target;
@property (readonly) SEL selector;
@property (nonatomic) NSTimeInterval interval;
@property (nonatomic) GRTestStatus status;
@property (nonatomic) GRTestStats stats;
@property (nonatomic) NSException *exception;
@property (nonatomic, getter=isDisabled) BOOL disabled;
@property (nonatomic, getter=isHidden) BOOL hidden;
@property (nonatomic, weak) id<GRTestDelegate> delegate;

/*!
 Create test with identifier, name.
 @param identifier Unique identifier
 @param name Name
 */
- (id)initWithIdentifier:(NSString *)identifier name:(NSString *)name delegate:(id<GRTestDelegate>)delegate;

/*!
 Create test with target/selector.
 @param target Target (usually a test case)
 @param selector Selector (usually a test method)
 */
- (id)initWithTarget:(id)target selector:(SEL)selector delegate:(id<GRTestDelegate>)delegate;

@end
