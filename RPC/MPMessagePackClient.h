//
//  MPMessagePackRPClient.h
//  MPMessagePack
//
//  Created by Gabriel on 12/12/14.
//  Copyright (c) 2014 Gabriel Handford. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "MPDefines.h"
#import "MPRPCProtocol.h"

typedef NS_ENUM (NSInteger, MPMessagePackClientStatus) {
  MPMessagePackClientStatusNone = 0,
  MPMessagePackClientStatusClosed = 1,
  MPMessagePackClientStatusOpening,
  MPMessagePackClientStatusOpen,
};

typedef NS_OPTIONS (NSInteger, MPMessagePackOptions) {
  MPMessagePackOptionsNone = 0,
  // If true, the message is wrapped in a frame
  MPMessagePackOptionsFramed = 1 << 0,
};

@protocol MPMessagePackCoder
- (id)encodeObject:(id)obj;
@end

@class MPMessagePackClient;

@protocol MPMessagePackClientDelegate <NSObject>
- (void)client:(MPMessagePackClient *)client didError:(NSError *)error fatal:(BOOL)fatal;
- (void)client:(MPMessagePackClient *)client didChangeStatus:(MPMessagePackClientStatus)status;
- (void)client:(MPMessagePackClient *)client didReceiveNotificationWithMethod:(NSString *)method params:(NSArray *)params;
@end

@interface MPMessagePackClient : NSObject

@property (weak) id<MPMessagePackClientDelegate> delegate;
@property (copy) MPRequestHandler requestHandler;
@property (readonly, nonatomic) MPMessagePackClientStatus status;
@property id<MPMessagePackCoder> coder;

- (instancetype)initWithName:(NSString *)name options:(MPMessagePackOptions)options;

- (void)openWithHost:(NSString *)host port:(UInt32)port completion:(MPCompletion)completion;

- (BOOL)openWithSocket:(NSString *)unixSocket completion:(MPCompletion)completion;

- (void)setInputStream:(NSInputStream *)inputStream outputStream:(NSOutputStream *)outputStream;

- (void)close;

/*!
 Send RPC request asyncronously with completion block.
 
 @param method Method name
 @param params Method args. If coder is set on client, we will use it to encode.
 @param messageId Unique message identifier. Responses will use this message ID.
 @param completion Response
 @result RPC message
 */
- (NSArray *)sendRequestWithMethod:(NSString *)method params:(NSArray *)params messageId:(NSInteger)messageId completion:(MPRequestCompletion)completion;

/*!
 Send a response.

 @param result Result
 @param error Error
 @param messageId Message ID (will match request message ID)
 */
- (void)sendResponseWithResult:(id)result error:(id)error messageId:(NSInteger)messageId;

/*!
 Send request synchronously.
 
 @param method Method name
 @param params Method args. If coder is set on client, we will use it to encode.
 @param messageId Unique message identifier. Responses will use this message ID.
 @param timeout Timeout
 @param error Out error
 @result Result of method invocation
 */
- (id)sendRequestWithMethod:(NSString *)method params:(NSArray *)params messageId:(NSInteger)messageId timeout:(NSTimeInterval)timeout error:(NSError **)error;

/*!
 Cancel request.
 
 @param messageId Message id
 @result Return YES if cancelled
 */
- (BOOL)cancelRequestWithMessageId:(NSInteger)messageId;

@end


