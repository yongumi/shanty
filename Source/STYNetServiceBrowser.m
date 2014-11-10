//
//  STYNetServiceBrowser.m
//  shanty
//
//  Created by Jonathan Wight on 11/6/14.
//  Copyright (c) 2014 schwa.io. All rights reserved.
//

#import "STYNetServiceBrowser.h"

#include <dns_sd.h>

#import "STYNetService.h"
#import "STYConstants.h"

@interface STYNetServiceBrowser ()
@property (readwrite, nonatomic, assign) DNSServiceRef service;
@property (readwrite, nonatomic, strong) NSMutableDictionary *services;
@end

#pragma mark -

@implementation STYNetServiceBrowser

- (id)init
    {
    if ((self = [super init]) != NULL)
        {
        _queue = dispatch_get_main_queue();
        }
    return self;
    }

- (void)dealloc
    {
    [self stop];
    }

- (void)searchForServicesOfType:(NSString *)type inDomain:(NSString *)domainString
    {
    if ([self.delegate respondsToSelector:@selector(netServiceBrowserWillSearch:)])
        {
        [self.delegate netServiceBrowserWillSearch:self];
        }
    
    uint32_t theInterfaceIndex = kDNSServiceInterfaceIndexAny;

    if (self.localOnly == YES)
        {
        theInterfaceIndex = kDNSServiceInterfaceIndexLocalOnly;
        }

    self.services = [NSMutableDictionary dictionary];

    DNSServiceErrorType theResult = DNSServiceBrowse(&_service, 0, theInterfaceIndex, type.UTF8String, domainString.UTF8String, MyDNSServiceBrowseReply, (__bridge void *)self);
    if (theResult == kDNSServiceErr_NoError)
        {
        theResult = DNSServiceSetDispatchQueue(_service, self.queue);
        if (theResult == kDNSServiceErr_NoError)
            {
            return;
            }
        // TODO: Error handling
        }

    if ([self.delegate respondsToSelector:@selector(netServiceBrowser:didNotSearch:)])
        {
        NSError *theError = [NSError errorWithDomain:kSTYErrorDomain code:kSTYErrorCode_Unknown userInfo:@{ @"DNSSD_ResultCode": @(theResult) }];
        [self.delegate netServiceBrowser:self didNotSearch:theError];
        }
    }

- (void)stop
    {
    if (_service != NULL)
        {
        DNSServiceRefDeallocate(_service);
        _service = NULL;
        }

    _services = NULL;

    if ([self.delegate respondsToSelector:@selector(netServiceBrowserDidStopSearch:)])
        {
        [self.delegate netServiceBrowserDidStopSearch:self];
        }
    }
    
#pragma mark -

static void MyDNSServiceBrowseReply(DNSServiceRef sdRef, DNSServiceFlags flags, uint32_t interfaceIndex, DNSServiceErrorType errorCode, const char *serviceName, const char *regtype, const char *replyDomain, void *context)
    {
//    NSLog(@"MyDNSServiceBrowseReply flags:%d idx:%d err:%d serviceName:%s regtype:%s replyDomain:%s", flags, interfaceIndex, errorCode, serviceName, regtype, replyDomain);

    if (errorCode == kDNSServiceErr_NoError)
        {
        if (flags & kDNSServiceFlagsAdd)
            {
            STYNetServiceBrowser *self = (__bridge STYNetServiceBrowser *)context;
            STYNetService *theService = [[STYNetService alloc] initWithDomain:[NSString stringWithUTF8String:replyDomain] type:[NSString stringWithUTF8String:regtype] name:[NSString stringWithUTF8String:serviceName]];
            NSString *theKey = [@[theService.domain, theService.type, theService.name] componentsJoinedByString:@"|"];
            if ([self.services objectForKey:theKey] != NULL)
                {
                return;
                }
            theService.queue = self.queue;
            [self.services setObject:theService forKey:theKey];
            if ([self.delegate respondsToSelector:@selector(netServiceBrowser:didFindService:moreComing:)])
                {
                [self.delegate netServiceBrowser:self didFindService:theService moreComing:kDNSServiceFlagsMoreComing ? YES : NO];
                }
            }
        else if (!(flags & kDNSServiceFlagsAdd))
            {
            STYNetServiceBrowser *self = (__bridge STYNetServiceBrowser *)context;
            STYNetService *theService = [[STYNetService alloc] initWithDomain:[NSString stringWithUTF8String:replyDomain] type:[NSString stringWithUTF8String:regtype] name:[NSString stringWithUTF8String:serviceName]];
            NSString *theKey = [@[theService.domain, theService.type, theService.name] componentsJoinedByString:@"|"];
            [self.services removeObjectForKey:theKey];
            [self.delegate netServiceBrowser:self didRemoveService:theService moreComing:kDNSServiceFlagsMoreComing ? YES : NO];
            }
        }
    }

@end

