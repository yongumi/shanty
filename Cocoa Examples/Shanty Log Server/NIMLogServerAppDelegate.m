//
//  STYAppDelegate.m
//  Shanty Log Server
//
//  Created by Jonathan Wight on 11/26/13.
//  Copyright (c) 2013 schwa.io. All rights reserved.
//

#import "NIMLogServerAppDelegate.h"

#import <Shanty/Shanty.h>

#import "NIMLoggingPeer.h"
#import "NIMLoggingSession.h"

@interface NIMLogServerAppDelegate () <STYServerDelegate>
@property (readwrite, nonatomic) STYServer *server;
@property (readwrite, nonatomic) NSMutableDictionary *peersByAddress;
@end

#pragma mark -

@implementation NIMLogServerAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
    {
    self.peersByAddress = [NSMutableDictionary dictionary];
    [self _startServer];
    }

- (NSArray *)peers
    {
    return([self.peersByAddress allValues]);
    }

- (void)_startServer
    {
    self.server = [[STYServer alloc] init];
    self.server.netServiceType = @"_io-schwa-stylog._tcp";
    self.server.delegate = self;

//    __weak typeof(self) weak_self = self;
    [self.server.messageHandler addCommand:NULL handler:^(STYMessagingPeer *inPeer, STYMessage *inMessage, NSError **outError) {
        dispatch_async(dispatch_get_main_queue(), ^{
//            __strong typeof(weak_self) strong_self = weak_self;
//            if (strong_self == NULL) {
//                return;
//                }
//            NSString *theLogMessage = [[NSString alloc] initWithData:inMessage.data encoding:NSUTF8StringEncoding];
//            NSDictionary *theEvent = @{ @"message": theLogMessage };
//            NSDictionary *theDictionary = inPeer.userInfo;
//            NSMutableArray *theEvents = theDictionary[@"events"];
//            [theDictionary willChangeValueForKey:@"events"];
//            [theEvents addObject:theEvent];
//            [theDictionary didChangeValueForKey:@"events"];

            NIMLoggingSession *theSession = inPeer.userInfo;
            [theSession handleMessage:inMessage];
            });
        return(YES);
        }];

    [self.server startListening:NULL];
    }

- (void)server:(STYServer *)inServer peerDidConnect:(STYMessagingPeer *)inPeer
    {
    dispatch_async(dispatch_get_main_queue(), ^{
        NIMLoggingPeer *theLoggingPeer = self.peersByAddress[inPeer.socket.peerAddress.toString];
        if (theLoggingPeer == NULL)
            {
            theLoggingPeer = [[NIMLoggingPeer alloc] initWithSTYPeer:inPeer];
            [self willChangeValueForKey:@"peers"];
            self.peersByAddress[inPeer.socket.peerAddress.toString] = theLoggingPeer;
            [self didChangeValueForKey:@"peers"];
            }
        else
            {
            [theLoggingPeer makeSession];
            }


        inPeer.userInfo = theLoggingPeer.currentSession;
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
