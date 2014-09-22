//
//  STYAddress.m
//  Shanty Examples
//
//  Created by Jonathan Wight on 12/11/13.
//  Copyright (c) 2013 schwa.io. All rights reserved.
//

#import "STYAddress.h"

#include <netinet/in.h>
#include <arpa/inet.h>

#import "STYLogger.h"
#import "STYConstants.h"

// TODO - hey what about that IPV6?

@interface STYAddress () <NSNetServiceDelegate>
@property (readwrite, nonatomic, copy) NSArray *addresses;
@property (readwrite, nonatomic, copy) NSString *hostname;
@property (readwrite, nonatomic) uint16_t port;
@property (readwrite, nonatomic, strong) NSNetService *netService;
@property (readwrite, nonatomic, copy) void (^resolveHandler)(NSError *);
@end

#pragma mark -

@implementation STYAddress

- (instancetype)init
    {
    if ((self = [super init]) != NULL)
        {
        }
    return self;
    }

- (instancetype)initWithAnyAddress:(uint16_t)inPort
    {
    if ((self = [self initWithIPV4Address:INADDR_ANY port:inPort]) != NULL)
        {
        }
    return self;
    }

- (instancetype)initWithLoopbackAddress:(uint16_t)inPort
    {
    if ((self = [self initWithIPV4Address:INADDR_LOOPBACK port:inPort]) != NULL)
        {
        }
    return self;
    }

- (instancetype)initWithAddresses:(NSArray *)inAddresses
    {
    NSParameterAssert(inAddresses.count > 0);
    
    if ((self = [self init]) != NULL)
        {
        _addresses = [inAddresses copy];
        _port = _portForAddress(inAddresses[0]);
        }
    return self;
    }

- (instancetype)initWithHostname:(NSString *)inHostname port:(uint16_t)inPort
    {
    if ((self = [self init]) != NULL)
        {
        _hostname = [inHostname copy];
        _port = inPort;
        }
    return self;
    }

- (instancetype)initWithIPV4Address:(u_int32_t)inAddress port:(uint16_t)inPort
    {
    struct sockaddr_in theSockAddress = {
        .sin_len = sizeof(theSockAddress),
        .sin_family = AF_INET, // IPV4 style address
        .sin_port = htons(inPort),
        .sin_addr = htonl(inAddress),
        };
    
    if ((self = [self initWithAddresses:@[ [NSData dataWithBytes:&theSockAddress length:sizeof(theSockAddress)] ]]) != NULL)
        {
        }
    return self;
    }

- (instancetype)initWithNetService:(NSNetService *)inNetService;
    {
    if ((self = [self init]) != NULL)
        {
        _netService = inNetService;
        }
    return self;
    }

- (void)dealloc
    {
    if (_netService.delegate == self)
        {
        _netService.delegate = nil;
        }
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
        [theDescriptions addObject:[NSString stringWithFormat:@"%@:%u", self.hostname, self.port]];
        }
    else if (self.netService != NULL)
        {
        [theDescriptions addObject:[NSString stringWithFormat:@"%@", [self.netService description]]];
        }
    
    if (self.addresses)
        {
        for (NSData *theAddress in self.addresses)
            {
            [theDescriptions addObject:[NSString stringWithFormat:@"%@:%hu", _descriptionForAddress(theAddress), _portForAddress(theAddress)]];
            }
        }
    else
        {
        [theDescriptions addObject:[NSString stringWithFormat:@":%u", self.port]];
        }
    

    return([NSString stringWithFormat:@"%@ (%@)", [super description], [theDescriptions componentsJoinedByString:@", "]]);
    }

- (NSString *)toString
    {
    // TODO HACK
    // This only returns the first address and only works on IPV4
    NSData *theAddress = self.addresses.firstObject;
    return [NSString stringWithFormat:@"%@:%hu", _descriptionForAddress(theAddress), _portForAddress(theAddress)];
    }

- (instancetype)addressBySettingPort:(int16_t)inPort;
    {
    STYAddress *theAddress = [[STYAddress alloc] initWithHostname:self.hostname port:inPort];
    return(theAddress);
    }


#pragma mark -

- (void)resolveWithTimeout:(NSTimeInterval)timeout handler:(STYCompletionBlock)inHandler
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
            STYLogError_(@"Could not resolve");
            CFRelease(theHost);

            if (inHandler != NULL)
                {
                NSError *theError = [NSError errorWithDomain:kSTYErrorDomain code:kSTYErrorCode_Unknown userInfo:NULL];
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

#pragma mark -

- (BOOL)isLoopback
    {
    // TODO: This is a bit of a hack.
    return self.addresses.count == 1 && [self.addresses[0] isEqual:[self _addressDataWithIPV4Address:INADDR_LOOPBACK port:self.port]];
    }

- (NSArray *)IPV4Addresses
    {
    NSMutableArray *IPV4Addresses = [NSMutableArray array];
    for (NSData *addressData in self.addresses)
        {
        if (addressData.length == sizeof(struct sockaddr_in))
            {
            const struct sockaddr_in *theSockAddress = addressData.bytes;
            if (theSockAddress->sin_family == AF_INET)
                {
                [IPV4Addresses addObject:addressData];
                }
            }
        }
    return(IPV4Addresses);
    }

- (NSArray *)IPV6Addresses
    {
    NSMutableArray *IPV6Addresses = [NSMutableArray array];
    for (NSData *addressData in self.addresses)
        {
        if (addressData.length == sizeof(struct sockaddr_in6))
            {
            const struct sockaddr_in6 *theSockAddress = addressData.bytes;
            if (theSockAddress->sin6_family == AF_INET6)
                {
                [IPV6Addresses addObject:addressData];
                }
            }
        }
    return(IPV6Addresses);
    }

- (NSData *)_addressDataWithIPV4Address:(u_int32_t)inAddress port:(uint16_t)inPort
    {
    struct sockaddr_in theSockAddress = {
        .sin_len = sizeof(theSockAddress),
        .sin_family = AF_INET, // IPV4 style address
        .sin_port = htons(inPort),
        .sin_addr = htonl(inAddress),
        };
    
    return [NSData dataWithBytes:&theSockAddress length:sizeof(theSockAddress)];
    }

- (NSData *)_addressData:(NSData *)inAddressData withPort:(uint16_t)inPort
    {
    struct sockaddr_in theAddress;

    NSParameterAssert(inAddressData.length == sizeof(theAddress));

    memcpy(&theAddress, inAddressData.bytes, sizeof(theAddress));
    theAddress.sin_port = htons(inPort);

    NSData *theAddressData = [NSData dataWithBytes:&theAddress length:sizeof(theAddress)];
    return(theAddressData);
    }

- (void)netServiceDidResolveAddress:(NSNetService *)sender
    {
    self.addresses = sender.addresses;
    if (self.resolveHandler != NULL)
        {
        self.resolveHandler(NULL);
        self.resolveHandler = NULL;
        }
    }

- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict
    {
    if (self.resolveHandler != NULL)
        {
        NSError *theError = [NSError errorWithDomain:kSTYErrorDomain code:kSTYErrorCode_Unknown userInfo:NULL];
        self.resolveHandler(theError);
        self.resolveHandler = NULL;
        }
    }

static NSString *_descriptionForAddress(NSData *inAddress)
    {
    const struct sockaddr_in *theAddress = inAddress.bytes;
    const socklen_t theLength = INET6_ADDRSTRLEN > INET_ADDRSTRLEN ? INET6_ADDRSTRLEN : INET_ADDRSTRLEN;
    char buffer[theLength];
    inet_ntop(theAddress->sin_family, &theAddress->sin_addr, buffer, theLength);
    return theAddress->sin_family == AF_INET ? [NSString stringWithUTF8String:buffer] : [NSString stringWithFormat:@"[%s]", buffer];;
    }

UInt16 _portForAddress(NSData *inAddress)
    {
    const struct sockaddr_in *theAddress = inAddress.bytes;
    return ntohs(theAddress->sin_port);
    }

@end
