//
//  STYRevealLiteManager.h
//  EmbeddingTest
//
//  Created by Jonathan Wight on 2/13/14.
//  Copyright (c) 2014 schwa. All rights reserved.
//

#import <Foundation/Foundation.h>

@class STYMessagingPeer;

@interface STYRevealLiteManager : NSObject

+ (NSString *)netServiceType;

+ (instancetype)sharedInstance;

#if TARGET_OS_IPHONE
- (void)start;
#endif

- (void)fetch:(STYMessagingPeer *)inPeer toDirectory:(NSURL *)inURL completion:(void (^)(NSError *))completion;

@end