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
#include <arpa/inet.h>

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

- (void)dealloc
	{
    [self close:nil];
    
    self.CFSocket = nil;
    self.runLoopSource = nil;
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
        dispatch_io_close(self.channel, DISPATCH_IO_STOP);
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

- (void)read:(dispatch_io_handler_t)inHandler
    {
    NSParameterAssert(inHandler != NULL);
    dispatch_io_read(self.channel, 0, SIZE_MAX, self.queue, inHandler);
    }

- (void)write:(dispatch_data_t)inData completion:(STYCompletionBlock)inCompletion
    {
    NSParameterAssert(inCompletion != NULL);
    dispatch_io_write(self.channel, 0, inData, self.queue, ^(bool done, dispatch_data_t data, int error) {
        if (inCompletion)
        {
            inCompletion(NULL);
        }
        });
    }

#pragma mark -

- (void)_connect:(STYCompletionBlock)inCompletion
    {
    STYLogDebug_(@"Socket _connect");
    NSParameterAssert(self.connected == NO);
    NSParameterAssert(self.address.addresses != NULL);

    CFSocketSignature theSocketSignature = (CFSocketSignature){
        .socketType = SOCK_STREAM, // Streaming type
        .protocol = IPPROTO_TCP, // TCP/IP protocol
    };

    STYLogDebug_(@"Picking best address out of %@", self.address);

// TODO: Attempt to open IPV6 socket. Unfortunately no idea why this doesn't work with CFSocketCreateConnectedToSocketSignature
//    if (self.address.IPV6Addresses.count > 0 && NO)
//        {
//        theSocketSignature.protocolFamily = AF_INET6; // IPV6 family
//        NSData *theAddress = self.address.IPV6Addresses.firstObject;
//        theSocketSignature.address = (__bridge_retained CFDataRef)theAddress;
//        }
//    else
        {
        theSocketSignature.protocolFamily = AF_INET; // IPV4 family
        NSData *theAddress = self.address.IPV4Addresses.firstObject;
        STYLogDebug_(@"Using %@:%d (%@) to connect.", [STYAddress descriptionForAddress:theAddress], [STYAddress portForAddress:theAddress], theAddress);
        theSocketSignature.address = (__bridge_retained CFDataRef)theAddress;
        }

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
    CFSocketRef theSocket = CFSocketCreateConnectedToSocketSignature(kCFAllocatorDefault, &theSocketSignature, kCFSocketConnectCallBack, MyCFSocketCallBack, &theSocketContext, self.connectTimeout);
    if (theSocket == NULL)
        {
        NSError *theError = _CreateErrorWithErrno(kSTYErrorCode_Unknown, @"Could not create socket");
        inCompletion(theError);
        return;
        }
    self.CFSocket = theSocket;
    CFRelease(theSocket);

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
    
    // TODO: Low water mark of 1 might be silly
    dispatch_io_set_low_water(self.channel, 1);

    __weak typeof (self) weakSelf = self;
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
            [theDelegate socketHasDataAvailable:weakSelf];
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
    if (type == kCFSocketConnectCallBack)
        {
        STYCompletionBlock theBlock = (__bridge STYCompletionBlock)info;
        theBlock(NULL);
        }
    else
        {
        STYLogWarning_(@"Unhandled MyCFSocketCallBack: %d", type);
        }
    }

static NSError *_CreateErrorWithErrno(NSUInteger code, NSString *inDescription)
    {
    NSError *theUnderlyingError = [NSError errorWithDomain:NSPOSIXErrorDomain code:errno userInfo:NULL];
    NSError *theError = [NSError errorWithDomain:kSTYErrorDomain code:code userInfo:@{ NSLocalizedDescriptionKey:inDescription, NSUnderlyingErrorKey: theUnderlyingError }];
    STYLogError_(@"%@: %@", inDescription, theUnderlyingError);
    return theError;
    }

@end
