//
//  MPRPCProtocolTest.m
//  MPMessagePack
//
//  Created by Gabriel on 8/30/15.
//  Copyright (c) 2015 Gabriel Handford. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>

@import MPMessagePack;

@interface MPRPCProtocolTest : XCTestCase
@end

@implementation MPRPCProtocolTest

- (void)test {
  MPRPCProtocol *protocol = [[MPRPCProtocol alloc] init];
  NSData *data = [protocol encodeRequestWithMethod:@"test" params:@[@{@"arg1": @"val1"}] messageId:1 options:0 encodeError:nil];
  XCTAssertNotNil(data);

  NSData *data2 = [protocol encodeResponseWithResult:@(1) error:nil messageId:1 options:0 encodeError:nil];
  XCTAssertNotNil(data2);
}

@end
