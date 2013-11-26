//
//  CTest.m
//  DIT Networking
//
//  Created by Jonathan Wight on 11/5/13.
//  Copyright (c) 2013 schwa.io. All rights reserved.
//

#import "CTest.h"

#import <JavaScriptCore/JavaScriptCore.h>

#import "DITClient.h"
#import "DITServer.h"
#import "DITMessagingPeer.h"
#import "DITMessage.h"

@interface CTest ()
@property (readwrite, nonatomic) DITServer *server;
@property (readwrite, nonatomic) NSMutableSet *servedPeers;
@property (readwrite, nonatomic) DITClient *client;
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
    self.server = [[DITServer alloc] init];
    self.servedPeers = [NSMutableSet set];

    NSDictionary *theMessageHandlers = @{
        @"evaluate_script": ^(DITMessagingPeer *inPeer, DITMessage *inMessage, NSError **outError) {
            NSLog(@"%@", inMessage);
            NSString *theScript = [[NSString alloc] initWithData:inMessage.data encoding:NSUTF8StringEncoding];
            JSVirtualMachine *theVirtualMachine = [[JSVirtualMachine alloc] init];
            JSContext *theContext = [[JSContext alloc] initWithVirtualMachine:theVirtualMachine];
            JSValue *theResult = [theContext evaluateScript:theScript];
            NSLog(@"%@", theResult);


//            DITMessage *theResponse = [[DITMessage alloc] initWithControlData:<#(NSDictionary *)#> metadata:<#(NSDictionary *)#> data:<#(NSData *)#>
//            [inPeer sendMessage:theResponse];

            return(YES);
            },
        @"script_result": ^(DITMessagingPeer *inPeer, DITMessage *inMessage, NSError **outError) {
            NSLog(@"%@", inMessage);



            return(YES);
            },
        };


    __weak typeof(self) weak_self = self;

    self.server.connectHandler = ^(CFSocketRef inSocket, NSData *inAddress, NSError **outError) {
        __strong typeof(weak_self) strong_self = weak_self;
        DITMessagingPeer *thePeer = [[DITMessagingPeer alloc] initWithSocket:inSocket messageHandlers:theMessageHandlers];
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
    self.client = [[DITClient alloc] initWithHostname:NULL port:self.server.port];
    [self.client connect:^(NSError *error) {
        DITMessagingPeer *thePeer = [[DITMessagingPeer alloc] initWithSocket:self.client.socket];

        for (int N = 0; N != 1; ++N)
            {
            NSDictionary *theControlData = @{
                @"cmd": @"evaluate_script",
                };
            NSString *theScript = @"10 + 10";
            NSData *theData = [theScript dataUsingEncoding:NSUTF8StringEncoding];
            DITMessage *theMessage = [[DITMessage alloc] initWithControlData:theControlData metadata:NULL data:theData];
            [thePeer sendMessage:theMessage replyBlock:NULL];
            }
        }];

    }

@end
