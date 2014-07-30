//
//  STYResolveable.h
//  shanty
//
//  Created by Jonathan Wight on 7/30/14.
//  Copyright (c) 2014 schwa.io. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STYCompletionBlocks.h"

@protocol STYResolveable <NSObject>

@property (readonly, nonatomic) BOOL resolved;

- (void)resolveWithTimeout:(NSTimeInterval)timeout handler:(STYCompletionBlock)inHandler;

@end
