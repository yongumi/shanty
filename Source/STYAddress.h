//
//  STYAddress.h
//  Shanty Examples
//
//  Created by Jonathan Wight on 12/11/13.
//  Copyright (c) 2013 schwa.io. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STYCompletionBlocks.h"

@interface STYAddress : NSObject <NSCopying>

@property (readonly, nonatomic, copy) NSArray *addresses;
@property (readonly, nonatomic) uint16_t port;

- (instancetype)init; // Designated initializer.
- (instancetype)initWithAnyAddress:(uint16_t)inPort;
- (instancetype)initWithLoopbackAddress:(uint16_t)inPort;
- (instancetype)initWithAddresses:(NSArray *)inAddresses;
- (instancetype)initWithHostname:(NSString *)inHostname port:(uint16_t)inPort;
- (instancetype)initWithNetService:(NSNetService *)inNetService;
- (instancetype)initWithIPV4Address:(u_int32_t)inAddress port:(uint16_t)inPort;

- (void)resolveWithTimeout:(NSTimeInterval)timeout handler:(STYCompletionBlock)inHandler;

- (BOOL)isLoopback;

- (NSArray *)IPV4Addresses;
- (NSArray *)IPV6Addresses;

// TODO: This is a quick hack and will be going away.
- (NSString *)toString;

- (instancetype)addressBySettingPort:(int16_t)inPort;


@end
