//
//  STYServer.m
//  Shanty
//
//  Created by Jonathan Wight on 10/29/13.
//  Copyright (c) 2013 schwa.io. All rights reserved.
//

#import "STYServer.h"

#if TARGET_OS_IPHONE == 1
@import UIKit;
#endif

#include <sys/socket.h>
#include <netinet/in.h>
#include <unistd.h>

#import "STYMessagingPeer.h"
#import "NSNetService+STYUserInfo.h"
#import "STYMessageHandler.h"
#import "STYSocket.h"

static void TCPSocketListenerAcceptCallBack(CFSocketRef inSocket, CFSocketCallBackType inCallbackType, CFDataRef inAddress, const void *inData, void *ioInfo);

@interface STYServer () <NSNetServiceDelegate, STYMessagingPeerDelegate>
@property (readonly, nonatomic, copy) NSMutableSet *mutablePeers;
@property (readwrite, nonatomic, strong) __attribute__((NSObject)) CFSocketRef IPV4Socket;
@property (readwrite, nonatomic, strong) __attribute__((NSObject)) CFRunLoopRef runLoop;
@property (readwrite, nonatomic, strong) __attribute__((NSObject)) CFRunLoopSourceRef runLoopSource;
@property (readwrite, nonatomic) NSNetService *netService;
@end

#pragma mark -

@implementation STYServer

- (instancetype)init
    {
    if ((self = [super init]) != NULL)
        {
        _netServiceDomain = @"local.";

#if TARGET_OS_IPHONE == 1
        NSString *theType = [[[[NSBundle mainBundle] bundleIdentifier] stringByReplacingOccurrencesOfString:@"." withString:@"-"] lowercaseString];
        _netServiceType = [NSString stringWithFormat:@"_%@._tcp.", theType];
        NSString *theName = [NSString stringWithFormat:@"%@ on %@ (%d)",
            [[NSBundle mainBundle] infoDictionary][(__bridge NSString *)kCFBundleNameKey],
            [[UIDevice currentDevice] name],
            getpid()
            ];
        _netServiceName = theName;
#endif

        _mutablePeers = [NSMutableSet set];
        _messageHandler = [[STYMessageHandler alloc] init];
        }
    return self;
    }

- (void)dealloc
    {
    [self stopListening:NULL];
    }

#pragma mark -

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
    [self _startListening:^(NSError *error) {
        if (error == NULL)
            {
            [self _startPublishing:inResultHandler];
            }
        }];
    }

- (void)stopListening:(STYCompletionBlock)inResultHandler
    {
    [self _stopPublishing:NULL];

    if (self.runLoopSource != NULL)
        {
        CFRunLoopRemoveSource(self.runLoop, self.runLoopSource, kCFRunLoopCommonModes);
        self.runLoopSource = NULL;
        }

    self.IPV4Socket = NULL;
    }

#pragma mark -

- (void)_startListening:(STYCompletionBlock)inResultHandler
    {
//getifaddrs

    // Create an IPV4 address...
    struct sockaddr_in theAddress = {
        .sin_len = sizeof(theAddress),
        .sin_family = AF_INET, // IPV4 style address
        .sin_port = htons(self.port),
        .sin_addr = htonl(INADDR_ANY),
        };

    CFSocketContext theSocketContext = {
        .info = (__bridge void *)self
        };
    self.IPV4Socket = CFSocketCreate(kCFAllocatorDefault, PF_INET, SOCK_STREAM, IPPROTO_TCP, kCFSocketAcceptCallBack, TCPSocketListenerAcceptCallBack, &theSocketContext);
    if (self.IPV4Socket == NULL)
        {
        NSLog(@"ERROR: Could not create socket %d", errno);
        return;
        }

    // Turn on socket flags...
    int theReuseSocketFlag = 1;
    int result = setsockopt(CFSocketGetNative(self.IPV4Socket), SOL_SOCKET, SO_REUSEADDR, (void *)&theReuseSocketFlag, sizeof(theReuseSocketFlag));
    if (result != 0)
        {
        NSLog(@"ERROR: Could not setsockopt");
        return;
        }

    // Set the socket address...
    CFSocketSetAddress(self.IPV4Socket, (__bridge CFDataRef)[NSData dataWithBytes:&theAddress length:sizeof(theAddress)]);

    // Get the port...
    NSData *addr = (__bridge_transfer NSData *)CFSocketCopyAddress(self.IPV4Socket);
    memcpy(&theAddress, [addr bytes], [addr length]);
    if (self.port == 0)
        {
        self.port = ntohs(theAddress.sin_port);
        }

    // Shove it all into a runloop
    CFRunLoopSourceRef theRunLoopSource = CFSocketCreateRunLoopSource(kCFAllocatorDefault, self.IPV4Socket, 0);
    CFRunLoopAddSource(self.runLoop, theRunLoopSource, kCFRunLoopCommonModes);
    self.runLoopSource = theRunLoopSource;
    CFRelease(theRunLoopSource);

    if (inResultHandler)
        {
        NSLog(@"Serving...");
        inResultHandler(NULL);
        }
    }

- (void)_startPublishing:(STYCompletionBlock)inResultHandler
    {
    NSParameterAssert(self.netService == NULL);

    self.netService = [[NSNetService alloc] initWithDomain:self.netServiceDomain type:self.netServiceType name:self.netServiceName port:self.port];
    self.netService.sty_userInfo = [inResultHandler copy];
    self.netService.delegate = self;
    [self.netService publishWithOptions:0];
    }

- (void)_stopPublishing:(STYCompletionBlock)inResultHandler
    {
    NSParameterAssert(self.netService != NULL);

    self.netService.delegate = NULL;
    [self.netService stop];
    self.netService = NULL;
    }

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
        }

    STYMessagingPeer *thePeer = [[theClass alloc] initWithMessageHandler:self.messageHandler];
    thePeer.delegate = self;

    STYSocket *theSocket = [[STYSocket alloc] initWithCFSocket:inSocket];
    [thePeer openWithMode:kSTYMessengerModeServer socket:theSocket];

    [self.mutablePeers addObject:thePeer];

    if ([self.delegate respondsToSelector:@selector(server:peerDidConnect:)])
        {
        [self.delegate server:self peerDidConnect:thePeer];
        }
    }

#pragma mark -

- (void)netServiceDidPublish:(NSNetService *)sender
    {
    STYCompletionBlock theBlock = sender.sty_userInfo;
    if (theBlock)
        {
        theBlock(NULL);
        sender.sty_userInfo = NULL;
        }
    }

- (void)netService:(NSNetService *)sender didNotPublish:(NSDictionary *)errorDict
    {
    STYCompletionBlock theBlock = sender.sty_userInfo;
    if (theBlock)
        {
        theBlock([NSError errorWithDomain:@"TODO_DOMAIN" code:-1 userInfo:NULL]);
        sender.sty_userInfo = NULL;
        }
    }

#pragma mark -

- (void)messagingPeerRemoteDidDisconnect:(STYMessagingPeer *)inPeer
    {
    [self.mutablePeers removeObject:inPeer];
    if ([self.delegate respondsToSelector:@selector(server:peerDidDisconnect:)])
        {
        [self.delegate server:self peerDidDisconnect:inPeer];
        }
    }

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
