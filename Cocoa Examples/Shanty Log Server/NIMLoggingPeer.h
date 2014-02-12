//
//  NIMLoggingPeer.h
//  Shanty Examples
//
//  Created by Jonathan Wight on 2/11/14.
//  Copyright (c) 2014 schwa.io. All rights reserved.
//

#import <Foundation/Foundation.h>

@class STYAddress;
@class STYMessage;
@class STYMessagingPeer;
@class NIMLoggingSession;

@interface NIMLoggingPeer : NSObject

@property (readonly, nonatomic) STYMessagingPeer *STYPeer;
@property (readonly, nonatomic) STYAddress *address;
@property (readonly, nonatomic, copy) NSArray *sessions;
//@property (readonly, nonatomic, copy) NSArray *events;
@property (readonly, nonatomic) NIMLoggingSession *currentSession;

- (id)initWithSTYPeer:(STYMessagingPeer *)inSTYPeer;

- (void)makeSession;
- (void)handleMessage:(STYMessage *)inMessage;

@end
