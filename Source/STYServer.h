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
@class STYMessagingPeer;
@protocol STYServerDelegate;

@interface STYServer : NSObject

@property (readwrite, nonatomic, copy) NSString *host;
@property (readwrite, nonatomic) unsigned short port;
@property (readwrite, nonatomic, copy) NSString *netServiceDomain;
@property (readwrite, nonatomic, copy) NSString *netServiceType;
@property (readwrite, nonatomic, copy) NSString *netServiceName;
@property (readonly, nonatomic, copy) NSSet *peers;
@property (readwrite, nonatomic, copy) STYMessageHandler *messageHandler;
@property (readwrite, nonatomic, weak) id <STYServerDelegate> delegate;

- (void)startListening:(STYCompletionBlock)inResultHandler;
- (void)stopListening:(STYCompletionBlock)inResultHandler;

@end

#pragma mark -

@protocol STYServerDelegate <NSObject>

@optional
- (BOOL)server:(STYServer *)inServer peerCanConnectWithSocket:(CFSocketRef)inSocket;
- (Class)server:(STYServer *)inServer classForPeerWithSocket:(CFSocketRef)inSocket;
- (void)server:(STYServer *)inServer peerDidConnect:(STYMessagingPeer *)inPeer;
- (void)server:(STYServer *)inServer peerDidDisconnect:(STYMessagingPeer *)inPeer;

@end