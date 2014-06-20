//
//  STYSocket.m
//  Shanty
//
//  Created by Jonathan Wight on 1/2/14.
//  Copyright (c) 2014 schwa.io. All rights reserved.
//

#import "STYSocket.h"

#include <sys/socket.h>
#include <netinet/in.h>

#import "STYAddress.h"
#import "STYLogger.h"
#import "STYConstants.h"

@interface STYSocket ()
@property (readwrite, nonatomic, copy) STYAddress *address;
@property (readwrite, nonatomic, strong) __attribute__((NSObject)) CFSocketRef CFSocket;
@property (readwrite, nonatomic, strong) __attribute__((NSObject)) CFRunLoopSourceRef runLoopSource;
@property (readwrite, nonatomic) int connectTimeout;

@property (readwrite, nonatomic) BOOL connected;
@property (readwrite, nonatomic) BOOL open;
@property (readwrite, nonatomic) dispatch_queue_t queue;
@property (readwrite, nonatomic) dispatch_io_t channel;
@property (readwrite, nonatomic) dispatch_source_t readSource;
@end

#pragma mark -

@implementation STYSocket

- (instancetype)init
    {
    if ((self = [super init]) != NULL)
        {
        _connectTimeout = 10;
        }
    return self;
    }

- (instancetype)initWithAddress:(STYAddress *)inAddress
    {
    NSParameterAssert(inAddress != NULL);

    if ((self = [self init]) != NULL)
        {
        _address = [inAddress copy];
        }
    return self;
    }

- (instancetype)initWithCFSocket:(CFSocketRef)inSocket
    {
    NSParameterAssert(inSocket != NULL);

    NSData *theAddressData = (__bridge_transfer NSData *)CFSocketCopyAddress(inSocket);
    if (theAddressData == NULL)
        {
        return(NULL);
        }
    STYAddress *theAddress = [[STYAddress alloc] initWithAddresses:@[ theAddressData ]];

    if ((self = [self initWithAddress:theAddress]) != NULL)
        {
        _CFSocket = inSocket;
        _connected = YES;
        }
    return self;
    }

- (NSString *)description
    {
    return([NSString stringWithFormat:@"%@ (connected:%d, open:%d, address:%@, peerAddress:%@", [super description], self.connected, self.open, [self.address toString], [self.peerAddress toString]]);
    }

- (STYAddress *)peerAddress
    {
    if (self.connected == NO)
        {
        return(NULL);
        }

    NSParameterAssert(self.CFSocket != NULL);

    NSData *theAddressData = (__bridge_transfer NSData *)CFSocketCopyPeerAddress(self.CFSocket);
    if (theAddressData == NULL)
        {
        return(NULL);
        }
    STYAddress *theAddress = [[STYAddress alloc] initWithAddresses:@[ theAddressData ]];
    return(theAddress);
    }

- (void)open:(STYCompletionBlock)inCompletion
    {
    NSParameterAssert(self.open == NO);

    STYLogDebug_(@"Socket open");

    if (self.connected == NO)
        {
        [self _resolve:inCompletion];
        }
    else
        {
        [self _configure];
        if (inCompletion)
            {
            inCompletion(NULL);
            }
        }
    }

- (void)close:(STYCompletionBlock)inCompletion
    {
    if (self.open == NO)
        {
        return;
        }

    if ([self.delegate respondsToSelector:@selector(socketDidClose:)])
        {
        [self.delegate socketDidClose:self];
        }

    if (self.channel != NULL)
        {
        dispatch_io_close(self.channel, 0);
        self.channel = NULL;
        }
    if (self.readSource != NULL)
        {
        dispatch_source_cancel(self.readSource);
        self.readSource = NULL;
        }

    if (inCompletion)
        {
        inCompletion(NULL);
        }

    self.open = NO;
    }

- (void)_connect:(STYCompletionBlock)inCompletion
    {
    STYLogDebug_(@"Socket _connect");
    NSParameterAssert(self.connected == NO);
    NSParameterAssert(self.address.addresses != NULL);

    // Create the socket...
    CFSocketSignature theSocketSignature = {
        .protocolFamily = PF_INET, // IPV4 family
        .socketType = SOCK_STREAM, // Streaming type
        .protocol = IPPROTO_TCP, // TCP/IP protocol
        .address = (__bridge_retained CFDataRef)self.address.addresses[0], // TODO - why 0?
        };

    CFRunLoopRef theRunLoop = CFRunLoopGetCurrent();

    __weak typeof(self) weak_self = self;

    STYCompletionBlock theBlock = ^(NSError *inError) {
        __strong typeof(weak_self) strong_self = weak_self;
        if (strong_self != NULL)
            {
            CFRunLoopRemoveSource(theRunLoop, strong_self.runLoopSource, kCFRunLoopCommonModes);
            strong_self.runLoopSource = NULL;
            strong_self.connected = YES;
            if (inCompletion)
                {
                inCompletion(NULL);
                }
            }
        };

    CFSocketContext theSocketContext = {
        .info = (__bridge void *)[theBlock copy],
        .retain = CFRetain,
        .release = CFRelease,
        };
    self.CFSocket = CFSocketCreateConnectedToSocketSignature(kCFAllocatorDefault, &theSocketSignature, kCFSocketConnectCallBack, MyCFSocketCallBack, &theSocketContext, self.connectTimeout);

    if (self.CFSocket == NULL)
        {
        NSError *theUnderlyingError = [NSError errorWithDomain:NSPOSIXErrorDomain code:errno userInfo:NULL];
        NSError *theError = [NSError errorWithDomain:kSTYErrorDomain code:-1 userInfo:@{ NSLocalizedDescriptionKey: @"Could not create socket", NSUnderlyingErrorKey: theUnderlyingError }];
        STYLogError_(@"Could not create socket and connect it");
       
        inCompletion(theError);
        return;
        }

    CFRunLoopSourceRef theRunLoopSource = CFSocketCreateRunLoopSource(kCFAllocatorDefault, self.CFSocket, 0);
    CFRunLoopAddSource(theRunLoop, theRunLoopSource, kCFRunLoopCommonModes);
    self.runLoopSource = theRunLoopSource;
    CFRelease(theRunLoopSource);
    }
    
- (void)_resolve:(STYCompletionBlock)inCompletion
    {
    __weak typeof(self) weak_self = self;
    STYLogDebug_(@"Resolving: %@", self.address);
    [self.address resolveWithTimeout:60 handler:^(NSError *inError) {
        if (inError != NULL)
            {
            inCompletion(inError);
            return;
            }
            
        __strong typeof(weak_self) strong_self = weak_self;
        [strong_self _connect:^(NSError *inError) {
            if (inError != NULL)
                {
                inCompletion(inError);
                return;
                }
            if (inError == NULL)
                {
                [strong_self _configure];
                if (inCompletion)
                    {
                    inCompletion(NULL);
                    }
                }
            }];
        }];
    }

- (void)_configure
    {
    STYLogDebug_(@"%@ %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd));

    NSParameterAssert(self.connected == YES);
    NSParameterAssert(self.open == NO);
    NSParameterAssert(self.CFSocket != NULL);

    self.queue = dispatch_queue_create("io.schwa.STYSocket", DISPATCH_QUEUE_SERIAL);

    self.channel = dispatch_io_create(DISPATCH_IO_STREAM, CFSocketGetNative(self.CFSocket), dispatch_get_main_queue(), ^(int error) {
        // TODO: Clean up
        });
    dispatch_io_set_low_water(self.channel, 1);

    self.readSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_READ, CFSocketGetNative(self.CFSocket), 0, self.queue);
    dispatch_source_set_cancel_handler(self.readSource, ^{
        [self close:NULL];
        CFSocketInvalidate(self.CFSocket);

// TODO we're not communicating a close anywhere...
//        if ([self.delegate respondsToSelector:@selector(messagingPeerRemoteDidDisconnect:)])
//            {
//            [self.delegate messagingPeerRemoteDidDisconnect:self];
//            }
        });

    dispatch_source_set_event_handler(self.readSource, ^ {
        id <STYSocketDelegate> theDelegate = self.delegate;
        if ([theDelegate respondsToSelector:@selector(socketHasDataAvailable:)])
            {
            [theDelegate socketHasDataAvailable:self];
            }
        else
            {
            STYLogWarning_(@"Socket received event but no delegate set up to receive it.");
            }

        });

    dispatch_resume(self.readSource);

    self.open = YES;
    }


//static void MyCFHostClientCallBack(CFHostRef theHost, CFHostInfoType typeInfo, const CFStreamError *error, void *info)
//    {
//    STYClient *theClient = (__bridge STYClient *)info;
//
//    Boolean theResolvedFlag = NO;
//    NSArray *theAddresses = (__bridge NSArray *)CFHostGetAddressing(theClient.host, &theResolvedFlag);
//    STYLogDebug_(@"***** %@", theAddresses);
//    }

static void MyCFSocketCallBack(CFSocketRef s, CFSocketCallBackType type, CFDataRef address, const void *data, void *info)
    {
    STYLogDebug_(@"MyCFSocketCallBack: %d", type);
    if (type == kCFSocketConnectCallBack)
        {
        STYCompletionBlock theBlock = (__bridge STYCompletionBlock)info;
        theBlock(NULL);
        }
    }

@end
