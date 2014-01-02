//
//  STYAddress.m
//  Shanty Examples
//
//  Created by Jonathan Wight on 12/11/13.
//  Copyright (c) 2013 schwa.io. All rights reserved.
//

#import "STYAddress.h"

#include <netinet/in.h>

// TODO - hey what about that IPV6?

@interface STYAddress () <NSNetServiceDelegate>
@property (readwrite, nonatomic, copy) NSArray *addresses;
@property (readwrite, nonatomic, copy) NSString *hostname;
@property (readwrite, nonatomic, assign) unsigned short port;
@property (readwrite, nonatomic, strong) NSNetService *netService;
@property (readwrite, nonatomic, copy) void (^resolveHandler)(NSError *);
@end

#pragma mark -

@implementation STYAddress

- (instancetype)initWithAddresses:(NSArray *)inAddresses
    {
    if ((self = [super init]) != NULL)
        {
        _addresses = inAddresses;
        }
    return self;
    }

- (instancetype)initWithHostname:(NSString *)inHostname port:(unsigned int)inPort
    {
    if ((self = [self initWithAddresses:NULL]) != NULL)
        {
        _hostname = inHostname;
        _port = inPort;
        }
    return self;
    }

- (instancetype)initWithNetService:(NSNetService *)inNetService;
    {
    if ((self = [self initWithAddresses:NULL]) != NULL)
        {
        _netService = inNetService;
        }
    return self;
    }

- (id)copyWithZone:(NSZone *)zone;
    {
    return(self);
    }

- (NSString *)description
    {
    NSMutableArray *theDescriptions = [NSMutableArray array];

    if (self.hostname != NULL)
        {
        [theDescriptions addObject:[NSString stringWithFormat:@"%@:%d", self.hostname, self.port]];
        }
    else if (self.netService)
        {
        [theDescriptions addObject:[NSString stringWithFormat:@"%@", [self.netService description]]];
        }


    for (NSData *theAddress in self.addresses)
        {
        NSDictionary *theParts = DictionaryFromAddress(theAddress);
        [theDescriptions addObject:[NSString stringWithFormat:@"%@:%@", theParts[@"sin_addr"], theParts[@"sin_port"]]];
        }
    return([NSString stringWithFormat:@"%@ (%@)", [super description], [theDescriptions componentsJoinedByString:@", "]]);
    }

- (void)resolveWithTimeout:(NSTimeInterval)timeout handler:(STYCompletionBlock)inHandler;
    {
    if (self.netService != NULL)
        {
        if (self.netService.addresses.count > 0)
            {
            self.addresses = self.netService.addresses;
            if (inHandler != NULL)
                {
                inHandler(NULL);
                }
            }
        else
            {
            self.resolveHandler = inHandler;
            self.netService.delegate = self;
            [self.netService resolveWithTimeout:timeout];
            }
        }
    else if (self.hostname != NULL)
        {
        CFHostRef theHost = CFHostCreateWithName(kCFAllocatorDefault, (__bridge CFStringRef)self.hostname);

        CFStreamError theStreamError;
        /*BOOL theResult = */CFHostStartInfoResolution(theHost, kCFHostAddresses, &theStreamError);

        Boolean theResolvedFlag = NO;
        NSArray *theResolvedAddresses = (__bridge NSArray *)CFHostGetAddressing(theHost, &theResolvedFlag);
        if (theResolvedFlag == NO)
            {
            NSLog(@"Could not resolve");
            CFRelease(theHost);

            if (inHandler != NULL)
                {
                NSError *theError = [NSError errorWithDomain:@"TODO_DOMAIN" code:-1 userInfo:NULL];
                inHandler(theError);
                }
            return;
            }
        CFRelease(theHost);

        NSMutableArray *theAddresses = [NSMutableArray array];
        for (NSData *theAddress in theResolvedAddresses)
            {
            [theAddresses addObject:[self _addressData:theAddress withPort:self.port]];
            }

        self.addresses = theAddresses;
        if (inHandler != NULL)
            {
            inHandler(NULL);
            }
        }
    else
        {
        if (inHandler != NULL)
            {
            inHandler(NULL);
            }
        }
    }

- (NSData *)_addressData:(NSData *)inAddressData withPort:(unsigned int)inPort
    {
    struct sockaddr_in theAddress;

    NSParameterAssert(inAddressData.length == sizeof(theAddress));

    memcpy(&theAddress, inAddressData.bytes, sizeof(theAddress));
    theAddress.sin_port = htons(inPort);

    NSData *theAddressData = [NSData dataWithBytes:&theAddress length:sizeof(theAddress)];
    return(theAddressData);
    }

#pragma mark -

- (void)netServiceDidResolveAddress:(NSNetService *)sender
    {
    self.addresses = sender.addresses;
    if (self.resolveHandler != NULL)
        {
        self.resolveHandler(NULL);
        }
    }

- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict
    {
    if (self.resolveHandler != NULL)
        {
        NSError *theError = [NSError errorWithDomain:@"TODO_DOMAIN" code:-1 userInfo:NULL];
        self.resolveHandler(theError);
        }
    }

#pragma mark -

static NSDictionary *DictionaryFromAddress(NSData *inAddress)
    {
    NSMutableDictionary *theParts = [NSMutableDictionary dictionary];

    const struct sockaddr_in *theAddress = [inAddress bytes];

    theParts[@"sin_len"] = @(theAddress->sin_len);
    theParts[@"sin_family"] = @(theAddress->sin_family);
    theParts[@"sin_port"] = @(ntohs(theAddress->sin_port));

    in_addr_t theIPV4Address = ntohl(theAddress->sin_addr.s_addr);

    theParts[@"sin_addr"] = [NSString stringWithFormat:@"%d.%d.%d.%d",
        (theIPV4Address >> 24) & 0xFF,
        (theIPV4Address >> 16) & 0xFF,
        (theIPV4Address >> 8) & 0xFF,
        (theIPV4Address) & 0xFF];

    return theParts;
    }

@end