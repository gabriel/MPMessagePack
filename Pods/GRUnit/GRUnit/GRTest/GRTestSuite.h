//
//  GRTestSuite.h
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

#import "GRTestGroup.h"

/*!
 If set, will run it as a "test filter" like the env variable TEST.
 */
extern NSString *GRUnitTest;


/*!
 Test suite is an alias for test group.
 
 A test case is an instance of a test case class with test methods.
 A test is a id<GRTest> which represents a target and a selector.
 A test group is a collection of tests; A collection of id<GRTest> (GRTest or GRTestGroup).
 
 For example, if you have 2 test cases, GRTestCase1 (with some test methods) and GRTestCase2 (with some test methods), 
 your test suite might look like:
 
"Tests" (GRTestSuite)
  GRTestGroup (collection of tests from GRTestCase1)
    - (void)testA1 (GRTest with target GRTestCase1 + testA1)
    - (void)testA2 (GRTest with target GRTestCase1 + testA2)
  GRTestGroup (collection of tests from GRTestCase2)
    - (void)testB1; (GRTest with target GRTestCase2 + testB1)
    - (void)testB2; (GRTest with target GRTestCase2 + testB2)  
 
 */
@interface GRTestSuite : GRTestGroup { }

/*! 
 Create test suite with test cases.
 @param name Label to give the suite
 @param testCases Array of init'ed test case classes
 @param delegate Delegate
 */
- (id)initWithName:(NSString *)name testCases:(NSArray *)testCases delegate:(id<GRTestDelegate>)delegate;

/*!
 Creates a suite of all tests.
 Will load all classes that subclass from GRTestCase (or register test case class).
 @result Suite
 */
+ (GRTestSuite *)allTests;

/*!
 Create suite of tests with filter.
 This is useful for running a single test or all tests in a single test case.
 
 For example,
 'GHSlowTest' -- Runs all test method in GHSlowTest
 'GHSlowTest/testSlowA -- Only runs the test method testSlowA in GHSlowTest
 
 @param testFilter Test filter
 @result Suite
 */
+ (GRTestSuite *)suiteWithTestFilter:(NSString *)testFilter;

/*!
 Create suite of tests that start with prefix.
 @param prefix If test case class starts with the prefix; If nil or empty string, returns all tests
 @param options Compare options
 */
+ (GRTestSuite *)suiteWithPrefix:(NSString *)prefix options:(NSStringCompareOptions)options;

/*!
 Suite for a single test/method.
 @param testCaseClass Test case class
 @param method Method
 @result Suite
 */
+ (GRTestSuite *)suiteWithTestCaseClass:(Class)testCaseClass method:(SEL)method;

/*!
 Return test suite based on environment (TEST=TestFoo/foo)
 @result Suite
 */
+ (GRTestSuite *)suiteFromEnv;

@end

@interface GRTestSuite (JUnitXML)

- (BOOL)writeJUnitXMLToDirectory:(NSString *)directory error:(NSError **)error;

@end

//! @endcond
