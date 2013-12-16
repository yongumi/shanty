//
//  STYDebugTool.m
//  Shanty Examples
//
//  Created by Jonathan Wight on 12/10/13.
//  Copyright (c) 2013 schwa.io. All rights reserved.
//

#import "STYDebugTool.h"

#import <Shanty/Shanty.h>

@interface STYDebugTool ()
@property (readwrite, nonatomic) STYServer *server;
@end

@implementation STYDebugTool

+ (void)load
    {
    @autoreleasepool {
        [[self sharedInstance] _startServer];
        }
    }

static STYDebugTool *gSharedInstance = NULL;

+ (instancetype)sharedInstance
    {
    static dispatch_once_t sOnceToken = 0;
    dispatch_once(&sOnceToken, ^{
        gSharedInstance = [[self alloc] init];
        });
    return(gSharedInstance);
    }


- (void)_startServer
    {
    NSLog(@"Starting server");
    self.server = [[STYServer alloc] init];
    self.server.netServiceType = @"_stydebugtool._tcp";

    __weak typeof(self) weak_self = self;
    [self.server.messageHandler addCommand:@"snapshots" handler:^(STYMessagingPeer *inPeer, STYMessage *inMessage, NSError **outError)
        {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weak_self) strong_self = weak_self;
            [strong_self _recurseImages:[[UIApplication sharedApplication] keyWindow] depth:0 block:^(NSData *image) {
                NSDictionary *theControl = @{
                    @"cmd": @"snapshot.reply",
                    @"in-reply-to": inMessage.controlData[@"msgid"],
                    @"more-coming": @(1),
                    };
                STYMessage *theMessage = [[STYMessage alloc] initWithControlData:theControl metadata:NULL data:image];
                [inPeer sendMessage:theMessage replyBlock:NULL];
                }];


            NSDictionary *theControl = @{
                @"cmd": @"snapshot.reply",
                @"in-reply-to": inMessage.controlData[@"msgid"],
                @"more-coming": @(0),
                };
            STYMessage *theMessage = [[STYMessage alloc] initWithControlData:theControl metadata:NULL data:NULL];
            [inPeer sendMessage:theMessage replyBlock:NULL];
            });


        return(YES);
        }];

    [self.server startListening:NULL];
    }

- (void)_recurseImages:(UIView *)inView depth:(int)inDepth block:(void (^)(NSData *image))block
    {
//    NSLog(@"%@ %@", [@"" stringByPaddingToLength:inDepth withString:@"." startingAtIndex:0], inView);

    if (CGRectIsEmpty(inView.bounds) == NO)
        {
        UIGraphicsBeginImageContextWithOptions(inView.bounds.size, NO, 0.0);

        UIView *theSnapshot = [inView snapshotViewAfterScreenUpdates:YES];
        [theSnapshot drawViewHierarchyInRect:theSnapshot.bounds afterScreenUpdates:YES];

        UIImage *theImage = UIGraphicsGetImageFromCurrentImageContext();

        UIGraphicsEndImageContext();

        NSData *thePNG = UIImagePNGRepresentation(theImage);
        block(thePNG);
        }

    for (UIView *theSubview in inView.subviews)
        {
        [self _recurseImages:theSubview depth:inDepth + 1 block:block];
        }
    }


@end
