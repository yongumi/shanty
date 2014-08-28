//
//  STYPeer.h
//  Shanty
//
//  Created by Jonathan Wight on 11/4/13.
//  Copyright (c) 2013 schwa.io. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STYCompletionBlocks.h"

// TODO: Rename
typedef NS_ENUM(NSInteger, STYMessengerMode) {
    kSTYMessengerModeUndefined,
    kSTYMessengerModeClient,
    kSTYMessengerModeServer
    };

typedef NS_ENUM(NSInteger, STYPeerState) {
    kSTYPeerStateUndefined,
    kSTYPeerStateOpening,
    kSTYPeerStateHandshaking,
    kSTYPeerStateChallengeResponse,
    kSTYPeerStateReady,
//    kSTYPeerStateClosing,
    kSTYPeerStateClosed,
    kSTYPeerStateError,
};

@class STYTransport;
@class STYSocket;
@class STYAddress;
@class STYMessage;
@class STYPeer;
@class STYMessageHandler;

@protocol STYPeerDelegate;

@interface STYPeer : NSObject

@property (readonly, nonatomic) STYMessengerMode mode;
@property (readonly, nonatomic) STYTransport *transport;
@property (readwrite, atomic) STYPeerState state; // TODO: Should be readonly but needed by subclasses.
@property (readwrite, nonatomic) STYMessageHandler *systemHandler; // TODO: Should be readonly but needed by subclasses.
@property (readwrite, nonatomic) STYMessageHandler *messageHandler;
@property (readonly, nonatomic, copy) NSString *name;
@property (readonly, nonatomic, copy) NSUUID *UUID;
@property (readwrite, nonatomic) id userInfo;
@property (readwrite, nonatomic, weak) id <STYPeerDelegate> delegate;

- (instancetype)initWithMode:(STYMessengerMode)inMode socket:(STYSocket *)inSocket name:(NSString *)inName;

- (void)open:(STYCompletionBlock)inCompletion;
- (void)close:(STYCompletionBlock)inCompletion;

//- (void)reopen:(STYCompletionBlock)inCompletion;

- (void)sendMessage:(STYMessage *)inMessage completion:(STYCompletionBlock)inCompletion;
- (void)sendMessage:(STYMessage *)inMessage replyHandler:(STYMessageBlock)inReplyHandler completion:(STYCompletionBlock)inCompletion;

- (NSDictionary *)makeHelloMetadata:(NSDictionary *)inExtras;

@end

#pragma mark -

@protocol STYPeerDelegate <NSObject>
@optional
- (void)peerWillChangeState:(STYPeer *)inPeer oldState:(STYPeerState)inOldState newState:(STYPeerState)inNewState;
- (void)peerDidChangeState:(STYPeer *)inPeer oldState:(STYPeerState)inOldState newState:(STYPeerState)inNewState;

// TODO: Will be deprecated.
- (void)peerDidClose:(STYPeer *)inPeer;
@end