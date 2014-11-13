//
//  STYSocket.h
//  Shanty
//
//  Created by Jonathan Wight on 1/2/14.
//  Copyright (c) 2014 schwa.io. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STYBlockTypes.h"

@class STYAddress;

@protocol STYSocketDelegate;

/**
 *  A representation of a POSIX socket exposing dispatch io properties...
 */
@interface STYSocket : NSObject

@property (readonly, nonatomic, copy) STYAddress *address;
@property (readonly, nonatomic, copy) STYAddress *peerAddress;
@property (readonly, nonatomic, strong) __attribute__((NSObject)) CFSocketRef CFSocket;
@property (readonly, nonatomic) dispatch_queue_t queue;
@property (readonly, nonatomic) BOOL connected;
@property (readonly, nonatomic) BOOL open;

@property (readwrite, atomic, weak) id <STYSocketDelegate> delegate;

/**
 *  Initializes the socket with an address.
 *
 *  The socket is not connected at this point.
 */
- (instancetype)initWithAddress:(STYAddress *)inAddress;

/**
 *  Initializes the socket with with a CFNetworking socket.
 *
 *  The socket is assumed to be connected at this point.
 */
- (instancetype)initWithCFSocket:(CFSocketRef)inSocket;

/**
 *  Opens the socket and prepares it for io. If the socket is not already connected it is connected first.
 */
- (void)open:(STYCompletionBlock)inCompletion;

- (void)close:(STYCompletionBlock)inCompletion;

//- (void)reopen:(STYCompletionBlock)inCompletion;

- (void)read:(dispatch_io_handler_t)inHandler;
- (void)write:(dispatch_data_t)inData completion:(STYCompletionBlock)inCompletion;

@end

#pragma mark -

@protocol STYSocketDelegate <NSObject>
@optional

- (void)socketHasDataAvailable:(STYSocket *)inSocket;
- (void)socketDidClose:(STYSocket *)inSocket;

@end
