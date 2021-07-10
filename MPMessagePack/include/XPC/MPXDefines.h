//
//  MPXDefines.h
//  MPMessagePack
//
//  Copyright (c) 2014 Gabriel Handford. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifdef __MAC_OS_X_VERSION_MAX_ALLOWED
#define ENABLE_XPC_SUPPORT 1
#else
#define ENABLE_XPC_SUPPORT 0
#endif
