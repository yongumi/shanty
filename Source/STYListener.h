//
//  STYListener.h
//  Shanty
//
//  Created by Jonathan Wight on 10/29/13.
//  Copyright (c) 2013 schwa.io. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STYBlockTypes.h"

@class STYMessageHandler;
@class STYPeer;
@class STYAddress;

@protocol STYListenerDelegate;

@interface STYListener : NSObject

@property (readonly, nonatomic, copy) STYAddress *address;
@property (readonly, nonatomic, copy) STYAddress *actualAddress;

@property (readwrite, nonatomic) BOOL publishOnLocalhostOnly;

@property (readwrite, nonatomic, copy) STYMessageHandler *messageHandler;
@property (readwrite, nonatomic, weak) id <STYListenerDelegate> delegate;

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

@protocol STYListenerDelegate <NSObject>

@optional
- (BOOL)listener:(STYListener *)inServer peerCanConnectWithSocket:(CFSocketRef)inSocket;
- (void)listener:(STYListener *)inServer didCreatePeer:(STYPeer *)inPeer;
- (void)listener:(STYListener *)inServer peerWillConnect:(STYPeer *)inPeer;
- (void)listener:(STYListener *)inServer peerDidConnect:(STYPeer *)inPeer;
- (void)listener:(STYListener *)inServer peerDidDisconnect:(STYPeer *)inPeer;

@end
