//
//  STYServiceDiscoverer.m
//  TwitterNT
//
//  Created by Jonathan Wight on 11/26/13.
//  Copyright (c) 2013 toxicsoftware. All rights reserved.
//

#import "STYServiceDiscoverer.h"

#import "STYClient.h"

@interface STYServiceDiscoverer () <NSNetServiceBrowserDelegate, NSNetServiceDelegate>
@property (readwrite, nonatomic) NSNetServiceBrowser *serviceBrowser;
@property (readwrite, nonatomic) NSNetService *service;
@property (readwrite, nonatomic, strong) void (^clientBlock)(STYClient *client, NSError *error);
@end

#pragma mark -

@implementation STYServiceDiscoverer

- (instancetype)initWithType:(NSString *)inType domain:(NSString *)inDomain
    {
    if ((self = [super init]) != NULL)
        {
        _type = inType;
        _domain = inDomain;
        }
    return self;
    }

- (id)init
    {
    // TODO - guess type from CFBundleID

    if ((self = [self initWithType:@"_schwatest._tcp." domain:@""]) != NULL)
        {
        }
    return self;
    }


- (void)start:(void (^)(STYClient *client, NSError *error))inHandler
    {
    NSParameterAssert(inHandler != NULL);

    self.clientBlock = inHandler;

    self.serviceBrowser = [[NSNetServiceBrowser alloc] init];
    self.serviceBrowser.delegate = self;
    [self.serviceBrowser searchForServicesOfType:self.type inDomain:self.domain];
    }

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindService:(NSNetService *)aNetService moreComing:(BOOL)moreComing
    {
    if (self.service)
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

    self.service.delegate = NULL;
    [self.service stop];
    self.service = NULL;

    self.service = aNetService;
    self.service.delegate = self;
    [self.service resolveWithTimeout:60.0];
    }

- (void)netServiceDidResolveAddress:(NSNetService *)sender
    {
    NSLog(@"RESOLVE: %@ %ld", sender.hostName, (long)sender.port);

    self.service.delegate = NULL;
    [self.service stop];
    self.service = NULL;

    STYClient *theClient = [[STYClient alloc] initWithNetService:sender];
    self.clientBlock(theClient, NULL);
    }


@end
