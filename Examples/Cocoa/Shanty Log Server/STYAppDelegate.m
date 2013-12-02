//
//  STYAppDelegate.m
//  Shanty Log Server
//
//  Created by Jonathan Wight on 11/26/13.
//  Copyright (c) 2013 schwa.io. All rights reserved.
//

#import "STYAppDelegate.h"

#import "STYServer.h"
#import "STYMessagingPeer.h"
#import "STYMessage.h"

@interface STYAppDelegate ()
@property (readwrite, nonatomic) STYServer *server;
@property (readwrite, nonatomic) NSMutableSet *servedPeers;

@end

#pragma mark -

@implementation STYAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
    {
    [self _startServer];
    }

- (void)_startServer
    {
    NSLog(@"Starting server");
    self.server = [[STYServer alloc] init];
    self.servedPeers = [NSMutableSet set];

    __weak typeof(self) weak_self = self;

    NSDictionary *theHandlers = @{

        @"log": ^(STYMessagingPeer *inPeer, STYMessage *inMessage, NSError **outError) {
            NSString *theLogMessage = [[NSString alloc] initWithData:inMessage.data encoding:NSUTF8StringEncoding];
            NSLog(@"%@", theLogMessage);
            },
        };

    self.server.connectHandler = ^(CFSocketRef inSocket, NSData *inAddress, NSError **outError) {
        __strong typeof(weak_self) strong_self = weak_self;
        STYMessagingPeer *thePeer = [[STYMessagingPeer alloc] initWithSocket:inSocket messageHandlers:theHandlers];
        [strong_self.servedPeers addObject:thePeer];
        return(YES);
        };
    [self.server startListening:^(NSError *inError) {
        }];
    }

@end
