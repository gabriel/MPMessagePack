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
  MPMessagePackClientStatusClosed,
  MPMessagePackClientStatusOpening,
  MPMessagePackClientStatusOpen,
};

typedef NS_ENUM(NSInteger, MPMessagePackClientOptions) {
  MPMessagePackClientOptionsFramed = 1 << 0,
};

@class MPMessagePackClient;

typedef void (^MPRequestCompletion)(NSError *error, id result);
typedef void (^MPRequestHandler)(NSString *method, id params, MPRequestCompletion completion);


@protocol MPMessagePackClientDelegate <NSObject>
- (void)client:(MPMessagePackClient *)client didError:(NSError *)error fatal:(BOOL)fatal;
- (void)client:(MPMessagePackClient *)client didChangeStatus:(MPMessagePackClientStatus)status;
@end

@interface MPMessagePackClient : NSObject <NSStreamDelegate>

@property (weak) id<MPMessagePackClientDelegate> delegate;
@property (copy) MPRequestHandler requestHandler;
@property (readonly, nonatomic) MPMessagePackClientStatus status;

- (instancetype)initWithOptions:(MPMessagePackClientOptions)options;

- (instancetype)initWithInputStream:(NSInputStream *)inputStream outputStream:(NSOutputStream *)outputStream options:(MPMessagePackClientOptions)options;

- (void)openWithHost:(NSString *)host port:(UInt32)port completion:(MPCompletion)completion;

- (void)close;

- (void)sendRequestWithMethod:(NSString *)method params:(id)params completion:(MPRequestCompletion)completion;

- (void)sendResponseWithResult:(id)result error:(id)error messageId:(NSUInteger)messageId;

@end
