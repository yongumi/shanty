//
//  STYServiceDiscoverer.m
//  Shanty
//
//  Created by Jonathan Wight on 11/26/13.
//  Copyright (c) 2013 toxicsoftware. All rights reserved.
//

#import "STYServiceDiscoverer.h"

#import "STYAddress.h"
#import "STYSocket.h"
#import "STYSocket.h"
#import "STYLogger.h"
#import "STYNetService.h"
#import "STYNetServiceBrowser.h"

@interface STYServiceDiscoverer () <STYNetServiceBrowserDelegate>
@property (readwrite, nonatomic, strong) NSMutableSet *mutableServices;
@property (readwrite, nonatomic) STYNetServiceBrowser *serviceBrowser;
@property (readwrite, nonatomic, copy) void (^discoverFirstServiceAndStopHandler)(STYNetService *service, NSError *error);
@property (readwrite, nonatomic) BOOL started;
@end

#pragma mark -

@implementation STYServiceDiscoverer

- (instancetype)initWithType:(NSString *)inType domain:(NSString *)inDomain
    {
    NSParameterAssert(inType.length > 0);

    if ((self = [super init]) != NULL)
        {
        _type = [inType copy];
        _domain = [inDomain copy] ?: @"";
        }
    return self;
    }

- (instancetype)initWithType:(NSString *)inType
    {
    return [self initWithType:inType domain:NULL];
    }

- (void)dealloc
    {
    [self stop];
    }

- (void)start
    {
    if (self.started == NO)
        {
        self.mutableServices = [NSMutableSet set];

        self.serviceBrowser = [[STYNetServiceBrowser alloc] init];
//        self.serviceBrowser.localOnly = YES;
        self.serviceBrowser.delegate = self;
        [self.serviceBrowser searchForServicesOfType:self.type inDomain:self.domain];

        self.started = YES;
        }
    }

- (void)stop
    {
    if (self.started == YES)
        {
        [self.serviceBrowser stop];
        self.serviceBrowser.delegate = NULL;
        self.serviceBrowser = NULL;

        self.started = NO;
        }
    }

- (void)discoverFirstServiceAndStop:(void (^)(STYNetService *service, NSError *error))inHandler
    {
    NSParameterAssert(self.started == NO);

    self.discoverFirstServiceAndStopHandler = inHandler;
    [self start];
    }

- (NSSet *)services
    {
    return(self.mutableServices);
    }

#pragma mark -

- (void)netServiceBrowser:(STYNetServiceBrowser *)aNetServiceBrowser didFindService:(STYNetService *)aNetService moreComing:(BOOL)moreComing
    {
    if (self.started == NO)
        {
        return;
        }

    if ([aNetService.domain rangeOfString:@"members.btmm.icloud.com."].location != NSNotFound)
        {
        // TODO: For now as a work-around to prevent duplicate services. Back to My Mac is IPv6 only and right now shanty is IPv4 only (due to laziness)
        return;
        }

    if (self.discoverFirstServiceAndStopHandler != NULL)
        {
        self.discoverFirstServiceAndStopHandler(aNetService, NULL);
        [self stop];
        }

    NSParameterAssert([NSThread isMainThread]);
    [self willChangeValueForKey:@"services"];
    [self.mutableServices addObject:aNetService];
    [self didChangeValueForKey:@"services"];
    }
   
- (STYNetService *)discoverFirstService:(NSTimeInterval)inTimeout error:(NSError *__autoreleasing *)outError
    {
    __block STYNetService *theNetService = NULL;
    __block NSError *theError = NULL;
    __block BOOL theFlag = YES;
    [self discoverFirstServiceAndStop:^(STYNetService *service, NSError *error) {
        theNetService = service;
        theError = error;
        theFlag = NO;
        }];

    NSDate *theStartDate = [NSDate date];

    while (theFlag == YES)
        {
        if (inTimeout > 0.0 && [[NSDate date] timeIntervalSinceDate:theStartDate] >= inTimeout)
            {
            break;
            }
        [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];
        }

    if (outError != NULL)
        {
        *outError = theError;
        }
    return theNetService;
    }
   
- (void)netServiceBrowser:(STYNetServiceBrowser *)aNetServiceBrowser didRemoveService:(STYNetService *)aNetService moreComing:(BOOL)moreComing;
    {
    if (self.started == NO)
        {
        return;
        }

    NSParameterAssert([NSThread isMainThread]);
    [self willChangeValueForKey:@"services"];
    [self.mutableServices removeObject:aNetService];
    [self didChangeValueForKey:@"services"];
    }

@end
