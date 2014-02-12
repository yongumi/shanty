//
//  NIMLoggingSession.m
//  Shanty Examples
//
//  Created by Jonathan Wight on 2/11/14.
//  Copyright (c) 2014 schwa.io. All rights reserved.
//

#import "NIMLoggingSession.h"

#import <Shanty/Shanty.h>

#import "NIMLoggingPeer.h"

@interface NIMLoggingSession ()
@property (readonly, nonatomic, weak) NIMLoggingPeer *peer;
@property (readonly, nonatomic, copy) NSDate *created;
@property (readonly, nonatomic) NSMutableArray *mutableEvents;
@end

#pragma mark -

@implementation NIMLoggingSession

- (instancetype)initWithPeer:(NIMLoggingPeer *)inPeer
    {
    if ((self = [super init]) != NULL)
        {
        _peer = inPeer;
        _created = [NSDate date];
        _mutableEvents = [NSMutableArray array];
        }
    return self;
    }

- (NSArray *)events
    {
    return(self.mutableEvents);
    }

- (void)handleMessage:(STYMessage *)inMessage;
    {
    [self willChangeValueForKey:@"events"];
    [self.mutableEvents addObject:inMessage];
    [self didChangeValueForKey:@"events"];

    }

@end
