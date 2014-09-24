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

@property (readonly, nonatomic) STYMessengerMode mode; // TODO: Will be deprecated.
@property (readonly, nonatomic) STYTransport *transport;
@property (readonly, atomic) STYPeerState state;
@property (readonly, nonatomic) STYMessageHandler *systemHandler;
@property (readonly, nonatomic) STYMessageHandler *messageHandler;
@property (readonly, nonatomic, copy) NSString *name;
@property (readonly, nonatomic, copy) NSUUID *UUID;
@property (readwrite, nonatomic, weak) id <STYPeerDelegate> delegate;

- (instancetype)initWithMode:(STYMessengerMode)inMode socket:(STYSocket *)inSocket name:(NSString *)inName;

- (void)prepareSystemHandler;

- (void)open:(STYCompletionBlock)inCompletion;
- (void)close:(STYCompletionBlock)inCompletion;

- (void)sendMessage:(STYMessage *)inMessage completion:(STYCompletionBlock)inCompletion;
- (void)sendMessage:(STYMessage *)inMessage replyHandler:(STYMessageBlock)inReplyHandler completion:(STYCompletionBlock)inCompletion;

- (NSDictionary *)makeHelloMetadata:(NSDictionary *)inExtras;
@end

#pragma mark -

@protocol STYPeerDelegate <NSObject>
@optional
- (void)peerDidClose:(STYPeer *)inPeer;

- (NSString *)peerRequestSecret:(STYPeer *)inPeer;

@end

#pragma mark -

@interface STYPeer (Subclassing)
@property (readwrite, atomic) STYPeerState state; // TODO: Should be readonly but needed by subclasses.
@property (readwrite, nonatomic) STYMessageHandler *systemHandler; // TODO: Should be readonly but needed by subclasses.
@property (readwrite, nonatomic) STYMessageHandler *messageHandler;

- (void)willChangeToState:(STYPeerState)inState fromState:(STYPeerState)inOldState;
- (void)didChangeToState:(STYPeerState)inState fromState:(STYPeerState)inOldState;

@end
