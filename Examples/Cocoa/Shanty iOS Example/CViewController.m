//
//  CViewController.m
//  Shanty iOS Example
//
//  Created by Jonathan Wight on 11/6/13.
//  Copyright (c) 2013 schwa.io. All rights reserved.
//

#import "CViewController.h"

@import CoreMotion;

#import "STYServer.h"
#import "STYMessagingPeer.h"
#import "STYMessage.h"
#import "STYMessageHandler.h"

@interface CViewController ()
@property (readwrite, nonatomic) CMMotionManager *motionManager;
@property (readwrite, nonatomic) STYServer *server;
@property (readwrite, nonatomic) BOOL sendGyroEvents;
@end

@implementation CViewController

- (void)viewDidLoad
    {
    [super viewDidLoad];

    [self _startServer];
//    [self _startGyroUpdating];
    }

- (void)_startServer
    {
    NSLog(@"Starting server");
    self.server = [[STYServer alloc] init];
    [self.server startListening:NULL];
    }

- (void)_startGyroUpdating
    {
    NSDictionary *theControlData = @{
        @"cmd": @"gyro_update",
        };

    __block int count = 0;

    self.motionManager = [[CMMotionManager alloc] init];
    [self.motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:^(CMDeviceMotion *motion, NSError *error) {

        if ((++count) % 100 == 0)
            {
            NSLog(@"Event: %d", count);
            }

        CMAttitude *theAttitude = motion.attitude;

        NSDictionary *theMetadata = @{
            @"x": @(theAttitude.quaternion.x),
            @"y": @(theAttitude.quaternion.y),
            @"z": @(theAttitude.quaternion.z),
            @"w": @(theAttitude.quaternion.w),
            };

        for (STYMessagingPeer *thePeer in self.server.peers)
            {
            STYMessage *theMessage = [[STYMessage alloc] initWithControlData:theControlData metadata:theMetadata data:NULL];
            [thePeer sendMessage:theMessage replyBlock:NULL];
            }
        }];

    }

@end
