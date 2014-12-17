#import <GRUnit/GRUnit.h>

#import "MPMessagePackClient.h"
#import "MPMessagePackServer.h"

@interface MPMessagePackClientTest : GRTestCase
@property MPMessagePackClient *client;
@property MPMessagePackServer *server;
@end

@implementation MPMessagePackClientTest

- (void)test:(dispatch_block_t)completion {
  _server = [[MPMessagePackServer alloc] initWithOptions:MPMessagePackOptionsFramed];
  
  _server.requestHandler = ^(NSString *method, id params, MPRequestCompletion completion) {
    if ([method isEqualToString:@"test"]) {
      completion(nil, params);
    }
  };
  
  UInt32 port = 41111;
  NSError *error = nil;
  
  if (![_server openWithPort:port error:&error]) {
    GRFail(@"Unable to start server: %@", error);
  }
  
  _client = [[MPMessagePackClient alloc] initWithName:@"Test" options:MPMessagePackOptionsFramed];
  [_client openWithHost:@"127.0.0.1" port:port completion:^(NSError *error) {
    if (error) GRErrorHandler(error);
    GRTestLog(@"Sending request");
    [_client sendRequestWithMethod:@"test" params:@{@"param1": @(1)} completion:^(NSError *error, id result) {
      
      GRTestLog(@"Result: %@", result);
      completion();
    }];
    
  }];
}

@end