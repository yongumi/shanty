//
//  JSONRPCTest.h
//  Shanty
//
//  Created by Jonathan Wight on 5/1/14.
//  Copyright (c) 2014 schwa.io. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TXJSONRPCFunctionCall;
@class TXJSONRPCFunctionResult;

@interface TXJSONRPCVendor : NSObject

- (id)initWithProtocol:(Protocol *)inProtocol object:(id)inObject error:(NSError *__autoreleasing *)outError;

- (TXJSONRPCFunctionResult *)call:(TXJSONRPCFunctionCall *)inFunctionCall;
- (NSArray *)callBatch:(NSArray *)inCalls;

@end
