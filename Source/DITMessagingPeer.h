//
//  DITMessagingPeer.h
//  DIT
//
//  Created by Jonathan Wight on 11/4/13.
//  Copyright (c) 2013 schwa.io. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DITMessage;
@class DITMessagingPeer;

typedef BOOL (^MessageHandlerBlock)(DITMessagingPeer *inPeer, DITMessage *inMessage, NSError **outError);

@interface DITMessagingPeer : NSObject

- (instancetype)initWithSocket:(CFSocketRef)inSocket;
- (instancetype)initWithSocket:(CFSocketRef)inSocket messageHandlers:(NSDictionary *)inMessageHandlers;

- (void)sendMessage:(DITMessage *)inMessage replyBlock:(MessageHandlerBlock)inBlock;

- (void)addCommand:(NSString *)inCommand handler:(MessageHandlerBlock)inBlock;

@end
