//
//  STYServer.h
//  Shanty
//
//  Created by Jonathan Wight on 10/29/13.
//  Copyright (c) 2013 schwa.io. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STYCompletionBlocks.h"

@class STYMessageHandler;
@class STYPeer;
@class STYAddress;

@protocol STYServerDelegate;

@interface STYServer : NSObject

@property (readonly, nonatomic, copy) STYAddress *address;
@property (readonly, nonatomic, copy) STYAddress *actualAddress;

@property (readwrite, nonatomic) BOOL publishOnLocalhostOnly;

@property (readwrite, nonatomic, copy) STYMessageHandler *messageHandler;
@property (readwrite, nonatomic, weak) id <STYServerDelegate> delegate;

@property (readonly, nonatomic, copy) NSArray *peers;

@property (readonly, nonatomic) BOOL listening;
@property (readonly, nonatomic) BOOL publishing;

+ (NSString *)randomCode;

- (instancetype)initWithListeningAddress:(STYAddress *)inListeningAddress; // Designated initializer.
- (instancetype)initWithListeningAddress:(STYAddress *)inListeningAddress netServiceDomain:(NSString *)inDomain type:(NSString *)inType name:(NSString *)inName;

- (void)startListening:(STYCompletionBlock)inResultHandler;
- (void)stopListening:(STYCompletionBlock)inResultHandler;

@end

#pragma mark -

@protocol STYServerDelegate <NSObject>

@optional
- (BOOL)server:(STYServer *)inServer peerCanConnectWithSocket:(CFSocketRef)inSocket;
- (Class)server:(STYServer *)inServer classForPeerWithSocket:(CFSocketRef)inSocket;
- (void)server:(STYServer *)inServer didCreatePeer:(STYPeer *)inPeer;
- (void)server:(STYServer *)inServer peerWillConnect:(STYPeer *)inPeer;
- (void)server:(STYServer *)inServer peerDidConnect:(STYPeer *)inPeer;
- (void)server:(STYServer *)inServer peerDidDisconnect:(STYPeer *)inPeer;

@end
