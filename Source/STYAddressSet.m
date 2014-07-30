//
//  STYAddressSet.m
//  shanty
//
//  Created by Jonathan Wight on 7/24/14.
//  Copyright (c) 2014 schwa.io. All rights reserved.
//

#import "STYAddressSet.h"

@interface STYAddressSet ()
@property (readwrite, nonatomic, copy) NSArray *addresses;
@end

#pragma mark -

@implementation STYAddressSet

- (instancetype)initWithAddresses:(NSArray *)inAddresses;
    {
    if ((self = [super init]) != NULL)
        {
        _addresses = inAddresses;
        }
    return self;
    }


- (instancetype)initWithAddress:(STYAddress *)inAddress
    {
    return [self initWithAddresses:@[ inAddress ]];
    }

- (STYAddressSet *)allIPV4Addreses
    {
    return self.addresses.firstObject;
    }

- (STYAddressSet *)allIPV6Addreses
    {
    return self.addresses.firstObject;
    }

@end

#pragma mark -

@implementation STYAddressSet (NSNetService)

- (instancetype)initWithNetService:(NSNetService *)inNetService
    {
    if ((self = [self init]) != NULL)
        {
        }
    return self;
    }



@end
