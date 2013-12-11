//
//  STYAppDelegate.m
//  Shanty Log Server
//
//  Created by Jonathan Wight on 11/26/13.
//  Copyright (c) 2013 schwa.io. All rights reserved.
//

#import "STYAppDelegate.h"

#import "Shanty.h"

@interface STYAppDelegate ()
@property (readwrite, nonatomic) STYServer *server;
@property (readwrite, nonatomic) NSMutableArray *events;
@end

#pragma mark -

@implementation STYAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
    {
    _events = [NSMutableArray array];

    [self _startServer];
    }

- (void)_startServer
    {
    self.server = [[STYServer alloc] init];

    __weak typeof(self) weak_self = self;
    [self.server.messageHandler addCommand:@"log" handler:^(STYMessagingPeer *inPeer, STYMessage *inMessage, NSError **outError) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weak_self) strong_self = weak_self;
            if (strong_self) {
                NSString *theLogMessage = [[NSString alloc] initWithData:inMessage.data encoding:NSUTF8StringEncoding];
                NSDictionary *theEvent = @{ @"message": theLogMessage };
                [strong_self willChangeValueForKey:@"events"];
                [strong_self.events addObject:theEvent];
                [strong_self didChangeValueForKey:@"events"];
                }
            });
        return(YES);
        }];

    [self.server startListening:NULL];
    }

@end
