//
//  STYMessagingPeer.h
//  Shanty
//
//  Created by Jonathan Wight on 11/4/13.
//  Copyright (c) 2013 schwa.io. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STYCompletionBlocks.h"

typedef NS_ENUM(NSInteger, STYMessengerMode) {
    kSTYMessengerModeUndefined,
    kSTYMessengerModeClient,
    kSTYMessengerModeServer
    };

@class STYSocket;
@class STYAddress;
@class STYMessage;
@class STYMessagingPeer;
@class STYMessageHandler;

typedef BOOL (^STYMessageBlock)(STYMessagingPeer *inPeer, STYMessage *inMessage, NSError **outError);

@interface STYMessagingPeer : NSObject

@property (readonly, nonatomic) STYMessengerMode mode;
@property (readonly, nonatomic) STYSocket *socket;
@property (readwrite, nonatomic) STYMessageHandler *messageHandler;
@property (readonly, nonatomic, copy) NSString *name;
@property (readwrite, nonatomic) id userInfo;
@property (readwrite, nonatomic, copy) STYMessageBlock tap;
@property (readonly, nonatomic) BOOL open;

- (instancetype)initWithMode:(STYMessengerMode)inMode socket:(STYSocket *)inSocket name:(NSString *)inName;

- (void)open:(STYCompletionBlock)inCompletion;
- (void)close:(STYCompletionBlock)inCompletion;

//- (void)reopen:(STYCompletionBlock)inCompletion;

- (void)sendMessage:(STYMessage *)inMessage completion:(STYCompletionBlock)inCompletion;
- (void)sendMessage:(STYMessage *)inMessage replyHandler:(STYMessageBlock)inReplyHandler completion:(STYCompletionBlock)inCompletion;

@end
