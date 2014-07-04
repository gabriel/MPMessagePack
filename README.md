MPMessagePack
===========

Objective-C implementation for [MessagePack](http://msgpack.org/). 

MessagePack is an efficient binary serialization format. It lets you exchange data among multiple languages like JSON. But it's faster and smaller.

# Install

[CocoaPods](http://cocoapods.org) is a dependency manager for Objective-C, which automates and simplifies the process of using 3rd-party libraries in your projects.

## Podfile

```ruby
platform :ios, "7.0"
pod "MPMessagePack"
```

# MPMessagePack

```objc
#import <MPMessagePack/MPMessagePack.h>

NSDictionary *dict =
  @{
    @"n": @(32134123),
    @"bool": @(YES),
    @"array": @[@(1.1f), @(2.1)],
    @"body": [NSData data],
  };

NSData *data = [dict mp_messagePack];

// To get error info
NSError *error = nil;
NSData *data = [MPMessagePackWriter writeObject:dict error:&error];
```
