//
//  STYLogging.m
//  TwitterNT
//
//  Created by Jonathan Wight on 11/26/13.
//  Copyright (c) 2013 toxicsoftware. All rights reserved.
//

#import "STYLogging.h"

#import "STYClient.h"
#import "STYServiceDiscoverer.h"
#import "STYMessagingPeer.h"
#import "STYMessage.h"
#import "STYConstants.h"

@interface STYLogging ()
@property (readwrite, nonatomic) STYServiceDiscoverer *discoverer;
@property (readwrite, nonatomic) STYClient *client;
@property (readwrite, nonatomic) STYMessagingPeer *peer;
@end

#pragma mark -

@implementation STYLogging

static STYLogging *gSharedInstance = NULL;

//+ (void)load
//    {
//    [self sharedInstance];
//    double delayInSeconds = 5.0;
//    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
//    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
//        [[self sharedInstance] log:@"Hello world"];
//        });
//    }

+ (instancetype)sharedInstance
    {
    static dispatch_once_t sOnceToken = 0;
    dispatch_once(&sOnceToken, ^{
        gSharedInstance = [[self alloc] init];
        });
    return(gSharedInstance);
    }

- (instancetype)init
    {
    if ((self = [super init]) != NULL)
        {
        // This is too much code just to connect.
        _discoverer = [[STYServiceDiscoverer alloc] init];
        __weak typeof(self) weak_self = self;
        [_discoverer start:^(STYClient *client, NSError *error) {

            NSLog(@"Starting client");
            __strong typeof(weak_self) strong_self = weak_self;
            if (strong_self == NULL)
                {
                return;
                }
            strong_self.discoverer = NULL;
            strong_self.client = client;

            [strong_self.client connect:^(NSError *error) {
                NSLog(@"CONNECTED? %@", error);
                strong_self.peer = strong_self.client.peer;
                }];
            }];
        }
    return self;
    }

- (void)log:(NSString *)inMessage
    {
    if (self.peer == NULL)
        {
//        NSLog(@"No peer. Logs are getting dropped!");
        return;
        }
    
    NSDictionary *theControlData = @{
        kSTYCommandKey: @"log",
        };
    NSData *theData = [inMessage dataUsingEncoding:NSUTF8StringEncoding];
    STYMessage *theMessage = [[STYMessage alloc] initWithControlData:theControlData metadata:NULL data:theData];
    [self.peer sendMessage:theMessage replyBlock:NULL];
    }

@end
