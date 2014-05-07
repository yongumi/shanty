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
#import "STYMessagingPeer.h"
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

- (NSNetService *)discoverFirstService:(NSTimeInterval)inTimeout error:(NSError *__autoreleasing *)outError
    {
    __block NSNetService *theNetService = NULL;
    __block NSError *theError = NULL;
    __block BOOL theFlag = YES;
    [self discoverFirstServiceAndStop:^(NSNetService *service, NSError *error) {
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

#pragma mark -

- (void)connectToService:(NSNetService *)inNetService openPeer:(BOOL)inOpenPeer completion:(void (^)(STYMessagingPeer *peer, NSError *error))handler
    {
    NSParameterAssert(inNetService);
    NSParameterAssert(handler);

    STYAddress *theAddress = [[STYAddress alloc] initWithNetService:inNetService];
    STYSocket *theSocket = [[STYSocket alloc] initWithAddress:theAddress];
    STYMessagingPeer *thePeer = [[STYMessagingPeer alloc] initWithMode:kSTYMessengerModeClient socket:theSocket name:inNetService.name];
    if (inOpenPeer == YES)
        {
        [thePeer open:^(NSError *error) {
            if (error == NULL)
                {
                handler(thePeer, NULL);
                }
            else
                {
                handler(NULL, error);
                }
            }];
        }
    else
        {
        handler(thePeer, NULL);
        }
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
