//
//  STYAddress.h
//  Shanty Examples
//
//  Created by Jonathan Wight on 12/11/13.
//  Copyright (c) 2013 schwa.io. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STYResolveable.h"

@interface STYAddress : NSObject <NSCopying, STYResolveable>

@property (readonly, nonatomic, copy) NSData *addressData;
@property (readonly, nonatomic) uint16_t port;

- (instancetype)init; // Designated initializer.
- (instancetype)initWithAnyAddress:(unsigned int)inPort;
- (instancetype)initWithLoopbackAddress:(unsigned int)inPort;
- (instancetype)initWithAddressData:(NSData *)inAddressData;
- (instancetype)initWithHostname:(NSString *)inHostname port:(unsigned int)inPort;
- (instancetype)initWithIPV4Address:(u_int32_t)inAddress port:(uint16_t)inPort;

- (void)resolveWithTimeout:(NSTimeInterval)timeout handler:(STYCompletionBlock)inHandler;

- (BOOL)isLoopback;

// TODO: This is a quick hack and will be going away.
- (NSString *)toString;

- (instancetype)addressBySettingPort:(int16_t)inPort;

@end
