//
//  MPMessagePackXPC.h
//  MPMessagePack
//
//  Created by Gabriel on 5/5/15.
//  Copyright (c) 2015 Gabriel Handford. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ServiceManagement/ServiceManagement.h>

typedef NS_ENUM(NSInteger, MPXPCErrorCode) {
  MPXPCErrorCodeInvalidRequest = -1,
  MPXPCErrorCodeUnknownRequest = -2,
};

@interface MPXPCService : NSObject

- (void)listen:(xpc_connection_t)service;

// Subclasses should implement this
- (void)handleRequestWithMethod:(NSString *)method params:(NSArray *)params messageId:(NSNumber *)messageId completion:(void (^)(NSError *error, id value))completion;

@end
