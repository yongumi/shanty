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

static void MyCFHostClientCallBack(CFHostRef theHost, CFHostInfoType typeInfo, const CFStreamError *error, void *info);
static void MyCFSocketCallBack(CFSocketRef s, CFSocketCallBackType type, CFDataRef address, const void *data, void *info);

@interface STYClient ()
@property (readwrite, nonatomic, strong) __attribute__((NSObject)) CFHostRef host;
@property (readwrite, nonatomic, strong) NSData *address;
@property (readwrite, nonatomic, strong) __attribute__((NSObject)) CFSocketRef socket;
@property (readwrite, nonatomic, strong) __attribute__((NSObject)) CFRunLoopSourceRef runLoopSource;
@end

#pragma mark -

@implementation STYClient

- (instancetype)initWithHostname:(NSString *)inHostname port:(unsigned short)inPort
    {
    if ((self = [super init]) != NULL)
        {
        _hostname = inHostname;
        _port = inPort;
        [self address];
        }
    return self;
    }

- (void)connect:(STYCompletionBlock)inCompletionBlock;
    {
    if (self.hostname.length == 0)
        {
        [self _connect:inCompletionBlock];
        }
    else
        {
        [self _resolve:^(NSError *error) {
            [self _connect:inCompletionBlock];
            }];
        }
    }

- (NSData *)address
    {
    if (_address == NULL)
        {
        // Create an IPV4 address...
        struct sockaddr_in theAddress = {
            .sin_len = sizeof(theAddress),
            .sin_family = AF_INET, // IPV4 style address
            .sin_port = htons(self.port),
            .sin_addr = htonl(INADDR_ANY),
            };
        _address = [NSData dataWithBytes:&theAddress length:sizeof(theAddress)];
        NSLog(@"%@", _address);
        }
    return(_address);
    }

- (void)_resolve:(STYCompletionBlock)inCompletionBlock;
    {
    CFHostRef theHost = CFHostCreateWithName(kCFAllocatorDefault, (__bridge CFStringRef)self.hostname);

//    CFHostClientContext theHostClientContext = {
//        .info = (__bridge void *)self,
//        };
//    CFHostSetClient(theHost, &MyCFHostClientCallBack, &theHostClientContext);

    CFStreamError theStreamError;
    /*BOOL theResult = */CFHostStartInfoResolution(theHost, kCFHostAddresses, &theStreamError);
//    NSLog(@"***** %d %d %ld", theResult, theStreamError.error, theStreamError.domain);

//    CFHostScheduleWithRunLoop(theHost, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
//    self.host = theHost;

    if (1)
        {
        Boolean theResolvedFlag = NO;
        NSArray *theAddresses = (__bridge NSArray *)CFHostGetAddressing(theHost, &theResolvedFlag);
//        NSLog(@"***** %@", theAddresses);

        self.address = theAddresses[0];

        // Create an IPV4 address...
        struct sockaddr_in theAddress;
        memcpy(&theAddress, self.address.bytes, sizeof(theAddresses));
        theAddress.sin_port = htons(self.port);

        self.address = [NSData dataWithBytes:&theAddress length:sizeof(theAddress)];
//        NSLog(@"%@", _address);



        inCompletionBlock(NULL);
        }


    CFRelease(theHost);
    }

- (void)_connect:(STYCompletionBlock)inCompletionBlock;
    {

    // Create the socket...
    CFSocketSignature theSocketSignature = {
        .protocolFamily = PF_INET, // IPV4 family
        .socketType = SOCK_STREAM, // Streaming type
        .protocol = IPPROTO_TCP, // TCP/IP protocol
        .address = (__bridge_retained CFDataRef)self.address,
        };

    NSLog(@"%@ %lu/%lu %d", self.address, (unsigned long)self.address.length, sizeof(struct sockaddr_in), self.port);

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

@end

#pragma mark -

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
