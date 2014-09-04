//
//  STYServiceDiscoverer.h
//  Shanty
//
//  Created by Jonathan Wight on 11/26/13.
//  Copyright (c) 2013 toxicsoftware. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol STYServiceDiscovererDelegate;

@interface STYServiceDiscoverer : NSObject

@property (readonly, nonatomic, copy) NSString *type;
@property (readonly, nonatomic, copy) NSString *domain;
@property (readonly, nonatomic) NSSet *services;
@property (readonly, nonatomic) BOOL started;

- (instancetype)initWithType:(NSString *)inType domain:(NSString *)inDomain;
- (instancetype)initWithType:(NSString *)inType;

- (void)start;
- (void)stop;

- (void)discoverFirstServiceAndStop:(void (^)(NSNetService *service, NSError *error))inHandler;

/**
 *  Attempt to discover the a network service of type. This method is blocking.
 */
- (NSNetService *)discoverFirstService:(NSTimeInterval)inTimeout error:(NSError *__autoreleasing *)outError;

@end
