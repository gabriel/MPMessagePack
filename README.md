MPMessagePack
===========

Objective-C implementation for [MessagePack](http://msgpack.org/). 

MessagePack is an efficient binary serialization format. It lets you exchange data among multiple languages like JSON. But it's faster and smaller.

# Install

[CocoaPods](http://cocoapods.org) is a dependency manager for Objective-C, which automates and simplifies the process of using 3rd-party libraries in your projects.

## Podfile

```ruby
pod "MPMessagePack"
```

# MPMessagePack

## Writing

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
```

Or via ```MPMessagePackWriter```.

```objc
NSError *error = nil;
NSData *data = [MPMessagePackWriter writeObject:dict error:&error];
```

If you need to use an ordered dictionary.

```objc
MPOrderedDictionary *dict = [[MPOrderedDictionary alloc] init];
[dict addEntriesFromDictionary:@{@"c": @(1), @"b": @(2), @"a": @(3)}];
[dict sortKeysUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
[dict mp_messagePack];
```

## Reading

```objc
id obj = [MPMessagePackReader readData:data error:&error];
```
