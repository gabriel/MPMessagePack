#import <GRUnit/GRUnit.h>

#import "MPMessagePackClient.h"
#import "MPMessagePackServer.h"

@interface MPMessagePackClientTest : GRTestCase
@property MPMessagePackClient *client;
@property MPMessagePackServer *server;
@end

@implementation MPMessagePackClientTest

- (void)test:(dispatch_block_t)completion {
  MPMessagePackServer *server = [[MPMessagePackServer alloc] initWithOptions:MPMessagePackOptionsFramed];
  
  server.requestHandler = ^(NSString *method, id params, MPRequestCompletion completion) {
    if ([method isEqualToString:@"test"]) {
      completion(nil, params);
    }
  };
  
  UInt32 port = 41112;
  NSError *error = nil;
  
  if (![server openWithPort:port error:&error]) {
    GRFail(@"Unable to start server: %@", error);
  }
  
  MPMessagePackClient *client = [[MPMessagePackClient alloc] initWithName:@"Test" options:MPMessagePackOptionsFramed];
  [client openWithHost:@"localhost" port:port completion:^(NSError *error) {
    if (error) GRErrorHandler(error);
    GRTestLog(@"Sending request");
    [client sendRequestWithMethod:@"test" params:@{@"param1": @(1)} completion:^(NSError *error, id result) {
      
      GRTestLog(@"Result: %@", result);
      
      [client close];
      [server close];
      completion();
    }];
    
  }];
  
  [self wait:10];
}

//- (void)testLocalSocket:(dispatch_block_t)completion {
//  MPMessagePackServer *server = [[MPMessagePackServer alloc] initWithOptions:MPMessagePackOptionsFramed];
//  server.requestHandler = ^(NSString *method, id params, MPRequestCompletion completion) {
//    completion(nil, @{});
//  };
//  
//  NSString *socketName = [NSString stringWithFormat:@"/tmp/msgpacktest-%@.socket", @(arc4random())];
//  NSError *error = nil;
//  if (![server openWithSocket:socketName error:&error]) {
//    GRFail(@"Unable to start server: %@", error);
//  }
//  
//  MPMessagePackClient *client = [[MPMessagePackClient alloc] initWithName:@"Test" options:MPMessagePackOptionsFramed];
//  if (![client openWithSocket:socketName error:&error]) {
//    GRFail(@"Unable to connect to local socket");
//  }
//  
//  GRTestLog(@"Sending request");
//  [client sendRequestWithMethod:@"test" params:@{} completion:^(NSError *error, id result) {
//    GRTestLog(@"Result: %@", result);
//    [client close];
//    [server close];
//    completion();
//  }];
//
//  [self wait:10];
//}

@end