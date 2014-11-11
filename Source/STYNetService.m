//
//  STYNetService.m
//  STYNetBrowser
//
//  Created by Jonathan Wight on 11/4/14.
//  Copyright (c) 2014 schwa.io. All rights reserved.
//

#import "STYNetService.h"

#include <dns_sd.h>

#import "STYResolver.h"
#import "STYLogger.h"
#import "STYConstants.h"

@interface STYNetService ()
@property (readwrite, nonatomic, copy) NSString *domain;
@property (readwrite, nonatomic, copy) NSString *type;
@property (readwrite, nonatomic, copy) NSString *name;
@property (readwrite, nonatomic, copy) NSString *hostName;
@property (readwrite, nonatomic, copy) NSArray *addresses;
@property (readwrite, nonatomic) NSInteger port;
@property (readwrite, nonatomic, copy) NSData *TXTRecordData;
@property (readwrite, nonatomic, strong) id userInfo;

@property (readwrite, nonatomic, assign) DNSServiceRef service;
@end

#pragma mark -

@implementation STYNetService

static NSMutableDictionary *gResolvingDomains = NULL;

static id gSharedInstance = NULL;

+ (NSMutableDictionary *)resolvingDomains
    {
    static dispatch_once_t sOnceToken = 0;
    dispatch_once(&sOnceToken, ^{
        gResolvingDomains = [NSMutableDictionary dictionary];
        });
    return gResolvingDomains;
    }

- (NSString *)key
    {
    NSString *key = [@[self.domain, self.type, self.name] componentsJoinedByString:@"|"];
    return key;
    }

- (instancetype)initWithDomain:(NSString *)domain type:(NSString *)type name:(NSString *)name port:(NSInteger)port
    {
    if ((self = [self init]) != NULL)
        {
        _domain = [domain copy];
        _type = [type copy];
        _name = [name copy];
        _port = port;
        }
    return self;
    }

- (instancetype)initWithDomain:(NSString *)domain type:(NSString *)type name:(NSString *)name
    {
    return [self initWithDomain:domain type:type name:name port:0];
    }

- (NSString *)description
    {
    return([NSString stringWithFormat:@"%@ (domain:%@, type:%@, name:%@, hostName:%@, addresses:%@, port:%ld", [super description], self.domain, self.type, self.name, self.hostName, self.addresses, (long)self.port]);
    }

- (void)resolve
    {
    if ([self.delegate respondsToSelector:@selector(netServiceWillResolve:)])
        {
        [self.delegate netServiceWillResolve:self];
        }

    [[STYNetService resolvingDomains] setObject:self forKey:self.key];

    // TODO: Retain self across lifetime of callback
    DNSServiceErrorType theResult = DNSServiceResolve(&_service, 0, 0, self.name.UTF8String, self.type.UTF8String, self.domain.UTF8String, MyDNSServiceResolveReply, (__bridge void *)self);
    if (theResult == kDNSServiceErr_NoError)
        {
        theResult = DNSServiceSetDispatchQueue(_service, self.queue);
        if (theResult == kDNSServiceErr_NoError)
            {
            return;
            }
        }

    if ([self.delegate respondsToSelector:@selector(netService:didNotResolve:)])
        {
        NSError *theError = [NSError errorWithDomain:kSTYErrorDomain code:kSTYErrorCode_Unknown userInfo:@{ @"DNSSD_ResultCode": @(theResult) }];
        [self.delegate netService:self didNotResolve:theError];
        }
    }

- (void)stop
    {
    if (_service != NULL)
        {
        DNSServiceRefDeallocate(_service);
        _service = NULL;
        }

    [[STYNetService resolvingDomains] removeObjectForKey:self.key];

    if ([self.delegate respondsToSelector:@selector(netServiceDidStop:)])
        {
        [self.delegate netServiceDidStop:self];
        }
    }
    
- (void)publish:(BOOL)inLocalhostOnly
    {
    if ([self.delegate respondsToSelector:@selector(netServiceWillPublish:)])
        {
        [self.delegate netServiceWillPublish:self];
        }

    DNSServiceFlags theFlags = 0;
    u_int32_t theInterfaceIndex = inLocalhostOnly ? kDNSServiceInterfaceIndexLocalOnly : kDNSServiceInterfaceIndexAny;
    const char *theName = self.name.UTF8String;
    const char *theRegType = self.type.UTF8String;
    const char *theDomain = self.domain.length > 0 ? self.domain.UTF8String : NULL;
    const char *theHost = "localhost";
    unsigned short thePort = htons(self.port);

    NSData *theTXTRecordData = [[NSNetService dataFromTXTRecordDictionary:@{}] bytes];
    size_t theTXTRecordSize = theTXTRecordData.length;
    const char *theTXTRecord = theTXTRecordData.bytes;

    NSParameterAssert(_service == NULL);
    
    DNSServiceErrorType theResult = DNSServiceRegister(&_service, theFlags, theInterfaceIndex, theName, theRegType, theDomain, theHost, thePort, theTXTRecordSize, theTXTRecord, MyDNSServiceRegisterReply, (__bridge void *)self);
    if (theResult == kDNSServiceErr_NoError)
        {
        theResult = DNSServiceSetDispatchQueue(self.service, self.queue);
        if (theResult == kDNSServiceErr_NoError)
            {
            return;
            }
        }
    
    NSError *theError = [NSError errorWithDomain:kSTYErrorDomain code:kSTYErrorCode_Unknown userInfo:@{ @"DNSSD_ResultCode": @(theResult) }];
    if ([self.delegate respondsToSelector:@selector(netService:didNotPublish:)])
        {
        [self.delegate netService:self didNotPublish:theError];
        }

    }

static void MyDNSServiceRegisterReply(DNSServiceRef sdRef, DNSServiceFlags flags, DNSServiceErrorType errorCode, const char *name, const char *regtype, const char *domain, void *context)
    {
    if (errorCode != 0)
        {
        STYLogError_(@"MyDNSServiceRegisterReply: %d %d %s %s %s", flags, errorCode, name, regtype, domain);
        }
    }

static void MyDNSServiceResolveReply(DNSServiceRef sdRef, DNSServiceFlags flags, uint32_t interfaceIndex, DNSServiceErrorType errorCode, const char *fullname, const char *hosttarget, uint16_t port, uint16_t txtLen, const unsigned char *txtRecord, void *context)
    {
//    NSLog(@"MyDNSServiceResolveReply flags:%d idx:%d err:%d fullname:%s hosttarget:%s port:%d", flags, interfaceIndex, errorCode, fullname, hosttarget, port);
    if (errorCode == kDNSServiceErr_NoError)
        {
        STYNetService *self = (__bridge STYNetService *)context;

        if ([[STYNetService resolvingDomains] objectForKey:self.key] == NULL)
            {
            return;
            }

        self.port = htons(port);
        self.hostName = [NSString stringWithUTF8String:hosttarget];
        self.TXTRecordData = [NSData dataWithBytes:txtRecord length:txtLen];

        STYResolver *theResolver = [[STYResolver alloc] init];
        theResolver.queue = self.queue;
        [theResolver resolveName:self.hostName service:[NSString stringWithFormat:@"%ld", (long)self.port] handler:^(NSArray *addresses, NSError *error) {
            self.addresses = addresses;
            if ([self.delegate respondsToSelector:@selector(netServiceDidResolveAddress:)])
                {
                [self.delegate netServiceDidResolveAddress:self];
                }
            }];
        [[STYNetService resolvingDomains] removeObjectForKey:self.key];
        }
    }

@end

#pragma mark -

