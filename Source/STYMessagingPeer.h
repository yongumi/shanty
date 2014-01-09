//
//  STYMessagingPeer.h
//  Shanty
//
//  Created by Jonathan Wight on 11/4/13.
//  Copyright (c) 2013 schwa.io. All rights reserved.
//

@import Foundation;

#import "STYCompletionBlocks.h"

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

typedef BOOL (^STYMessageBlock)(STYMessagingPeer *inPeer, STYMessage *inMessage, NSError **outError);

@interface STYMessagingPeer : NSObject

@property (readonly, nonatomic) STYMessengerMode mode;
@property (readonly, nonatomic) STYMessageHandler *messageHandler;
@property (readwrite, nonatomic) id userInfo;

- (instancetype)initWithMessageHandler:(STYMessageHandler *)inMessageHandler;

- (void)openWithMode:(STYMessengerMode)inMode socket:(STYSocket *)inSocket completion:(STYCompletionBlock)inCompletion;
- (void)close:(STYCompletionBlock)inCompletion;

- (void)sendMessage:(STYMessage *)inMessage completion:(STYCompletionBlock)inCompletion;
- (void)sendMessage:(STYMessage *)inMessage replyHandler:(STYMessageBlock)inReplyHandler completion:(STYCompletionBlock)inCompletion;

@end
