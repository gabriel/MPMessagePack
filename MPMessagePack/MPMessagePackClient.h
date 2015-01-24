//
//  MPMessagePackRPClient.h
//  MPMessagePack
//
//  Created by Gabriel on 12/12/14.
//  Copyright (c) 2014 Gabriel Handford. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "MPMessagePack.h"

typedef NS_ENUM(NSInteger, MPMessagePackClientStatus) {
  MPMessagePackClientStatusClosed = 1,
  MPMessagePackClientStatusOpening,
  MPMessagePackClientStatusOpen,
};

typedef NS_ENUM(NSInteger, MPMessagePackOptions) {
  MPMessagePackOptionsFramed = 1 << 0,
};

@protocol MPMessagePackCoder
- (NSDictionary *)encodeObject:(id)obj;
@end

@class MPMessagePackClient;

typedef void (^MPErrorHandler)(NSError *error);
typedef void (^MPRequestCompletion)(NSError *error, id result);
typedef void (^MPRequestHandler)(NSString *method, NSArray *params, MPRequestCompletion completion);


@protocol MPMessagePackClientDelegate <NSObject>
- (void)client:(MPMessagePackClient *)client didError:(NSError *)error fatal:(BOOL)fatal;
- (void)client:(MPMessagePackClient *)client didChangeStatus:(MPMessagePackClientStatus)status;
- (void)client:(MPMessagePackClient *)client didReceiveNotificationWithMethod:(NSString *)method params:(NSArray *)params;
@end

@interface MPMessagePackClient : NSObject <NSStreamDelegate>

@property (weak) id<MPMessagePackClientDelegate> delegate;
@property (copy) MPRequestHandler requestHandler;
@property (readonly, nonatomic) MPMessagePackClientStatus status;
@property id<MPMessagePackCoder> coder;

- (instancetype)initWithName:(NSString *)name options:(MPMessagePackOptions)options;

- (void)openWithHost:(NSString *)host port:(UInt32)port completion:(MPCompletion)completion;

- (BOOL)openWithSocket:(NSString *)unixSocket completion:(MPCompletion)completion;

- (void)setInputStream:(NSInputStream *)inputStream outputStream:(NSOutputStream *)outputStream;

- (void)close;

- (void)sendRequestWithMethod:(NSString *)method params:(NSArray *)params completion:(MPRequestCompletion)completion;

// For servers
- (void)sendResponseWithResult:(id)result error:(id)error messageId:(NSInteger)messageId;

@end
