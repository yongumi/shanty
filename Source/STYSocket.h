//
//  STYSocket.h
//  Shanty
//
//  Created by Jonathan Wight on 1/2/14.
//  Copyright (c) 2014 schwa.io. All rights reserved.
//

@import Foundation;

#import "STYCompletionBlocks.h"

@class STYAddress;

@interface STYSocket : NSObject

@property (readonly, nonatomic, strong) __attribute__((NSObject)) CFSocketRef CFSocket;
@property (readonly, nonatomic) dispatch_queue_t queue;
@property (readonly, nonatomic) dispatch_io_t channel;
@property (readonly, nonatomic) dispatch_source_t readSource;
@property (readwrite, nonatomic, copy) void (^readHandler)(void);

- (instancetype)init;
- (instancetype)initWithCFSocket:(CFSocketRef)inSocket;

- (STYAddress *)address;
- (STYAddress *)peerAddress;

// TODO make initWithAddress: and roll connect: into start, rename start. stop -> cancel
- (void)connect:(STYAddress *)inAddress completion:(STYCompletionBlock)inCompletion;

// TODO Rename. Open? Close? It's not clear that you need to call start after connect (connect and cancel)
- (void)start:(STYCompletionBlock)inCompletion;
- (void)stop:(STYCompletionBlock)inCompletion;

@end
