//
//  STYAddress.m
//  Shanty Examples
//
//  Created by Jonathan Wight on 12/11/13.
//  Copyright (c) 2013 schwa.io. All rights reserved.
//

#import "STYAddress.h"

#include <netinet/in.h>

@interface STYAddress ()
@end

#pragma mark -

@implementation STYAddress

- (id)initWithData:(NSData *)inData
    {
    if ((self = [super init]) != NULL)
        {
        _data = inData;
        }
    return self;
    }

- (id)copyWithZone:(NSZone *)zone;
    {
    return(self);
    }

- (NSString *)description
    {
//    return([NSString stringWithFormat:@"%@ %@", [super description], DictionaryFromAddress(self.data)]);
    NSDictionary *theParts = DictionaryFromAddress(self.data);
    return([NSString stringWithFormat:@"%@:%@", theParts[@"sin_addr"], theParts[@"sin_port"]]);
    }

static NSDictionary *DictionaryFromAddress(NSData *inAddress)
    {
    NSMutableDictionary *D = [NSMutableDictionary dictionary];

    const struct sockaddr_in *theAddress = [inAddress bytes];

    D[@"sin_len"] = @(theAddress->sin_len);
    D[@"sin_family"] = @(theAddress->sin_family);
    D[@"sin_port"] = @(ntohs(theAddress->sin_port));


    in_addr_t theIPV4Address = ntohl(theAddress->sin_addr.s_addr);

    D[@"sin_addr"] = [NSString stringWithFormat:@"%d.%d.%d.%d",
        (theIPV4Address >> 24) & 0xFF,
        (theIPV4Address >> 16) & 0xFF,
        (theIPV4Address >> 8) & 0xFF,
        (theIPV4Address) & 0xFF];

    return D;
    }

@end
