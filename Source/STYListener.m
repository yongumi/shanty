//
//  STYListener.m
//  Shanty
//
//  Created by Jonathan Wight on 10/29/13.
//  Copyright (c) 2013 schwa.io. All rights reserved.
//

#import "STYListener.h"

#if TARGET_OS_IPHONE == 1
#import <UIKit/UIKit.h>
#endif

#include <sys/socket.h>
#include <netinet/in.h>
#include <unistd.h>

#import "STYServerPeer.h"
#import "STYMessageHandler.h"
#import "STYSocket.h"
#import "STYAddress.h"
#import "STYLogger.h"
#import "STYConstants.h"
#import "STYServicePublisher.h"

static void TCPSocketListenerAcceptCallBack(CFSocketRef inSocket, CFSocketCallBackType inCallbackType, CFDataRef inAddress, const void *inData, void *ioInfo);

@interface STYListener ()
@property (readwrite, nonatomic, copy) STYAddress *actualAddress;
@property (readonly, nonatomic, copy) NSMutableArray *mutablePeers;
@property (readwrite, nonatomic, strong) __attribute__((NSObject)) CFSocketRef IPV4Socket;
@property (readwrite, nonatomic, strong) __attribute__((NSObject)) CFRunLoopRef runLoop;
@property (readwrite, nonatomic, strong) __attribute__((NSObject)) CFRunLoopSourceRef runLoopSource;
@property (readwrite, nonatomic) BOOL listening;
@property (readwrite, nonatomic) dispatch_source_t source;
@property (readwrite, nonatomic) STYServicePublisher *servicePublisher;
@end

#pragma mark -

@implementation STYListener

+ (NSString *)randomCode
    {
    return [NSString stringWithFormat:@"%d%d%d%d", arc4random_uniform(10), arc4random_uniform(10), arc4random_uniform(10), arc4random_uniform(10)];
    }

- (instancetype)initWithListeningAddress:(STYAddress *)inListeningAddress
    {
    if ((self = [super init]) != NULL)
        {
        _address = [inListeningAddress copy];

        _mutablePeers = [NSMutableArray array];
        _messageHandler = [[STYMessageHandler alloc] init];
        }
    return self;
    }

- (instancetype)initWithListeningAddress:(STYAddress *)inListeningAddress netServiceDomain:(NSString *)inDomain type:(NSString *)inType name:(NSString *)inName
    {
    if ((self = [self initWithListeningAddress:inListeningAddress]) != NULL)
        {
        _servicePublisher = [[STYServicePublisher alloc] initWithNetServiceDomain:inDomain type:inType name:inName port:0];
        _servicePublisher.localhostOnly = _publishOnLocalhostOnly;
        }
    return self;
    }

- (void)dealloc
    {
    [self stopListening:NULL];
    
    self.IPV4Socket = nil;
    self.runLoop = nil;
    self.runLoopSource = nil;
    }

#pragma mark -

- (void)setPublishOnLocalhostOnly:(BOOL)publishOnLocalhostOnly
    {
    if (_publishOnLocalhostOnly != publishOnLocalhostOnly)
        {
        _publishOnLocalhostOnly = publishOnLocalhostOnly;

        _servicePublisher.localhostOnly = _publishOnLocalhostOnly;
        }
    }

#pragma mark -

- (NSArray *)peers
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
    
    // TODO - what about errors?
    self.listening = YES;
        
    CFSocketContext theSocketContext = {
        .info = (__bridge void *)self
        };
    CFSocketRef theSocket = CFSocketCreate(kCFAllocatorDefault, PF_INET, SOCK_STREAM, IPPROTO_TCP, kCFSocketAcceptCallBack, TCPSocketListenerAcceptCallBack, &theSocketContext);
    
    if (theSocket == NULL)
        {
        STYLogError_(@"Could not create socket %d", errno);
        return;
        }

    self.IPV4Socket = theSocket;
    CFRelease(theSocket);

    // Turn on socket flags...
    int theReuseSocketFlag = 1;
    int result = setsockopt(CFSocketGetNative(self.IPV4Socket), SOL_SOCKET, SO_REUSEADDR, (void *)&theReuseSocketFlag, sizeof(theReuseSocketFlag));
    if (result != 0)
        {
        STYLogError_(@"Could not setsockopt %d", errno);
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
    else
        {
        self.actualAddress = self.address;
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

    self.listening = NO;

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
    if ([self.delegate respondsToSelector:@selector(listener:peerCanConnectWithSocket:)])
        {
        if ([self.delegate listener:self peerCanConnectWithSocket:inSocket] == NO)
            {
            return;
            }
        }

    STYSocket *theSocket = [[STYSocket alloc] initWithCFSocket:inSocket];

    STYPeer *thePeer = [[STYServerPeer alloc] initWithMode:kSTYMessengerModeServer socket:theSocket name:NULL];
    if ([self.delegate respondsToSelector:@selector(listener:didCreatePeer:)])
        {
        [self.delegate listener:self didCreatePeer:thePeer];
        }


    thePeer.messageHandler = self.messageHandler;

    if ([self.delegate respondsToSelector:@selector(listener:peerWillConnect:)])
        {
        [self.delegate listener:self peerWillConnect:thePeer];
        }

    [thePeer open:NULL];

    NSParameterAssert([NSThread isMainThread]);
    [self willChangeValueForKey:@"peers"];
    [self.mutablePeers addObject:thePeer];
    [self didChangeValueForKey:@"peers"];

    if ([self.delegate respondsToSelector:@selector(listener:peerDidConnect:)])
        {
        [self.delegate listener:self peerDidConnect:thePeer];
        }
    }

@end

#pragma mark -

static void TCPSocketListenerAcceptCallBack(CFSocketRef inSocket, CFSocketCallBackType inCallbackType, CFDataRef inAddress, const void *inData, void *ioInfo)
    {
    #pragma unused (inSocket, inAddress)

    STYListener *theServer = (__bridge STYListener *)ioInfo;
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
