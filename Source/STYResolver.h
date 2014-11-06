//
//  STYResolver.h
//  STYNetBrowser
//
//  Created by Jonathan Wight on 11/4/14.
//  Copyright (c) 2014 schwa.io. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface STYResolver : NSObject

@property (readwrite, nonatomic, strong) dispatch_queue_t queue;

- (void)resolveName:(NSString *)name service:(NSString *)service handler:(void (^)(NSArray *addresses, NSError *error))handler;
- (void)resolveName:(NSString *)name handler:(void (^)(NSArray *addresses, NSError *error))handler;

@end
