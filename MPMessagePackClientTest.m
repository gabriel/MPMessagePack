#import <GRUnit/GRUnit.h>

#import "MPMessagePackClient.h"
#import "MPMessagePackServer.h"

@interface MPMessagePackClientTest : GRTestCase
@property MPMessagePackClient *client;
@property MPMessagePackServer *server;
@end

@implementation MPMessagePackClientTest

- (void)test:(dispatch_block_t)completion {
  _server = [[MPMessagePackServer alloc] init];
  
  _server.requestHandler = ^(NSString *method, id params, MPRequestCompletion completion) {
    if ([method isEqualToString:@"test"]) {
      completion(nil, params);
    }
  };
  
  if (![_server openWithPort:41111 error:nil]) {
    GRFail(@"Unable to start server");
  }
  
  _client = [[MPMessagePackClient alloc] init];
  [_client openWithHost:@"localhost" port:41111 completion:^(NSError *error) {
    if (error) GRErrorHandler(error);
    GRTestLog(@"Sending request");
    [_client sendRequestWithMethod:@"test" params:@{@"param1": @(1)} completion:^(NSError *error, id result) {
      
      GRTestLog(@"Result: %@", result);
      completion();
    }];
    
  }];
}

@end