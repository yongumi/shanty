//
//  NIMLoggingPeer.m
//  Shanty Examples
//
//  Created by Jonathan Wight on 2/11/14.
//  Copyright (c) 2014 schwa.io. All rights reserved.
//

#import "NIMLoggingPeer.h"

#import <Shanty/Shanty.h>

#import "NIMLoggingSession.h"

@interface NIMLoggingPeer ()
@property (readonly, nonatomic) NSMutableArray *mutableSessions;
//@property (readonly, nonatomic) NSMutableArray *mutableEvents;
@end

#pragma mark -

@implementation NIMLoggingPeer

- (id)initWithSTYPeer:(STYMessagingPeer *)inSTYPeer
    {
    if ((self = [super init]) != NULL)
        {
        _STYPeer = inSTYPeer;
        _mutableSessions = [NSMutableArray arrayWithObject:[[NIMLoggingSession alloc] initWithPeer:self]];
//        _mutableEvents = [NSMutableArray array];
        }
    return self;
    }

- (NSArray *)sessions
    {
    return(self.mutableSessions);
    }

//- (NSArray *)events
//    {
//    return(self.mutableEvents);
//    }

- (NSString *)address
    {
    return([self.STYPeer.socket.address toString]);
    }

- (NIMLoggingSession *)currentSession;
    {
    return([self.sessions lastObject]);
    }

- (void)makeSession
    {
    [self willChangeValueForKey:@"currentSession"];
    [self willChangeValueForKey:@"sessions"];
    [self.mutableSessions addObject:[[NIMLoggingSession alloc] initWithPeer:self]];
    [self didChangeValueForKey:@"sessions"];
    [self didChangeValueForKey:@"currentSession"];
    }

- (void)handleMessage:(STYMessage *)inMessage;
    {
//    [self willChangeValueForKey:@"events"];
//    [self.mutableEvents addObject:inMessage];
//    [self didChangeValueForKey:@"events"];

    [self.currentSession handleMessage:inMessage];
    }

@end
