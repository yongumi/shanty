//
//  STYServer.m
//  Shanty
//
//  Created by Jonathan Wight on 10/29/13.
//  Copyright (c) 2013 schwa.io. All rights reserved.
//

#import "STYServer.h"

#if TARGET_OS_IPHONE == 1
#import <UIKit/UIKit.h>
#endif

#include <sys/socket.h>
#include <netinet/in.h>
#include <unistd.h>

#import "STYMessagingPeer.h"
#import "STYMessageHandler.h"
#import "STYSocket.h"
#import "STYAddress.h"
#import "STYLogger.h"
#import "STYConstants.h"
#import "STYServicePublisher.h"

static void TCPSocketListenerAcceptCallBack(CFSocketRef inSocket, CFSocketCallBackType inCallbackType, CFDataRef inAddress, const void *inData, void *ioInfo);

@interface STYServer ()
@property (readwrite, nonatomic, copy) STYAddress *actualAddress;
@property (readonly, nonatomic, copy) NSMutableSet *mutablePeers;
@property (readwrite, nonatomic, strong) __attribute__((NSObject)) CFSocketRef IPV4Socket;
@property (readwrite, nonatomic, strong) __attribute__((NSObject)) CFRunLoopRef runLoop;
@property (readwrite, nonatomic, strong) __attribute__((NSObject)) CFRunLoopSourceRef runLoopSource;
@property (readwrite, nonatomic) BOOL listening;
@property (readwrite, nonatomic) dispatch_source_t source;
@property (readwrite, nonatomic) STYServicePublisher *servicePublisher;
@end

#pragma mark -

@implementation STYServer

- (instancetype)initWithListeningAddress:(STYAddress *)inListeningAddress
    {
    if ((self = [super init]) != NULL)
        {
        _address = [inListeningAddress copy];

        _mutablePeers = [NSMutableSet set];
        _messageHandler = [[STYMessageHandler alloc] init];
        }
    return self;
    }

- (instancetype)initWithListeningAddress:(STYAddress *)inListeningAddress netServiceDomain:(NSString *)inDomain type:(NSString *)inType name:(NSString *)inName
    {
    if ((self = [self initWithListeningAddress:inListeningAddress]) != NULL)
        {
        _servicePublisher = [[STYServicePublisher alloc] initWithNetServiceDomain:inDomain type:inType name:inName port:0];
        }
    return self;
    }

- (void)dealloc
    {
    [self stopListening:NULL];
    }

#pragma mark -

- (STYServicePublisher *)servicePublisher
    {
    if (_servicePublisher == NULL)
        {
        }
    return _servicePublisher;
    }

- (NSSet *)peers
    {
    return(self.mutablePeers);
    }

- (CFRunLoopRef)runLoop
    {
    if (_runLoop == NULL)
        {
        _runLoop = CFRunLoopGetCurrent();
        }
    return(_runLoop);
    }

#pragma mark -

- (void)startListening:(STYCompletionBlock)inResultHandler
    {
    if (self.listening == YES)
        {
        if (inResultHandler != NULL)
            {
            inResultHandler(NULL);
            }
        return;
        }
        
    STYLogDebug_(@"Start listening.");

    CFSocketContext theSocketContext = {
        .info = (__bridge void *)self
        };
    self.IPV4Socket = CFSocketCreate(kCFAllocatorDefault, PF_INET, SOCK_STREAM, IPPROTO_TCP, kCFSocketAcceptCallBack, TCPSocketListenerAcceptCallBack, &theSocketContext);
    if (self.IPV4Socket == NULL)
        {
        STYLogDebug_(@"ERROR: Could not create socket %d", errno);
        return;
        }

    // Turn on socket flags...
    int theReuseSocketFlag = 1;
    int result = setsockopt(CFSocketGetNative(self.IPV4Socket), SOL_SOCKET, SO_REUSEADDR, (void *)&theReuseSocketFlag, sizeof(theReuseSocketFlag));
    if (result != 0)
        {
        STYLogDebug_(@"ERROR: Could not setsockopt");
        return;
        }
    
    NSData *theAddressData = [self.address.addresses firstObject];
    NSParameterAssert(theAddressData != NULL);
    CFSocketSetAddress(self.IPV4Socket, (__bridge CFDataRef)theAddressData);

    // Get the port...
    if (self.address.port == 0)
        {
        STYAddress *theServingAddress = [[STYAddress alloc] initWithAddresses:@[ (__bridge_transfer NSData *)CFSocketCopyAddress(self.IPV4Socket) ]];
        self.actualAddress = theServingAddress;
        }

    // Add the CFSocket to the runloop - this will be used to notify us of connections from clients...
    CFRunLoopSourceRef theRunLoopSource = CFSocketCreateRunLoopSource(kCFAllocatorDefault, self.IPV4Socket, 0);
    CFRunLoopAddSource(self.runLoop, theRunLoopSource, kCFRunLoopCommonModes);
    self.runLoopSource = theRunLoopSource;
    CFRelease(theRunLoopSource);

    STYLogDebug_(@"Listening on: %@", self.actualAddress);

    self.servicePublisher.port = self.actualAddress.port;

    [self.servicePublisher startPublishing:inResultHandler];
    }

- (void)stopListening:(STYCompletionBlock)inResultHandler
    {
    if (self.listening == NO)
        {
        if (inResultHandler != NULL)
            {
            inResultHandler(NULL);
            }
        return;
        }

    STYLogDebug_(@"Stop listening.");

    if (self.runLoopSource != NULL)
        {
        CFRunLoopRemoveSource(self.runLoop, self.runLoopSource, kCFRunLoopCommonModes);
        self.runLoopSource = NULL;
        }

    self.IPV4Socket = NULL;

    [self.servicePublisher stopPublishing:inResultHandler];
    }
    

#pragma mark -

- (void)_acceptSocket:(CFSocketRef)inSocket address:(NSData *)inAddress
    {
    if ([self.delegate respondsToSelector:@selector(server:peerCanConnectWithSocket:)])
        {
        if ([self.delegate server:self peerCanConnectWithSocket:inSocket] == NO)
            {
            return;
            }
        }

    Class theClass = [STYMessagingPeer class];
    if ([self.delegate respondsToSelector:@selector(server:classForPeerWithSocket:)])
        {
        theClass = [self.delegate server:self classForPeerWithSocket:inSocket];
        NSParameterAssert(theClass != NULL);
        }

    STYSocket *theSocket = [[STYSocket alloc] initWithCFSocket:inSocket];

    STYMessagingPeer *thePeer = [[theClass alloc] initWithMode:kSTYMessengerModeServer socket:theSocket name:NULL];
    thePeer.messageHandler = self.messageHandler;

    [thePeer open:NULL];

    [self.mutablePeers addObject:thePeer];

    if ([self.delegate respondsToSelector:@selector(server:peerDidConnect:)])
        {
        [self.delegate server:self peerDidConnect:thePeer];
        }
    }

#pragma mark -

@end

#pragma mark -

static void TCPSocketListenerAcceptCallBack(CFSocketRef inSocket, CFSocketCallBackType inCallbackType, CFDataRef inAddress, const void *inData, void *ioInfo)
    {
    #pragma unused (inSocket, inAddress)

    STYServer *theServer = (__bridge STYServer *)ioInfo;
    if (inCallbackType == kCFSocketAcceptCallBack)
        {
        CFSocketNativeHandle theNativeSocketHandle = *(CFSocketNativeHandle *)inData;
        CFSocketRef theSocket = CFSocketCreateWithNative(kCFAllocatorDefault, theNativeSocketHandle, 0, NULL, NULL);

        // for an AcceptCallBack, the data parameter is a pointer to a CFSocketNativeHandle
        uint8_t theSocketName[SOCK_MAXADDRLEN];
        socklen_t theSocketNameLength = sizeof(theSocketName);
        NSData *thePeerAddress = NULL;
        if (getpeername(theNativeSocketHandle, (struct sockaddr *)theSocketName, &theSocketNameLength) == 0)
            {
            thePeerAddress = [NSData dataWithBytes:theSocketName length:theSocketNameLength];
            }

        [theServer _acceptSocket:theSocket address:thePeerAddress];
        CFRelease(theSocket);
        }
    }
