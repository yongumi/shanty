//
//  STYServicePublisher.h
//  shanty
//
//  Created by Jonathan Wight on 5/23/14.
//  Copyright (c) 2014 schwa.io. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STYCompletionBlocks.h"

@interface STYServicePublisher : NSObject

@property (readwrite, nonatomic, copy) NSString *netServiceDomain;
@property (readwrite, nonatomic, copy) NSString *netServiceType;
@property (readwrite, nonatomic, copy) NSArray *netServiceSubtypes;
@property (readwrite, nonatomic, copy) NSString *netServiceName;
@property (readwrite, nonatomic) uint16_t port;
@property (readwrite, nonatomic) BOOL localhostOnly;

@property (readonly, nonatomic) BOOL publishing;

+ (NSString *)defaultNetServiceDomain;
+ (NSString *)defaultNetServiceType;
+ (NSString *)defaultNetServiceName;

- (instancetype)initWithNetServiceDomain:(NSString *)inDomain type:(NSString *)inType name:(NSString *)inName port:(uint16_t)inPort;
- (instancetype)initWithPort:(uint16_t)inPort;

- (void)startPublishing:(STYCompletionBlock)inResultHandler;
- (void)stopPublishing:(STYCompletionBlock)inResultHandler;

@end
