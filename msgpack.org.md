
# Install

```
pod "MPMessagePack"
```

# Writing

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

# Reading

```objc
id obj = [MPMessagePackReader readData:data error:&error];
```