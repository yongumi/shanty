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
@property (readonly, nonatomic, strong) NSMutableSet *mutableServices;
@property (readwrite, nonatomic) NSNetServiceBrowser *serviceBrowser;
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
        _mutableServices = [NSMutableSet set];
        }
    return self;
    }

- (id)init
    {
    // TODO - guess type from CFBundleID

    if ((self = [self initWithType:@"_schwatest._tcp." domain:NULL]) != NULL)
        {
        }
    return self;
    }

- (void)start;
    {
    self.serviceBrowser = [[NSNetServiceBrowser alloc] init];
    self.serviceBrowser.delegate = self;
    [self.serviceBrowser searchForServicesOfType:self.type inDomain:self.domain];
    }

- (NSSet *)services
    {
    return(self.mutableServices);
    }

#pragma mark -

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindService:(NSNetService *)aNetService moreComing:(BOOL)moreComing
    {
    if (self.serviceAcceptanceHandler)
        {
        if (self.serviceAcceptanceHandler(aNetService) == NO)
            {
            return;
            }
        }

    [self willChangeValueForKey:@"services"];
    [self.mutableServices addObject:aNetService];
    [self didChangeValueForKey:@"services"];
    }

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didRemoveService:(NSNetService *)aNetService moreComing:(BOOL)moreComing;
    {
    [self willChangeValueForKey:@"services"];
    [self.mutableServices removeObject:aNetService];
    [self didChangeValueForKey:@"services"];
    }

@end
