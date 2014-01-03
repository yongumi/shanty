//
//  STYClient.h
//  Shanty
//
//  Created by Jonathan Wight on 11/4/13.
//  Copyright (c) 2013 schwa.io. All rights reserved.
//

@import Foundation;

#import "STYCompletionBlocks.h"

@class STYAddress;
@class STYMessagingPeer;
@class STYMessageHandler;

@interface STYClient : NSObject

@property (readonly, nonatomic, strong) __attribute__((NSObject)) CFSocketRef socket;
@property (readwrite, nonatomic, copy) STYMessageHandler *messageHandler;
@property (readonly, nonatomic) STYMessagingPeer *peer;

- (instancetype)initWithAddress:(STYAddress *)inAddress;

- (void)connect:(STYCompletionBlock)inCompletionBlock;

@end
