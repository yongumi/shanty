//
//  STYServiceDiscoverer.h
//  Shanty
//
//  Created by Jonathan Wight on 11/26/13.
//  Copyright (c) 2013 toxicsoftware. All rights reserved.
//

#import <Foundation/Foundation.h>
@class STYMessagingPeer;

@interface STYServiceDiscoverer : NSObject

@property (readonly, nonatomic, copy) NSString *type;
@property (readonly, nonatomic, copy) NSString *domain;
@property (readonly, nonatomic) NSSet *services;
@property (readwrite, nonatomic, strong) BOOL (^serviceAcceptanceHandler)(NSNetService *service);

- (instancetype)initWithType:(NSString *)inType domain:(NSString *)inDomain;

- (void)start;
- (void)stop;

- (void)discoverFirstServiceAndStop:(void (^)(NSNetService *service, NSError *error))inHandler;

@end
