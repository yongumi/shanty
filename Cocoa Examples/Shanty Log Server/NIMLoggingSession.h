//
//  NIMLoggingSession.h
//  Shanty Examples
//
//  Created by Jonathan Wight on 2/11/14.
//  Copyright (c) 2014 schwa.io. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NIMLoggingPeer;
@class STYMessage;

@interface NIMLoggingSession : NSObject

@property (readonly, nonatomic, copy) NSArray *events;

- (instancetype)initWithPeer:(NIMLoggingPeer *)inPeer;

- (void)handleMessage:(STYMessage *)inMessage;

@end
