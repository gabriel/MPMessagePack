# GRUnit 

GRUnit is a test framework for iOS which runs as a Test (app) target in your project.

![GRUnit-1.0.1](https://raw.githubusercontent.com/gabriel/GRUnit/master/GRUnit-1.0.1.png)

## Install

### Install the GRUnit gem

This gem makes it easy to setup a test app target.

```xml
$ gem install grunit
```

### Install the Tests target

This will edit your ProjectName.xcodeproj file and create a Tests target, scheme, and a sample test file. Its ok to run this multiple times, it won't duplicate any files, targets or schemes.

```xml
$ grunit install -n ProjectName
```

### Add the Tests target to your Podfile

Setup your Podfile to include GRUnit for the Tests target you just created. 

```ruby
# Podfile
platform :ios, '7.0'

target :Tests do
	pod 'GRUnit', '~> 1.0.1'
end
```

Install your project's pods. CocoaPods will then download and configure the required libraries for your project:

```xml
$ pod install
```

Note: If you don't have a Tests target in your project, you will get an error: "[!] Unable to find a target named Tests". If you named your test target something different, such as "ProjectTests" then the Podfile target line should look like: `target :ProjectTests do` instead.

You should use the `.xcworkspace` file to work on your project:

```xml
$ open ProjectName.xcworkspace
```

### Add a test

To generate a test in your test target with name SampleTest:

```xml
$ grunit add -n ProjectName -f SampleTest
```

or read the `GRTestCase` info below.

### Sync all files references in main target to test target:

If you want to add all the files in your main target to the test target, run this sync command.

```xml
$ grunit sync -n ProjectName
```

## GRTestCase

```objc
#import <GRUnit/GRUnit.h>

@interface MyTest : GRTestCase
@end

@implementation MyTest

- (void)test {
  GRAssertEquals(1U, 1U);
  GRAssertEqualStrings(@"a string", @"a string");
  GRAssertEqualObjects(@[@"test"], expectedArray);
  // See more macros below
}

// Test with completion (async) callback
- (void)testWithCompletion:(dispatch_block_t)completion {
  dispatch_queue_t queue = dispatch_queue_create("MyTest", NULL);
  dispatch_async(queue, ^{
    [NSThread sleepForTimeInterval:2];
    GRTestLog(@"Log something and it will show up in the UI and stdout");

    // Call completion when the test is done
    completion();
  });
}

// For a long test, you can check cancel state and break/return
- (void)testCancel {
  for (NSInteger i = 0; i < 123456789; i++) {
    if (self.isCancelling) break;
  }
}

@end
```

To have all your tests in a test case run on the main thread, implement `shouldRunOnMainThread`.

```objc
@implementation MyTest

- (void)testSomethingOnMainThread {
  GRAssertTrue([NSThread isMainThread]);
}

- (BOOL)shouldRunOnMainThread {
  return YES;
}

@end
```

## Exception Breakpoint

You can set an exception breakpoint. If set, it will stop and breakpoint when an error first occurs.

https://developer.apple.com/library/ios/recipes/xcode_help-breakpoint_navigator/articles/adding_an_exception_breakpoint.html

## Test Macros

```
GRAssertNoErr(a1)
GRAssertErr(a1, a2)
GRAssertNotNULL(a1)
GRAssertNULL(a1)
GRAssertNotEquals(a1, a2)
GRAssertNotEqualObjects(a1, a2, desc, ...)
GRAssertOperation(a1, a2, op)
GRAssertGreaterThan(a1, a2)
GRAssertGreaterThanOrEqual(a1, a2)
GRAssertLessThan(a1, a2)
GRAssertLessThanOrEqual(a1, a2)
GRAssertEqualStrings(a1, a2)
GRAssertNotEqualStrings(a1, a2)
GRAssertEqualCStrings(a1, a2)
GRAssertNotEqualCStrings(a1, a2)
GRAssertEqualObjects(a1, a2)
GRAssertEquals(a1, a2)
GHAbsoluteDifference(left,right) (MAX(left,right)-MIN(left,right))
GRAssertEqualsWithAccuracy(a1, a2, accuracy)
GRFail(description, ...)
GRAssertNil(a1)
GRAssertNotNil(a1)
GRAssertTrue(expr)
GRAssertTrueNoThrow(expr)
GRAssertFalse(expr)
GRAssertFalseNoThrow(expr)
GRAssertThrows(expr)
GRAssertThrowsSpecific(expr, specificException)
GRAssertThrowsSpecificNamed(expr, specificException, aName)
GRAssertNoThrow(expr)
GRAssertNoThrowSpecific(expr, specificException)
GRAssertNoThrowSpecificNamed(expr, specificException, aName)
```

### Example Project

This project uses GRUnit. Open `GRUnit.xcworkspace` and run the Tests target.

### Converting from GHUnit

1. Replace `#import <GHUnit/GHUnit.h>` with `#import <GRUnit/GRUnit.h>`
1. Replace `GHTestCase` with `GRTestCase`
1. Replace `GHAssert...` with `GRAssert...` and remove the description argument (usually nil).
1. Replace `GHTestLog` with `GRTestLog`.

### Install Command Line

```xml
$ grunit install_cli -n ProjectName
```

Install ios-sim using homebrew:

```xml
$ brew install ios-sim
```

Now you can run tests from the command line:

```xml
$ grunit run -n ProjectName
```
