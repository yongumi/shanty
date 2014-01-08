//
//  STYMessagingPeer.h
//  Shanty
//
//  Created by Jonathan Wight on 11/4/13.
//  Copyright (c) 2013 schwa.io. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef enum {
    kSTYMessengerModeUndefined,
    kSTYMessengerModeClient,
    kSTYMessengerModeServer
    } STYMessengerMode;

@class STYSocket;
@class STYAddress;
@class STYMessage;
@class STYMessagingPeer;
@class STYMessageHandler;
@protocol STYMessagingPeerDelegate;

typedef BOOL (^STYMessageBlock)(STYMessagingPeer *inPeer, STYMessage *inMessage, NSError **outError);

@interface STYMessagingPeer : NSObject

@property (readonly, nonatomic) STYMessengerMode mode;
@property (readonly, nonatomic) STYMessageHandler *messageHandler;
@property (readwrite, nonatomic, weak) id <STYMessagingPeerDelegate> delegate;
@property (readwrite, nonatomic) id userInfo;

- (instancetype)initWithMessageHandler:(STYMessageHandler *)inMessageHandler;

- (void)openWithMode:(STYMessengerMode)inMode socket:(STYSocket *)inSocket;
- (void)close;

- (void)sendMessage:(STYMessage *)inMessage replyBlock:(STYMessageBlock)inBlock;

@end

@protocol STYMessagingPeerDelegate <NSObject>
- (void)messagingPeerRemoteDidDisconnect:(STYMessagingPeer *)inPeer;
@end