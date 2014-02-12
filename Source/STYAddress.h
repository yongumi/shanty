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

- (instancetype)initWithAddresses:(NSArray *)inAddresses;
- (instancetype)initWithHostname:(NSString *)inHostname port:(unsigned int)inPort;
- (instancetype)initWithNetService:(NSNetService *)inNetService;

- (void)resolveWithTimeout:(NSTimeInterval)timeout handler:(STYCompletionBlock)inHandler;

// TODO: This is a quick hack and will be going away.
- (NSString *)toString;

@end
