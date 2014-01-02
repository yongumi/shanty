//
//  STYClient.m
//  Shanty
//
//  Created by Jonathan Wight on 11/4/13.
//  Copyright (c) 2013 schwa.io. All rights reserved.
//

#import "STYClient.h"

#include <sys/socket.h>
#include <netinet/in.h>

#import "STYAddress.h"

@interface STYClient ()
@property (readwrite, nonatomic, copy) STYAddress *address;
@property (readwrite, nonatomic, strong) __attribute__((NSObject)) CFSocketRef socket;
@property (readwrite, nonatomic, strong) __attribute__((NSObject)) CFRunLoopSourceRef runLoopSource;
@end

#pragma mark -

@implementation STYClient

// TODO decide on the designated initializer.

- (instancetype)initWithAddress:(STYAddress *)inAddress;
    {
    if ((self = [super init]) != NULL)
        {
        _address = inAddress;
        }
    return(self);
    }

- (instancetype)initWithHostname:(NSString *)inHostname port:(unsigned short)inPort
    {
    STYAddress *theAddress = [[STYAddress alloc] initWithHostname:inHostname port:inPort];
    if ((self = [self initWithAddress:theAddress]) != NULL)
        {
        }
    return self;
    }

- (void)connect:(STYCompletionBlock)inCompletionBlock
    {
    [self.address resolveWithTimeout:60 handler:^(NSError *inError) {
        if (inError == NULL)
            {
            [self _connect:inCompletionBlock];
            }
        }];
    }

- (void)_connect:(STYCompletionBlock)inCompletionBlock;
    {
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

            if (inCompletionBlock)
                {
                inCompletionBlock(inError);
                }
            }
        };

    CFSocketContext theSocketContext = {
        .info = (__bridge void *)[theBlock copy],
        .retain = CFRetain,
        .release = CFRelease,
        };
    self.socket = CFSocketCreateConnectedToSocketSignature(kCFAllocatorDefault, &theSocketSignature, kCFSocketConnectCallBack, MyCFSocketCallBack, &theSocketContext, -1);

    if (self.socket == NULL)
        {
        NSLog(@"COULD NOT CREATE SOCKET: %d", errno);
        return;
        }

    CFRunLoopSourceRef theRunLoopSource = CFSocketCreateRunLoopSource(kCFAllocatorDefault, self.socket, 0);
    CFRunLoopAddSource(theRunLoop, theRunLoopSource, kCFRunLoopCommonModes);
    self.runLoopSource = theRunLoopSource;
    CFRelease(theRunLoopSource);
    }

//static void MyCFHostClientCallBack(CFHostRef theHost, CFHostInfoType typeInfo, const CFStreamError *error, void *info)
//    {
//    STYClient *theClient = (__bridge STYClient *)info;
//
//    Boolean theResolvedFlag = NO;
//    NSArray *theAddresses = (__bridge NSArray *)CFHostGetAddressing(theClient.host, &theResolvedFlag);
//    NSLog(@"***** %@", theAddresses);
//    }

static void MyCFSocketCallBack(CFSocketRef s, CFSocketCallBackType type, CFDataRef address, const void *data, void *info)
    {
    if (type == kCFSocketConnectCallBack)
        {
        STYCompletionBlock theBlock = (__bridge STYCompletionBlock)info;
        theBlock(NULL);
        }
    }

@end
