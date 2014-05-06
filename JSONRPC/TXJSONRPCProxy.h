//
//  TXJSONRPCProxy.h
//  Shanty
//
//  Created by Jonathan Wight on 5/2/14.
//  Copyright (c) 2014 schwa.io. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TXJSONRPCFunctionCall;
@class TXJSONRPCFunctionResult;

@protocol TXJSONRPCProxyDelegate;

#pragma mark -

@interface TXJSONRPCProxy : NSProxy

@property (readwrite, nonatomic, weak) id <TXJSONRPCProxyDelegate> delegate;

- (id)initWithProtocol:(Protocol *)inProtocol delegate:(id <TXJSONRPCProxyDelegate>)inDelegate;

@end

#pragma mark -

@protocol TXJSONRPCProxyDelegate <NSObject>
@required
- (TXJSONRPCFunctionResult *)JSONRPCProxy:(TXJSONRPCProxy *)inProxy call:(TXJSONRPCFunctionCall *)inCall;
@end
