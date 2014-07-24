//
//  STYAddressSet.h
//  shanty
//
//  Created by Jonathan Wight on 7/24/14.
//  Copyright (c) 2014 schwa.io. All rights reserved.
//

#import <Foundation/Foundation.h>

@class STYAddress;

@interface STYAddressSet : NSObject

- (instancetype)initWithAddresses:(NSArray *)inAddresses;
- (instancetype)initWithAddress:(STYAddress *)inAddress;

- (NSArray *)allIPV4Addreses;
- (NSArray *)allIPV6Addreses;

@end
