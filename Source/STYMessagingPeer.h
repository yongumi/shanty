//
//  STYMessagingPeer.h
//  Shanty
//
//  Created by Jonathan Wight on 11/4/13.
//  Copyright (c) 2013 schwa.io. All rights reserved.
//

#import <Foundation/Foundation.h>

@class STYMessage;
@class STYMessagingPeer;
@class STYMessageHandler;

typedef BOOL (^STYMessageBlock)(STYMessagingPeer *inPeer, STYMessage *inMessage, NSError **outError);

@interface STYMessagingPeer : NSObject

@property (readonly, nonatomic) STYMessageHandler *messageHandler;

- (instancetype)initWithSocket:(CFSocketRef)inSocket;
- (instancetype)initWithSocket:(CFSocketRef)inSocket messageHandler:(STYMessageHandler *)inMessageHandler;

// TODO close handler...

- (void)sendMessage:(STYMessage *)inMessage replyBlock:(STYMessageBlock)inBlock;

@end
