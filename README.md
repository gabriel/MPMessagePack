MPMessagePack
===========

Objective-C implementation for [MessagePack](http://msgpack.org/). 

MessagePack is an efficient binary serialization format. It lets you exchange data among multiple languages like JSON. But it's faster and smaller.

MPMessagePack uses [gabriel/GRUnit](https://github.com/gabriel/GRUnit) for unit testing.

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

```objc
MPMessagePackReader *reader = [[MPMessagePackReader alloc] initWithData:data];
id obj1 = [reader read:&error]; // Read an object
id obj2 = [reader read:&error]; // Read another object
```

# RPC

## Client

```objc
MPMessagePackClient *client = [[MPMessagePackClient alloc] init];
[client openWithHost:@"localhost" port:93434 completion:^(NSError *error) {
  // If error we failed
  [_client sendRequestWithMethod:@"test" params:@{@"param1": @(1)} completion:^(NSError *error, id result) {
    // If error we failed
    // Otherwise the result
  }];
}];
```


## Server

```objc
MPMessagePackServer *server = [[MPMessagePackServer alloc] initWithOptions:MPMessagePackOptionsFramed];

server.requestHandler = ^(NSString *method, id params, MPRequestCompletion completion) {
  if ([method isEqualToString:@"test"]) {
    completion(nil, params);
  }
};

NSError *error = nil;
if (![server openWithPort:93434 error:&error]) {
  // Failed to open
}
```

