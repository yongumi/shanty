//
//  main.m
//  SimpleTest
//
//  Created by Jonathan Wight on 5/7/14.
//  Copyright (c) 2014 schwa.io. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Shanty/Shanty.h>

int main(int argc, const char * argv[])
    {
    @autoreleasepool
        {
        NSLog(@"1");

        STYServiceDiscoverer *theDiscoverer = [[STYServiceDiscoverer alloc] initWithType:@"_io-schwa-prefstest._tcp."];
        NSNetService *theNetService = [theDiscoverer discoverFirstService:30.0 error:NULL];

        NSLog(@"%@", theNetService);

        __block BOOL theFlag = NO;
        __block STYPeer *thePeer = NULL;

        [theDiscoverer connectToService:theNetService openPeer:YES completion:^(STYPeer *peer, NSError *error) {
            NSLog(@"CONNECTED");
            thePeer = peer;
            theFlag = YES;
            }];

        while (theFlag == NO)
            {
            [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];
            }
        theDiscoverer = NULL;

        theFlag = NO;

        [thePeer close:^(NSError *error) {
            NSLog(@"CLOSED");
            thePeer = NULL;
            theFlag = YES;
            }];

        while (theFlag == NO)
            {
            [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];
            }

        }

    [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];


    NSLog(@"DONE");
    sleep(10000);

    return 0;
    }

