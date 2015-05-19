//
//  MPXPCClient.h
//  MPMessagePack
//
//  Created by Gabriel on 5/5/15.
//  Copyright (c) 2015 Gabriel Handford. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MPXPCClient : NSObject

@property NSTimeInterval timeout;

- (instancetype)initWithServiceName:(NSString *)serviceName priviledged:(BOOL)priviledged;

- (BOOL)connect:(NSError **)error;

- (void)sendRequest:(NSString *)method params:(NSArray *)params completion:(void (^)(NSError *error, id value))completion;

@end
