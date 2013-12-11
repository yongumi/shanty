//
//  CTest.m
//  Shanty Networking
//
//  Created by Jonathan Wight on 11/5/13.
//  Copyright (c) 2013 schwa.io. All rights reserved.
//

#import "CTest.h"

#import <JavaScriptCore/JavaScriptCore.h>

#import "STYClient.h"
#import "STYServer.h"
#import "STYMessagingPeer.h"
#import "STYMessage.h"

@interface CTest ()
@property (readwrite, nonatomic) STYServer *server;
@property (readwrite, nonatomic) NSMutableSet *servedPeers;
@property (readwrite, nonatomic) STYClient *client;
@end

@implementation CTest

- (void)main
    {
    [self _startServer];
    while (YES)
        {
//        NSLog(@"TICK");
        [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        }
    }

- (void)_startServer
    {
    NSLog(@"Starting server");
    self.server = [[STYServer alloc] init];
    self.servedPeers = [NSMutableSet set];

    NSDictionary *theMessageHandlers = @{
        @"evaluate_script": ^(STYMessagingPeer *inPeer, STYMessage *inMessage, NSError **outError) {
            NSLog(@"%@", inMessage);
            NSString *theScript = [[NSString alloc] initWithData:inMessage.data encoding:NSUTF8StringEncoding];
            JSVirtualMachine *theVirtualMachine = [[JSVirtualMachine alloc] init];
            JSContext *theContext = [[JSContext alloc] initWithVirtualMachine:theVirtualMachine];
            JSValue *theResult = [theContext evaluateScript:theScript];
            NSLog(@"%@", theResult);

//            STYMessage *theResponse = [[STYMessage alloc] initWithControlData:<#(NSDictionary *)#> metadata:<#(NSDictionary *)#> data:<#(NSData *)#>
//            [inPeer sendMessage:theResponse];

            return(YES);
            },
        @"script_result": ^(STYMessagingPeer *inPeer, STYMessage *inMessage, NSError **outError) {
            NSLog(@"%@", inMessage);



            return(YES);
            },
        };


    __weak typeof(self) weak_self = self;

    self.server.connectHandler = ^(CFSocketRef inSocket, NSData *inAddress, NSError **outError) {
        __strong typeof(weak_self) strong_self = weak_self;
        STYMessagingPeer *thePeer = [[STYMessagingPeer alloc] initWithSocket:inSocket messageHandlers:theMessageHandlers];
        [strong_self.servedPeers addObject:thePeer];
        return(YES);
        };
    [self.server startListening:^(NSError *inError) {
        __strong typeof(weak_self) strong_self = weak_self;
        [strong_self _startClient];
        }];
    }

- (void)_startClient
    {
    NSLog(@"Starting client");
    self.client = [[STYClient alloc] initWithHostname:NULL port:self.server.port];
    [self.client connect:^(NSError *error) {
        STYMessagingPeer *thePeer = [[STYMessagingPeer alloc] initWithSocket:self.client.socket];

        for (int N = 0; N != 1; ++N)
            {
            NSDictionary *theControlData = @{
                @"cmd": @"evaluate_script",
                };
            NSString *theScript = @"10 + 10";
            NSData *theData = [theScript dataUsingEncoding:NSUTF8StringEncoding];
            STYMessage *theMessage = [[STYMessage alloc] initWithControlData:theControlData metadata:NULL data:theData];
            [thePeer sendMessage:theMessage replyBlock:NULL];
            }
        }];

    }

@end
