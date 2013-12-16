//
//  STYAppDelegate.m
//  Shanty Log Server
//
//  Created by Jonathan Wight on 11/26/13.
//  Copyright (c) 2013 schwa.io. All rights reserved.
//

#import "STYAppDelegate.h"

#import <Shanty/Shanty.h>

@interface STYAppDelegate () <STYServerDelegate>
@property (readwrite, nonatomic) STYServer *server;
@property (readwrite, nonatomic) NSMutableArray *peers;
@end

#pragma mark -

@implementation STYAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
    {
    _peers = [NSMutableArray array];

    [self _startServer];
    }

- (void)_startServer
    {
    self.server = [[STYServer alloc] init];
    self.server.delegate = self;

//    __weak typeof(self) weak_self = self;
    [self.server.messageHandler addCommand:NULL handler:^(STYMessagingPeer *inPeer, STYMessage *inMessage, NSError **outError) {
        dispatch_async(dispatch_get_main_queue(), ^{
//            __strong typeof(weak_self) strong_self = weak_self;
//            if (strong_self == NULL) {
//                return;
//                }
            NSString *theLogMessage = [[NSString alloc] initWithData:inMessage.data encoding:NSUTF8StringEncoding];
            NSDictionary *theEvent = @{ @"message": theLogMessage };
            NSDictionary *theDictionary = inPeer.userInfo;
            NSMutableArray *theEvents = theDictionary[@"events"];
            [theDictionary willChangeValueForKey:@"events"];
            [theEvents addObject:theEvent];
            [theDictionary didChangeValueForKey:@"events"];
            });
        return(YES);
        }];

    [self.server startListening:NULL];
    }

- (void)server:(STYServer *)inServer peerDidConnect:(STYMessagingPeer *)inPeer
    {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self willChangeValueForKey:@"peers"];
        NSDictionary *theDictionary = @{
            @"peer": inPeer,
            @"address": inPeer.peerAddress,
            @"events": [NSMutableArray array],
            };
        [self.peers addObject:theDictionary];
        inPeer.userInfo = theDictionary;
        [self didChangeValueForKey:@"peers"];
    });
    }

- (void)server:(STYServer *)inServer peerDidDisconnect:(STYMessagingPeer *)inPeer
    {
    dispatch_async(dispatch_get_main_queue(), ^{
//        [self willChangeValueForKey:@"peers"];
//        [self.peers removeObject:inPeer];
//        [self didChangeValueForKey:@"peers"];
    });
    }

@end
