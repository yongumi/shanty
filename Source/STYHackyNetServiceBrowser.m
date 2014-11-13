//
//  STYHackyNetServiceBrowser.m
//  shanty
//
//  Created by Jonathan Wight on 11/6/14.
//  Copyright (c) 2014 schwa.io. All rights reserved.
//

#import "STYHackyNetServiceBrowser.h"

#import "STYNetService.h"

@interface STYHackyNetServiceBrowser () <STYNetServiceBrowserDelegate>
@property (readwrite, nonatomic) STYNetServiceBrowser *localBrowser;
@property (readwrite, nonatomic) STYNetServiceBrowser *globalBrowser;
@property (readwrite, nonatomic) NSMutableDictionary *services;
@end

#pragma mark -

@implementation STYHackyNetServiceBrowser

- (id)init
    {
    if ((self = [super init]) != NULL)
        {
        _localBrowser = [[STYNetServiceBrowser alloc] init];
        _localBrowser.delegate = self;
        _localBrowser.localOnly = YES;
        
        _globalBrowser = [[STYNetServiceBrowser alloc] init];
        _globalBrowser.delegate = self;
        _globalBrowser.localOnly = NO;

        _services = [NSMutableDictionary dictionary];
        }
    return self;
    }

- (void)dealloc
    {
    [self stop];
    }

- (void)setQueue:(dispatch_queue_t)queue
    {
    super.queue = queue;

    _localBrowser.queue = super.queue;
    _globalBrowser.queue = super.queue;
    }

- (void)searchForServicesOfType:(NSString *)type inDomain:(NSString *)domainString
    {
    if ([self.delegate respondsToSelector:@selector(netServiceBrowserWillSearch:)])
        {
        [self.delegate netServiceBrowserWillSearch:self];
        }

    self.services = [NSMutableDictionary dictionary];

    [self.localBrowser searchForServicesOfType:type inDomain:domainString];
    [self.globalBrowser searchForServicesOfType:type inDomain:domainString];
    }
    
- (void)stop
    {
    [self.localBrowser stop];
    [self.globalBrowser stop];

    if ([self.delegate respondsToSelector:@selector(netServiceBrowserDidStopSearch:)])
        {
        [self.delegate netServiceBrowserDidStopSearch:self];
        }

    self.services = NULL;
    }

#pragma mark -

- (void)netServiceBrowser:(STYNetServiceBrowser *)aNetServiceBrowser didNotSearch:(NSError *)error
    {
    if ([self.delegate respondsToSelector:@selector(netServiceBrowser:didNotSearch:)])
        {
        [self.delegate netServiceBrowser:self didNotSearch:error];
        }
    
    if (aNetServiceBrowser == self.localBrowser)
        {
        [self.globalBrowser stop];
        }
    else
        {
        [self.localBrowser stop];
        }

    self.services = NULL;
    }
    
- (void)netServiceBrowser:(STYNetServiceBrowser *)aNetServiceBrowser didFindService:(STYNetService *)aNetService moreComing:(BOOL)moreComing
    {
    if ([self.delegate respondsToSelector:@selector(netServiceBrowser:didFindService:moreComing:)])
        {
        STYNetService *theFoundService = [self.services objectForKey:aNetService.key];
        if (theFoundService == NULL)
            {
            // TODO: moreComing could be a total lie.
            if ([self.delegate respondsToSelector:@selector(netServiceBrowser:didFindService:moreComing:)])
                {
                [self.delegate netServiceBrowser:self didFindService:aNetService moreComing:moreComing];
                }
            [self.services setObject:aNetService forKey:aNetService.key];
            }
        }
        
    [self.services setObject:aNetService forKey:aNetService.key];
    }
    
- (void)netServiceBrowser:(STYNetServiceBrowser *)aNetServiceBrowser didRemoveService:(STYNetService *)aNetService moreComing:(BOOL)moreComing
    {
    STYNetService *theFoundService = [self.services objectForKey:aNetService.key];
    if (theFoundService == NULL)
        {
        return;
        }

    if ([self.delegate respondsToSelector:@selector(netServiceBrowser:didRemoveService:moreComing:)])
        {
        // TODO: moreComing could be a total lie.
        [self.delegate netServiceBrowser:self didRemoveService:theFoundService moreComing:moreComing];
        }

    [self.services removeObjectForKey:theFoundService.key];
    }

@end
