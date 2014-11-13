//
//  STYTransport.h
//  shanty
//
//  Created by Jonathan Wight on 8/25/14.
//  Copyright (c) 2014 schwa.io. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STYBlockTypes.h"

@class STYSocket;
@class STYAddress;
@class STYMessage;
@class STYPeer;
@class STYMessageHandler;

typedef NS_ENUM(NSInteger, STYTransportState) {
    kSTYTransportStateUndefined,
    kSTYTransportStateOpening,
    kSTYTransportStateReady,
//    kSTYTransportStateClosing,
    kSTYTransportStateClosed,
    kSTYTransportStateError,
};

@protocol STYTransportDelegate;

@interface STYTransport : NSObject

@property (readonly, nonatomic, weak) STYPeer *peer;
@property (readonly, atomic) STYTransportState state;
@property (readonly, nonatomic) STYSocket *socket;
@property (readwrite, nonatomic, copy) STYMessageBlock tap;
@property (readwrite, nonatomic, weak) id <STYTransportDelegate> delegate;

- (instancetype)initWithPeer:(STYPeer *)inPeer socket:(STYSocket *)inSocket;

- (void)open:(STYCompletionBlock)inCompletion;
- (void)close:(STYCompletionBlock)inCompletion;

- (STYMessage *)messageForSending:(STYMessage *)inMessage;

- (void)sendMessage:(STYMessage *)inMessage completion:(STYCompletionBlock)inCompletion;
- (void)sendMessage:(STYMessage *)inMessage replyHandler:(STYMessageBlock)inReplyHandler completion:(STYCompletionBlock)inCompletion;

@end

#pragma mark -

@protocol STYTransportDelegate <NSObject>
@optional
- (void)transport:(STYTransport *)inTransport didReceiveMessage:(STYMessage *)inMessage;
- (void)transportWillClose:(STYTransport *)inTransport;
@end