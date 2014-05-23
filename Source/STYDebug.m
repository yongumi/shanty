//
//  STYDebug.m
//  shanty
//
//  Created by Jonathan Wight on 5/23/14.
//  Copyright (c) 2014 schwa.io. All rights reserved.
//

#import "STYDebug.h"

#if TARGET_OS_IPHONE == 1
#import <UIKit/UIKit.h>
#import <SystemConfiguration/CaptiveNetwork.h>
#endif

#import "STYLogger.h"

@implementation STYDebug

static id gSharedInstance = NULL;

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
//        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationHandler:) name:NULL object:[UIApplication sharedApplication]];
        }
    return self;
    }

- (void)main
    {
#if TARGET_OS_IPHONE == 1
    NSArray *theInterfaces = (__bridge_transfer NSArray *)CNCopySupportedInterfaces();
    for (NSString *theInterface in theInterfaces)
        {
        NSDictionary *theNetworkInfo = (__bridge_transfer NSDictionary *)CNCopyCurrentNetworkInfo((__bridge CFStringRef)theInterface);
        STYLogDebug_(@"%@ %@", theInterface, theNetworkInfo[@"SSID"]);
        }
#endif
    }

- (void)notificationHandler:(NSNotification *)inNotification
    {
    if ([inNotification.name hasPrefix:@"UIApplication"] == NO)
        {
        return;
        }
    STYLogDebug_(@"%@", inNotification.name);
    }

@end

__attribute__((constructor)) static void constructor(void)
    {
    @autoreleasepool
        {
        [[STYDebug sharedInstance] main];
        }
    }
