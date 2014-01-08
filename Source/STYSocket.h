//
//  STYSocket.h
//  Shanty
//
//  Created by Jonathan Wight on 1/2/14.
//  Copyright (c) 2014 schwa.io. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STYCompletionBlocks.h"

@class STYAddress;

@interface STYSocket : NSObject

@property (readonly, nonatomic, strong) __attribute__((NSObject)) CFSocketRef CFSocket;
@property (readonly, nonatomic) dispatch_queue_t queue;
@property (readonly, nonatomic) dispatch_io_t channel;
@property (readonly, nonatomic) dispatch_source_t readSource;

- (instancetype)init;
- (instancetype)initWithCFSocket:(CFSocketRef)inSocket;

- (STYAddress *)address;
- (STYAddress *)peerAddress;

- (void)connect:(STYAddress *)inAddress completion:(STYCompletionBlock)inCompletionBlock;

// TODO Rename. Open? Close?
- (void)start:(void (^)(void))readCallback;
- (void)stop;

@end
