//
//  STYPeer.h
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

typedef NS_ENUM(NSInteger, STYPeerState) {
    kSTYPeerStateUndefined,
    kSTYPeerStateOpening,
    kSTYPeerStateHandshaking,
//    kSTYPeerStateChallengeResponse,
    kSTYPeerStateReady,
//    kSTYPeerStateClosing,
    kSTYPeerStateClosed,
    kSTYPeerStateError,
};

@class STYSocket;
@class STYAddress;
@class STYMessage;
@class STYPeer;
@class STYMessageHandler;

typedef BOOL (^STYMessageBlock)(STYPeer *inPeer, STYMessage *inMessage, NSError **outError);

@protocol STYPeerDelegate;

@interface STYPeer : NSObject

@property (readonly, nonatomic) STYMessengerMode mode;
@property (readonly, nonatomic) STYPeerState state;
@property (readonly, nonatomic) STYSocket *socket;
@property (readonly, nonatomic) STYMessageHandler *systemHandler;
@property (readwrite, nonatomic) STYMessageHandler *messageHandler;
@property (readonly, nonatomic, copy) NSString *name;
@property (readonly, nonatomic, copy) NSUUID *UUID;
@property (readwrite, nonatomic) id userInfo;
@property (readwrite, nonatomic, copy) STYMessageBlock tap;
@property (readwrite, nonatomic, weak) id <STYPeerDelegate> delegate;

- (instancetype)initWithMode:(STYMessengerMode)inMode socket:(STYSocket *)inSocket name:(NSString *)inName;

- (void)open:(STYCompletionBlock)inCompletion;
- (void)close:(STYCompletionBlock)inCompletion;

//- (void)reopen:(STYCompletionBlock)inCompletion;

- (void)sendMessage:(STYMessage *)inMessage completion:(STYCompletionBlock)inCompletion;
- (void)sendMessage:(STYMessage *)inMessage replyHandler:(STYMessageBlock)inReplyHandler completion:(STYCompletionBlock)inCompletion;

@end

#pragma mark -

@protocol STYPeerDelegate <NSObject>
@optional
- (void)peerWillChangeState:(STYPeer *)inPeer oldState:(STYPeerState)inOldState newState:(STYPeerState)inNewState;
- (void)peerDidChangeState:(STYPeer *)inPeer oldState:(STYPeerState)inOldState newState:(STYPeerState)inNewState;

// TODO: Will be deprecated.
- (void)peerDidClose:(STYPeer *)inPeer;
@end