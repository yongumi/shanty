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
@class STYAddress;

@protocol STYServerDelegate;

@interface STYServer : NSObject

@property (readwrite, nonatomic, copy) STYAddress *address;

@property (readwrite, nonatomic, copy) NSString *netServiceDomain;
@property (readwrite, nonatomic, copy) NSString *netServiceType;
@property (readwrite, nonatomic, copy) NSString *netServiceName;

@property (readwrite, nonatomic, copy) STYMessageHandler *messageHandler;
@property (readwrite, nonatomic, weak) id <STYServerDelegate> delegate;

@property (readonly, nonatomic, copy) NSSet *peers;

+ (NSString *)defaultNetServiceDomain;
+ (NSString *)defaultNetServiceType;
+ (NSString *)defaultNetServiceName;

- (instancetype)init; // Designated initializer.
- (instancetype)initWithNetServiceDomain:(NSString *)inDomain type:(NSString *)inType name:(NSString *)inName;

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
