//
//  NIMApplicationModel.m
//  Shanty Examples
//
//  Created by Jonathan Wight on 2/19/14.
//  Copyright (c) 2014 schwa.io. All rights reserved.
//

#import "NIMApplicationModel.h"

@interface NIMApplicationModel ()
@property (readwrite, nonatomic) NSMutableSet *mutablePeers;
@property (readwrite, nonatomic) NSMutableArray *mutableMessages;
@end

#pragma mark -

@implementation NIMApplicationModel

static id gSharedInstance = NULL;

+ (instancetype)sharedInstance
    {
    static dispatch_once_t sOnceToken = 0;
    dispatch_once(&sOnceToken, ^{
        gSharedInstance = [[self alloc] init];
        });
    return(gSharedInstance);
    }

- (id)init
    {
    if ((self = [super init]) != NULL)
        {
        _mutablePeers = [NSMutableSet set];
        _mutableMessages = [NSMutableArray array];
        }
    return self;
    }

- (NSSet *)peers
    {
    return(self.mutablePeers);
    }

- (NSArray *)messages
    {
    return(self.mutableMessages);
    }

- (void)addPeer:(STYMessagingPeer *)inPeer
    {
    [self willChangeValueForKey:@"peers"];
    [self.mutablePeers addObject:inPeer];
    [self didChangeValueForKey:@"peers"];
    }

- (void)removePeer:(STYMessagingPeer *)inPeer
    {
    [self willChangeValueForKey:@"peers"];
    [self.mutablePeers removeObject:inPeer];
    [self didChangeValueForKey:@"peers"];
    }

- (void)addMessage:(STYMessage *)inMessage peer:(STYMessagingPeer *)inPeer direction:(NSString *)inDirection;
    {
    NSDictionary *theDictionary = @{
        @"message": inMessage,
        @"peer": inPeer,
        @"direction": @[ @"unknown", @"incoming", @"outgoing" ][inMessage.direction],
        };

    [self willChangeValueForKey:@"messages"];
    [self.mutableMessages addObject:theDictionary];
    [self didChangeValueForKey:@"messages"];
    }

@end
