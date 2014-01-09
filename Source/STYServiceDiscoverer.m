//
//  STYServiceDiscoverer.m
//  TwitterNT
//
//  Created by Jonathan Wight on 11/26/13.
//  Copyright (c) 2013 toxicsoftware. All rights reserved.
//

#import "STYServiceDiscoverer.h"

#import "STYAddress.h"
#import "STYSocket.h"

@interface STYServiceDiscoverer () <NSNetServiceBrowserDelegate, NSNetServiceDelegate>
@property (readwrite, nonatomic, strong) NSMutableSet *mutableServices;
@property (readwrite, nonatomic) NSNetServiceBrowser *serviceBrowser;
@property (readwrite, nonatomic, copy) void (^discoverFirstServiceAndStopHandler)(NSNetService *service, NSError *error);
@property (readwrite, nonatomic) BOOL running;
@end

#pragma mark -

@implementation STYServiceDiscoverer

- (instancetype)initWithType:(NSString *)inType domain:(NSString *)inDomain
    {
    NSParameterAssert(inType.length > 0);

    if ((self = [super init]) != NULL)
        {
        _type = inType;
        _domain = inDomain ?: @"";
        }
    return self;
    }

- (void)dealloc
    {
    [self stop];
    }

- (void)start
    {
    if (self.running == NO)
        {
        self.mutableServices = [NSMutableSet set];

        self.serviceBrowser = [[NSNetServiceBrowser alloc] init];
        self.serviceBrowser.delegate = self;
        [self.serviceBrowser searchForServicesOfType:self.type inDomain:self.domain];

        self.running = YES;
        }
    }

- (void)stop
    {
    if (self.running == YES)
        {
        [self.serviceBrowser stop];
        self.serviceBrowser.delegate = NULL;
        self.serviceBrowser = NULL;

        self.running = NO;
        }
    }

- (void)discoverFirstServiceAndStop:(void (^)(NSNetService *service, NSError *error))inHandler
    {
    NSParameterAssert(self.running == NO);

    self.discoverFirstServiceAndStopHandler = inHandler;
    [self start];
    }

- (NSSet *)services
    {
    return(self.mutableServices);
    }

#pragma mark -

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindService:(NSNetService *)aNetService moreComing:(BOOL)moreComing
    {
    if (self.running == NO)
        {
        return;
        }

    if (self.serviceAcceptanceHandler)
        {
        if (self.serviceAcceptanceHandler(aNetService) == NO)
            {
            return;
            }
        }

    if (self.discoverFirstServiceAndStopHandler != NULL)
        {
        self.discoverFirstServiceAndStopHandler(aNetService, NULL);
        [self stop];
        }

    [self willChangeValueForKey:@"services"];
    [self.mutableServices addObject:aNetService];
    [self didChangeValueForKey:@"services"];
    }

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didRemoveService:(NSNetService *)aNetService moreComing:(BOOL)moreComing;
    {
    if (self.running == NO)
        {
        return;
        }

    [self willChangeValueForKey:@"services"];
    [self.mutableServices removeObject:aNetService];
    [self didChangeValueForKey:@"services"];
    }

@end
