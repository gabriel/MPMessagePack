//
//  MPDefines.h
//  MPMessagePack
//
//  Created by Gabriel on 12/13/14.
//  Copyright (c) 2014 Gabriel Handford. All rights reserved.
//

#undef MPDebug
#define MPDebug(fmt, ...) do {} while(0)
#undef MPErr
#define MPErr(fmt, ...) do {} while(0)

#if DEBUG
#undef MPDebug
#define MPDebug(fmt, ...) NSLog((@"%s:%d: " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#undef MPErr
#define MPErr(fmt, ...) NSLog((@"%s:%d: " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#endif

typedef void (^MPCompletion)(NSError *error);

#define MPMakeError(CODE, fmt, ...) [NSError errorWithDomain:@"MPMessagePack" code:CODE userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:fmt, ##__VA_ARGS__]}]

#define MPIfNull(obj, val) ([obj isEqual:NSNull.null] ? val : obj)