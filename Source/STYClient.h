//
//  STYClient.h
//  Shanty
//
//  Created by Jonathan Wight on 11/4/13.
//  Copyright (c) 2013 schwa.io. All rights reserved.
//

@import Foundation;

#import "STYCompletionBlocks.h"

@class STYAddress;

@interface STYClient : NSObject

@property (readonly, nonatomic, strong) __attribute__((NSObject)) CFSocketRef socket;

- (instancetype)initWithAddress:(STYAddress *)inAddress;
- (instancetype)initWithHostname:(NSString *)inHostname port:(unsigned short)inPort;

- (void)connect:(STYCompletionBlock)inCompletionBlock;

@end
