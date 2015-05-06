//
//  MPMessagePack
//
//  Created by Gabriel on 5/5/15.
//  Copyright (c) 2015 Gabriel Handford. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTestCase.h>

#import "MPMessagePackClient.h"
#import "MPMessagePackServer.h"

@interface MPMessagePackClientTest : XCTestCase
@property MPMessagePackClient *client;
@property MPMessagePackServer *server;
@end

@implementation MPMessagePackClientTest

- (void)testClientServer {
  XCTestExpectation *expectation = [self expectationWithDescription:@"Echo"];

  MPMessagePackServer *server = [[MPMessagePackServer alloc] initWithOptions:MPMessagePackOptionsFramed];
  
  server.requestHandler = ^(NSNumber *messageId, NSString *method, id params, MPRequestCompletion requestCompletion) {
    if ([method isEqualToString:@"test"]) {
      requestCompletion(nil, params);
    }
  };
  
  UInt32 port = 41112;
  NSError *error = nil;
  
  if (![server openWithPort:port error:&error]) {
    XCTFail(@"Unable to start server: %@", error);
  }
  
  MPMessagePackClient *client = [[MPMessagePackClient alloc] initWithName:@"Test" options:MPMessagePackOptionsFramed];
  [client openWithHost:@"localhost" port:port completion:^(NSError *error) {
    XCTAssertNil(error);

    NSLog(@"Sending request");
    [client sendRequestWithMethod:@"test" params:@[@{@"param1": @(1)}] messageId:1 completion:^(NSError *error, id result) {
      
      NSLog(@"Result: %@", result);
      XCTAssertNotNil(result);
      
      [client close];
      [server close];
      [expectation fulfill];
    }];
    
  }];

  [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

//- (void)testLocalSocket:(dispatch_block_t)completion {
//  XCTestExpectation *expectation = [self expectationWithDescription:@"Echo"];
//  MPMessagePackServer *server = [[MPMessagePackServer alloc] initWithOptions:MPMessagePackOptionsFramed];
//  server.requestHandler = ^(NSString *method, id params, MPRequestCompletion completion) {
//    completion(nil, @{});
//  };
//  
//  NSString *socketName = [NSString stringWithFormat:@"/tmp/msgpacktest-%@.socket", @(arc4random())];
//  NSError *error = nil;
//  if (![server openWithSocket:socketName error:&error]) {
//    XCTFail(@"Unable to start server: %@", error);
//  }
//  
//  MPMessagePackClient *client = [[MPMessagePackClient alloc] initWithName:@"Test" options:MPMessagePackOptionsFramed];
//  if (![client openWithSocket:socketName error:&error]) {
//    XCTFail(@"Unable to connect to local socket");
//  }
//  
//  NSLog(@"Sending request");
//  [client sendRequestWithMethod:@"test" params:@{} completion:^(NSError *error, id result) {
//    NSLog(@"Result: %@", result);
//    [client close];
//    [server close];
//    [expectation fulfill];
//  }];
//
//  [self waitForExpectationsWithTimeout:1.0 handler:nil];
//}

@end