//
//  GRTesting.m
//  GRUnit
//
//  Created by Gabriel Handford on 1/30/09.
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

#import "GRTesting.h"
#import "GRTest.h"
#import "GRTestCase.h"

#import <objc/runtime.h>

NSInteger ClassSort(id a, id b, void *context) {
  const char *nameA = class_getName([a class]);
  const char *nameB = class_getName([b class]);
  return strcmp(nameA, nameB);
}

// GTM_BEGIN
// Used for sorting methods below
static NSInteger MethodSort(id a, id b, void *context) {
  NSInvocation *invocationA = a;
  NSInvocation *invocationB = b;
  const char *nameA = sel_getName([invocationA selector]);
  const char *nameB = sel_getName([invocationB selector]);
  return strcmp(nameA, nameB);
}

/*
static int MethodSort(const void *a, const void *b) {
  const char *nameA = sel_getName(method_getName(*(Method*)a));
  const char *nameB = sel_getName(method_getName(*(Method*)b));
  return strcmp(nameA, nameB);
}
 */

BOOL isTestFixtureOfClass(Class aClass, Class testCaseClass) {
  if (testCaseClass == NULL) return NO;
  BOOL iscase = NO;
  Class superclass;
  for (superclass = aClass; 
       !iscase && superclass; 
       superclass = class_getSuperclass(superclass)) {
    iscase = superclass == testCaseClass ? YES : NO;
  }
  return iscase;
}
// GTM_END

@protocol GRTesting
- (void)_setUp;
- (void)_tearDown;
@end

@implementation GRTesting

static GRTesting *gSharedInstance;

+ (GRTesting *)sharedInstance {
  @synchronized(self) {   
    if (!gSharedInstance) gSharedInstance = [[GRTesting alloc] init];   
  }
  return gSharedInstance;
}

- (id)init {
  if ((self = [super init])) {
    // Default test cases
    testCaseClassNames_ = [NSMutableArray arrayWithObjects:@"GRTestCase", nil];
  }
  return self;
}

- (BOOL)isTestCaseClass:(Class)aClass {
  for(NSString *className in testCaseClassNames_) {
    if (isTestFixtureOfClass(aClass, NSClassFromString(className))) return YES;
  }
  return NO;
}

- (void)registerClass:(Class)aClass {
  [self registerClassName:NSStringFromClass(aClass)];
}

- (void)registerClassName:(NSString *)className {
  [testCaseClassNames_ addObject:className];
}

+ (NSString *)descriptionForException:(NSException *)exception {
  NSNumber *lineNumber = [exception userInfo][GRTestLineNumberKey];
  NSString *lineDescription = (lineNumber ? [lineNumber description] : @"Unknown");
  NSString *filename = [[[exception userInfo][GRTestFilenameKey] stringByStandardizingPath] stringByAbbreviatingWithTildeInPath];
  NSString *filenameDescription = (filename ? filename : @"Unknown");
  NSArray *stack = [exception callStackSymbols];
  
  NSMutableArray *lines = [NSMutableArray array];
  [lines addObject:[NSString stringWithFormat:@"\tName: %@", [exception name]]];
  [lines addObject:[NSString stringWithFormat:@"\tFile: %@", filenameDescription]];
  [lines addObject:[NSString stringWithFormat:@"\tLine: %@", lineDescription]];
  [lines addObject:[NSString stringWithFormat:@"\tReason: %@", [exception reason]]];
  if (stack) [lines addObject:[NSString stringWithFormat:@"\n%@", stack]];
  
  return [lines componentsJoinedByString:@"\n"];
}  

+ (NSString *)exceptionFilenameForTest:(id<GRTest>)test {
  return [[[[test exception] userInfo][GRTestFilenameKey] stringByStandardizingPath] stringByAbbreviatingWithTildeInPath];
}

+ (NSInteger)exceptionLineNumberForTest:(id<GRTest>)test {
  return [[[test exception] userInfo][GRTestLineNumberKey] integerValue];
}


- (NSArray *)loadAllTestCases {
  NSMutableArray *testCases = [NSMutableArray array];

  int count = objc_getClassList(NULL, 0);
  NSMutableData *classData = [NSMutableData dataWithLength:sizeof(Class) * count];
  Class *classes = (Class*)[classData mutableBytes];
  NSAssert(classes, @"Couldn't allocate class list");
  objc_getClassList(classes, count);
  
  for (int i = 0; i < count; ++i) {
    Class currClass = classes[i];
    id testcase = nil;
    
    if ([self isTestCaseClass:currClass]) {
      testcase = [[currClass alloc] init];
    } else {
      continue;
    }
    
    [testCases addObject:testcase];
  }
  
  return [testCases sortedArrayUsingFunction:ClassSort context:NULL];
}

// GTM_BEGIN

- (NSArray *)loadTestsFromTarget:(id)target delegate:(id<GRTestDelegate>)delegate {
  NSMutableArray *invocations = nil;
  // Need to walk all the way up the parent classes collecting methods (in case
  // a test is a subclass of another test).
  for (Class currentClass = [target class];
       currentClass && (currentClass != [NSObject class]);
       currentClass = class_getSuperclass(currentClass)) {
    unsigned int methodCount;
    Method *methods = class_copyMethodList(currentClass, &methodCount);
    if (methods) {
      // This handles disposing of methods for us even if an exception should fly.
      [NSData dataWithBytes:methods
                           length:sizeof(Method) * methodCount];
      if (!invocations) {
        invocations = [NSMutableArray arrayWithCapacity:methodCount];
      }
      for (size_t i = 0; i < methodCount; ++i) {
        Method currMethod = methods[i];
        SEL sel = method_getName(currMethod);
        const char *name = sel_getName(sel);
        char *returnType = NULL;
        // If it starts with test, and returns void run it.
        if (strstr(name, "test") == name) {
          returnType = method_copyReturnType(currMethod);
          if (returnType) {
            // @gabriel from jjm - this does not appear to work, i am seeing
            //                     memory leaks on exceptions
            // This handles disposing of returnType for us even if an
            // exception should fly. Length +1 for the terminator, not that
            // the length really matters here, as we never reference inside
            // the data block.
            //[NSData dataWithBytes:returnType
            //                     length:strlen(returnType) + 1];
          }
        }
        // TODO: If a test class is a subclass of another, and they reuse the
        // same selector name (ie-subclass overrides it), this current loop
        // and test here will cause cause it to get invoked twice.  To fix this
        // the selector would have to be checked against all the ones already
        // added, so it only gets done once.
        if (returnType  // True if name starts with "test"
            && strcmp(returnType, @encode(void)) == 0
            //&& method_getNumberOfArguments(currMethod) == 2) {
            ) {
          NSMethodSignature *sig = [[target class] instanceMethodSignatureForSelector:sel];
          NSInvocation *invocation
          = [NSInvocation invocationWithMethodSignature:sig];
          [invocation setSelector:sel];
          [invocations addObject:invocation];
        }
        if (returnType != NULL) free(returnType);
      }
    }
    if (methods != NULL) free(methods);
  }
  [invocations sortUsingFunction:MethodSort context:nil];
  
  NSMutableArray *tests = [[NSMutableArray alloc] initWithCapacity:[invocations count]];
  for (NSInvocation *invocation in invocations) {
    GRTest *test = [[GRTest alloc] initWithTarget:target selector:invocation.selector delegate:delegate];
    [tests addObject:test];
  }
  return tests;
}


+ (void)runTestWithTarget:(id)target selector:(SEL)selector completion:(void (^)(NSException *exception, NSTimeInterval interval))completion {  
  @try {
    // Private setUp internal to GRUnit (in case subclasses fail to call super)
    if ([target respondsToSelector:@selector(_setUp)]) {
      [target performSelector:@selector(_setUp)];
    }
    
    if ([target respondsToSelector:@selector(setUp)]) {
      [target performSelector:@selector(setUp)];
    }
  } @catch(NSException *e) {
    completion(e, 0);
    return;
  }
  
  NSDate *startDate = [NSDate date];
  
  @try {

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

    [target performSelector:selector withObject:^() {
      NSException *exception = nil;
      @try {
        if ([target respondsToSelector:@selector(tearDown)]) {
          [target performSelector:@selector(tearDown)];
        }
        
        // Private tearDown internal to GRUnit (in case subclasses fail to call super)
        if ([target respondsToSelector:@selector(_tearDown)]) {
          [target performSelector:@selector(_tearDown)];
        }
      } @catch(NSException *tearDownException) {
        exception = tearDownException;
      }
      
      completion(exception, [[NSDate date] timeIntervalSinceDate:startDate]);
    }];
  
#pragma clang diagnostic pop
    
  } @catch(NSException *e) {
    completion(e, [[NSDate date] timeIntervalSinceDate:startDate]);
  }
}

+ (BOOL)runTestWithTarget:(id)target selector:(SEL)selector exception:(NSException **)exception interval:(NSTimeInterval *)interval {
  
  NSDate *startDate = [NSDate date];  
  NSException *testException = nil;

  @try {
    // Wrap things in autorelease pools because they may
    // have an STMacro in their dealloc which may get called
    // when the pool is cleaned up
    @autoreleasepool {
    // We don't log exceptions here, instead we let the person that called
    // this log the exception.  This ensures they are only logged once but the
    // outer layers get the exceptions to report counts, etc.
      @try {
        // Private setUp internal to GRUnit (in case subclasses fail to call super)
        if ([target respondsToSelector:@selector(_setUp)])
          [target performSelector:@selector(_setUp)];

        if ([target respondsToSelector:@selector(setUp)])
          [target performSelector:@selector(setUp)];
        @try {
          // Runs the test
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
          [target performSelector:selector];
#pragma clang diagnostic pop
          
        } @catch (NSException *exception) {
          if (!testException) testException = exception;
        }

        if ([target respondsToSelector:@selector(tearDown)])
          [target performSelector:@selector(tearDown)];
        
        // Private tearDown internal to GRUnit (in case subclasses fail to call super)
        if ([target respondsToSelector:@selector(_tearDown)])
          [target performSelector:@selector(_tearDown)];

      } @catch (NSException *exception) {
        if (!testException) testException = exception;
      }
    }
  } @catch (NSException *exception) {
    if (!testException) testException = exception; 
  }  

  if (interval) *interval = [[NSDate date] timeIntervalSinceDate:startDate];
  if (exception) *exception = testException;
  BOOL passed = (!testException);
  
  return passed;
}

// GTM_END

@end

//! @endcond
