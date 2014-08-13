//
//  GRTestGroup.h
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

#import "GRTest.h"
#import "GRTestCase.h"

/*!
 Interface for a group of tests.

 This group conforms to the GRTest protocol as well (see Composite pattern).
 */
@protocol GRTestGroup <GRTest>

/*!
 Name.
 */
- (NSString *)name;

/*!
 Parent for test group.
 */
- (id<GRTestGroup>)parent;

/*!
 Children for test group.
 */
- (NSArray *)children;

@end

/*!
 A collection of tests (or test groups).

 A test group is a collection of `id<GRTest>`, that may represent a set of test case methods. 
 
 For example, if you had the following GRTestCase.

     @interface FooTest : GRTestCase {}
     - (void)testFoo;
     - (void)testBar;
     @end
 
 The GRTestGroup would consist of and array of GRTest: FooTest#testFoo, FooTest#testBar, 
 each test being a target and selector pair.

 A test group may also consist of a group of groups (since GRTestGroup conforms to GRTest),
 and this might represent a GRTestSuite.
 */
@interface GRTestGroup : NSObject <GRTestDelegate, GRTestGroup>

@property (nonatomic) NSTimeInterval interval;
@property (nonatomic) GRTestStatus status;
@property (nonatomic) GRTestStats stats;
@property (nonatomic) NSException *exception;
@property (nonatomic, getter=isDisabled) BOOL disabled;
@property (nonatomic, getter=isHidden) BOOL hidden;
@property (nonatomic, weak) id<GRTestDelegate> delegate;

@property (weak) id<GRTestGroup> parent;
@property (readonly) GRTestCase *testCase;

/*!
 Create an empty test group.
 @param name The name of the test group
 @param delegate Delegate, notifies of test start and end
 @result New test group
 */
- (id)initWithName:(NSString *)name delegate:(id<GRTestDelegate>)delegate;

/*!
 Create test group from a test case.
 @param testCase Test case, could be a subclass of GRTestCase
 @param delegate Delegate, notifies of test start and end
 @result New test group
 */
- (id)initWithTestCase:(id)testCase delegate:(id<GRTestDelegate>)delegate;

/*!
 Create test group from a single test.
 @param testCase Test case, could be a subclass of GRTestCase
 @param selector Test to run 
 @param delegate Delegate, notifies of test start and end
 */
- (id)initWithTestCase:(id)testCase selector:(SEL)selector delegate:(id<GRTestDelegate>)delegate;

/*!
 Create test group from a test case.
 @param testCase Test case, could be a subclass of GRTestCase
 @param delegate Delegate, notifies of test start and end
 @result New test group
 */
+ (GRTestGroup *)testGroupFromTestCase:(id)testCase delegate:(id<GRTestDelegate>)delegate;

/*!
 Add a test case (or test group) to this test group.
 @param testCase Test case, could be a subclass of GRTestCase
 */
- (void)addTestCase:(id)testCase;

/*!
 Add a test group to this test group.
 @param testGroup Test group to add
 */
- (void)addTestGroup:(GRTestGroup *)testGroup;

/*!
 Add tests to this group.
 @param tests Tests to add
 */
- (void)addTests:(NSArray */*of id<GRTest>*/)tests;

/*!
 Add test to this group.
 @param test Test to add
 */
- (void)addTest:(id<GRTest>)test;

/*!
 Get list of failed tests.
 @result Failed tests
 */
- (NSArray */*of id<GRTest>*/)failedTests;

@end

//! @endcond
