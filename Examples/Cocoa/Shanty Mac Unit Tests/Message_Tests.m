//
//  NetTest_Tests.m
//  Shanty Networking Tests
//
//  Created by Jonathan Wight on 11/4/13.
//  Copyright (c) 2013 schwa.io. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "STYMessage.h"

@interface Message_Tests : XCTestCase

@end

@implementation Message_Tests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample
{
	STYMessage *theMessage = [[STYMessage alloc] initWithControlData:@{} metadata:@{} data:NULL];
	STYMessage *theOtherMessage = [[STYMessage alloc] initWithDataBuffer:[theMessage buffer:NULL] error:NULL];
	XCTAssertEqualObjects([theMessage buffer:NULL], [theOtherMessage buffer:NULL], @"");
}

@end
