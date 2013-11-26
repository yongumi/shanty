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

typedef BOOL (^STYMessageBlock)(STYMessagingPeer *inPeer, STYMessage *inMessage, NSError **outError);

@interface STYMessagingPeer : NSObject

- (instancetype)initWithSocket:(CFSocketRef)inSocket;
- (instancetype)initWithSocket:(CFSocketRef)inSocket messageHandlers:(NSDictionary *)inMessageHandlers;

- (void)sendMessage:(STYMessage *)inMessage replyBlock:(STYMessageBlock)inBlock;

- (void)addCommand:(NSString *)inCommand handler:(STYMessageBlock)inBlock;

@end
