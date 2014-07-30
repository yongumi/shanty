//
//  STYAddressSet.h
//  shanty
//
//  Created by Jonathan Wight on 7/24/14.
//  Copyright (c) 2014 schwa.io. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STYResolveable.h"

@class STYAddress;

@interface STYAddressSet : NSObject <NSCopying, STYResolveable>

- (instancetype)initWithAddresses:(NSArray *)inAddresses;
- (instancetype)initWithAddress:(STYAddress *)inAddress;

- (STYAddressSet *)allIPV4Addreses;
- (STYAddressSet *)allIPV6Addreses;

@end


@interface STYAddressSet (NSNetService)
- (instancetype)initWithNetService:(NSNetService *)inNetService;
@end
