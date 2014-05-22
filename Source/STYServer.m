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
#import "NSNetService+STYUserInfo.h"
#import "STYMessageHandler.h"
#import "STYSocket.h"
#import "STYAddress.h"
#import "STYLogger.h"
#import "STYConstants.h"

static void TCPSocketListenerAcceptCallBack(CFSocketRef inSocket, CFSocketCallBackType inCallbackType, CFDataRef inAddress, const void *inData, void *ioInfo);

@interface STYServer () <NSNetServiceDelegate>
//@property (readwrite, nonatomic, copy) STYAddress *address;
@property (readonly, nonatomic, copy) NSMutableSet *mutablePeers;
@property (readwrite, nonatomic, strong) __attribute__((NSObject)) CFSocketRef IPV4Socket;
@property (readwrite, nonatomic, strong) __attribute__((NSObject)) CFRunLoopRef runLoop;
@property (readwrite, nonatomic, strong) __attribute__((NSObject)) CFRunLoopSourceRef runLoopSource;
@property (readwrite, nonatomic) NSNetService *netService;
@end

#pragma mark -

@implementation STYServer

+ (NSString *)defaultNetServiceDomain
    {
    return(@"");
    }

+ (NSString *)defaultNetServiceType
    {
    NSString *theType = [[[[NSBundle mainBundle] bundleIdentifier] stringByReplacingOccurrencesOfString:@"." withString:@"-"] lowercaseString];
    return([NSString stringWithFormat:@"_%@._tcp.", theType]);
    }

+ (NSString *)defaultNetServiceName
    {
    NSString *theName = [NSString stringWithFormat:@"%@ on %@ (%d)",
        [[NSBundle mainBundle] infoDictionary][(__bridge NSString *)kCFBundleNameKey],
#if TARGET_OS_IPHONE == 1
        [[UIDevice currentDevice] name],
#else
        @"<some Macintosh>",
#endif
        getpid()
        ];
    return(theName);
    }

- (instancetype)init
    {
    if ((self = [super init]) != NULL)
        {
        _address = [[STYAddress alloc] init];

        _netServiceDomain = [[[self class] defaultNetServiceDomain] copy];
        _netServiceType = [[[self class] defaultNetServiceType] copy];
        _netServiceName = [[[self class] defaultNetServiceName] copy];

        _mutablePeers = [NSMutableSet set];
        _messageHandler = [[STYMessageHandler alloc] init];
        }
    return self;
    }

- (instancetype)initWithNetServiceDomain:(NSString *)inDomain type:(NSString *)inType name:(NSString *)inName
    {
    if ((self = [self init]) != NULL)
        {
        if (inDomain != NULL)
            {
            _netServiceDomain = [inDomain copy];
            }
        if (inType != NULL)
            {
            _netServiceType = [inType copy];
            }
        if (inName != NULL)
            {
            _netServiceName = [inName copy];
            }
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
    [self _stopPublishing];

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
    // Create an IPV4 address...
    struct sockaddr_in theAddress = {
        .sin_len = sizeof(theAddress),
        .sin_family = AF_INET, // IPV4 style address
        .sin_port = htons(self.address.port),
        .sin_addr = htonl(INADDR_ANY),
        };

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

    // Set the socket address...
    CFSocketSetAddress(self.IPV4Socket, (__bridge CFDataRef)[NSData dataWithBytes:&theAddress length:sizeof(theAddress)]);

    // Get the port...
    if (self.address.port == 0)
        {
        NSData *addr = (__bridge_transfer NSData *)CFSocketCopyAddress(self.IPV4Socket);
        memcpy(&theAddress, [addr bytes], [addr length]);
        self.address = [self.address addressBySettingPort:ntohs(theAddress.sin_port)];
        }

    // Shove it all into a runloop
    CFRunLoopSourceRef theRunLoopSource = CFSocketCreateRunLoopSource(kCFAllocatorDefault, self.IPV4Socket, 0);
    CFRunLoopAddSource(self.runLoop, theRunLoopSource, kCFRunLoopCommonModes);
    self.runLoopSource = theRunLoopSource;
    CFRelease(theRunLoopSource);

    if (inResultHandler)
        {
        inResultHandler(NULL);
        }
    }

- (void)_startPublishing:(STYCompletionBlock)inResultHandler
    {
    NSParameterAssert(self.netService == NULL);

    self.netService = [[NSNetService alloc] initWithDomain:self.netServiceDomain type:self.netServiceType name:self.netServiceName port:self.address.port];
    self.netService.sty_userInfo = [inResultHandler copy];
    self.netService.delegate = self;
    [self.netService publishWithOptions:0];
    }

- (void)_stopPublishing
    {
    if (self.netService != NULL)
        {
        self.netService.delegate = NULL;
        [self.netService stop];
        self.netService = NULL;
        }
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
        theBlock([NSError errorWithDomain:kSTYErrorDomain code:-1 userInfo:NULL]);
        sender.sty_userInfo = NULL;
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
