//
//  ShantyMessagingPeer.h
//  Shanty
//
//  Created by Jonathan Wight on 11/4/13.
//  Copyright (c) 2013 schwa.io. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ShantyMessage;
@class ShantyMessagingPeer;

typedef BOOL (^MessageHandlerBlock)(ShantyMessagingPeer *inPeer, ShantyMessage *inMessage, NSError **outError);

@interface ShantyMessagingPeer : NSObject

- (instancetype)initWithSocket:(CFSocketRef)inSocket;
- (instancetype)initWithSocket:(CFSocketRef)inSocket messageHandlers:(NSDictionary *)inMessageHandlers;

- (void)sendMessage:(ShantyMessage *)inMessage replyBlock:(MessageHandlerBlock)inBlock;

- (void)addCommand:(NSString *)inCommand handler:(MessageHandlerBlock)inBlock;

@end
