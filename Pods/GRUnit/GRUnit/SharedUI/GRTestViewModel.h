//
//  GRTest.h
//  GRUnit
//
//  Created by Gabriel Handford on 1/17/09.
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
#import "GRTestSuite.h"
#import "GRTestRunner.h"

@class GRTestNode;

@protocol GRTestNodeDelegate <NSObject>
- (void)testNodeDidChange:(GRTestNode *)node;
@end

typedef NS_ENUM (NSInteger, GRTestNodeFilter) {
  GRTestNodeFilterNone = 0,
  GRTestNodeFilterFailed = 1
};

/*!
 Test view model for use in a tree view.
 */
@interface GRTestViewModel : NSObject <GRTestNodeDelegate>

@property (readonly) GRTestNode *root;
@property (getter=isEditing) BOOL editing;

/*!
 Create view model with root test group node.

 @param identifier Unique identifier for test model (used to load defaults)
 @param suite Suite
 */
- (id)initWithIdentifier:(NSString *)identifier suite:(GRTestSuite *)suite;

/*!
 @result Name of test suite.
 */
- (NSString *)name;

/*!
 Status description.

 @param prefix Prefix to append
 @result Current status string
 */
- (NSString *)statusString:(NSString *)prefix;

/*!
 Find the test node from the test.

 @param test Find test
 */
- (GRTestNode *)findTestNodeForTest:(id<GRTest>)test;

/*!
 Find the first failure.

 @result The first failure
 */
- (GRTestNode *)findFailure;

/*!
 Find the next failure starting from node.

 @param node Node to start from
 */
- (GRTestNode *)findFailureFromNode:(GRTestNode *)node;

/*!
 Register node, so that we can do a lookup later. See findTestNodeForTest:.

 @param node Node to register
 */
- (void)registerNode:(GRTestNode *)node;

/*!
 @result Returns the number of test groups.
 */
- (NSInteger)numberOfGroups;

/*!
 Returns the number of tests in group.
 @param group Group number
 @result The number of tests in group.
 */
- (NSInteger)numberOfTestsInGroup:(NSInteger)group;

/*!
 Search for path to test.
 @param test Test
 @result Index path
 */
- (NSIndexPath *)indexPathToTest:(id<GRTest>)test;

/*!
 Load defaults (user settings saved with saveDefaults).
 */
- (void)loadDefaults;

/*!
 Save defaults (user settings to be loaded with loadDefaults).
 */
- (void)saveDefaults;

/*!
 Run with current test suite.

 @param delegate Callback
 @param inParallel If YES, will run tests in operation queue
 */
- (void)run:(id<GRTestRunnerDelegate>)delegate inParallel:(BOOL)inParallel;

/*!
 Cancel test run.
 */
- (void)cancel;

/*!
 Check if running.

 @result YES if running.
 */
- (BOOL)isRunning;

@end


@interface GRTestNode : NSObject

@property (readonly) id<GRTest> test;
@property (weak) id<GRTestNodeDelegate> delegate;
@property (nonatomic) GRTestNodeFilter filter;
@property (nonatomic) NSString *textFilter;

- (id)initWithTest:(id<GRTest>)test children:(NSArray */*of id<GRTest>*/)children source:(GRTestViewModel *)source;
+ (GRTestNode *)nodeWithTest:(id<GRTest>)test children:(NSArray */*of id<GRTest>*/)children source:(GRTestViewModel *)source;

- (NSString *)identifier;
- (NSString *)name;
- (NSString *)nameWithStatus;

- (GRTestStatus)status;
- (NSString *)statusString;
- (NSString *)stackTrace;
- (NSString *)exceptionFilename;
- (NSInteger)exceptionLineNumber;
- (NSString *)log;
- (BOOL)isRunning;
- (BOOL)isDisabled;
- (BOOL)isHidden;
- (BOOL)isEnded;
- (BOOL)isGroupTest; // YES if test has "sub tests"

- (BOOL)isSelected;
- (void)setSelected:(BOOL)selected;

- (NSArray *)filteredChildren;
- (BOOL)failed;

- (void)notifyChanged;

- (void)setFilter:(GRTestNodeFilter)filter textFilter:(NSString *)textFilter;

@end

//! @endcond
