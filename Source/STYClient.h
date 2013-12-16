//
//  STYClient.h
//  Shanty
//
//  Created by Jonathan Wight on 11/4/13.
//  Copyright (c) 2013 schwa.io. All rights reserved.
//

@import Foundation;

#import "STYCompletionBlocks.h"

@interface STYClient : NSObject

@property (readonly, nonatomic) NSString *hostname;
@property (readonly, nonatomic) unsigned short port;
@property (readonly, nonatomic, strong) __attribute__((NSObject)) CFSocketRef socket;

- (instancetype)initWithHostname:(NSString *)inHostname port:(unsigned short)inPort;
- (instancetype)initWithNetService:(NSNetService *)inService;
- (void)connect:(STYCompletionBlock)inCompletionBlock;

@end
