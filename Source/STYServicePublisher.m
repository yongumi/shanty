//
//  STYServicePublisher.m
//  shanty
//
//  Created by Jonathan Wight on 5/23/14.
//  Copyright (c) 2014 schwa.io. All rights reserved.
//

#import "STYServicePublisher.h"

#if TARGET_OS_IPHONE == 1
#import <UIKit/UIKit.h>
#endif

#import "STYLogger.h"
#import "NSNetService+STYUserInfo.h"
#import "STYConstants.h"

@interface STYServicePublisher () <NSNetServiceDelegate>
@property (readwrite, nonatomic) NSNetService *netService;
@property (readwrite, nonatomic) BOOL publishing;
@property (readwrite, nonatomic) BOOL resumeOnForegrounding;
@property (readwrite, nonatomic) dispatch_source_t source;
@end

#pragma mark -

@implementation STYServicePublisher

+ (NSString *)defaultNetServiceDomain
    {
    return @"";
    }

+ (NSString *)defaultNetServiceType
    {
    NSString *theType = [[[[NSBundle mainBundle] bundleIdentifier] stringByReplacingOccurrencesOfString:@"." withString:@"-"] lowercaseString];
    return [NSString stringWithFormat:@"_%@._tcp.", theType];
    }

+ (NSString *)defaultNetServiceName
    {
    NSString *theName = [NSString stringWithFormat:@"%@ on %@ (%d)",
        [[NSBundle mainBundle] infoDictionary][(__bridge NSString *)kCFBundleNameKey],
#if TARGET_OS_IPHONE == 1
        [[UIDevice currentDevice] name],
#else
        @"<some Macintosh>",
#endif
        getpid()
        ];
    return(theName);
    }

- (instancetype)initWithPort:(uint16_t)inPort
    {
    if ((self = [super init]) != NULL)
        {
        _netServiceDomain = [[[self class] defaultNetServiceDomain] copy];
        _netServiceType = [[[self class] defaultNetServiceType] copy];
        _netServiceName = [[[self class] defaultNetServiceName] copy];
        _port = inPort;

#if TARGET_OS_IPHONE == 1
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:[UIApplication sharedApplication]];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:[UIApplication sharedApplication]];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate:) name:UIApplicationWillTerminateNotification object:[UIApplication sharedApplication]];
#else
#endif
        }
    return self;
    }

- (instancetype)initWithNetServiceDomain:(NSString *)inDomain type:(NSString *)inType name:(NSString *)inName port:(uint16_t)inPort
    {
    if ((self = [self initWithPort:inPort]) != NULL)
        {
        if (inDomain != NULL)
            {
            _netServiceDomain = [inDomain copy];
            }
        if (inType != NULL)
            {
            _netServiceType = [inType copy];
            }
        if (inName != NULL)
            {
            _netServiceName = [inName copy];
            }
        }
    return self;
    }

- (void)dealloc
    {
    [self stopPublishing:NULL];
    }

#pragma mark -

- (void)startPublishing:(STYCompletionBlock)inResultHandler
    {
    if (self.publishing == YES)
        {
        if (inResultHandler != NULL)
            {
            inResultHandler(NULL);
            }
        return;
        }
        
    NSParameterAssert(self.netService == NULL);
    NSParameterAssert(self.netServiceType.length > 0);
    NSParameterAssert(self.netServiceName.length > 0);
    NSParameterAssert(self.port != 0);

    self.netService = [[NSNetService alloc] initWithDomain:self.netServiceDomain type:self.netServiceType name:self.netServiceName port:self.port];
    self.netService.sty_userInfo = [inResultHandler copy];
    self.netService.delegate = self;
    [self.netService publishWithOptions:0];

    self.publishing = YES;
    }

- (void)stopPublishing:(STYCompletionBlock)inResultHandler
    {
    if (self.publishing == NO)
        {
        if (inResultHandler != NULL)
            {
            inResultHandler(NULL);
            }
        return;
        }

    NSParameterAssert(self.netService != NULL);

    self.netService.sty_userInfo = inResultHandler;
    [self.netService stop];

    self.publishing = NO;
    }
    
#pragma mark -

- (void)netServiceDidPublish:(NSNetService *)sender
    {
    STYCompletionBlock theBlock = sender.sty_userInfo;
    if (theBlock)
        {
        theBlock(NULL);
        sender.sty_userInfo = NULL;
        }
    }

- (void)netService:(NSNetService *)sender didNotPublish:(NSDictionary *)errorDict
    {
    STYCompletionBlock theBlock = sender.sty_userInfo;
    if (theBlock)
        {
        theBlock([NSError errorWithDomain:kSTYErrorDomain code:-1 userInfo:NULL]);
        sender.sty_userInfo = NULL;
        }
    }
    
- (void)netServiceDidStop:(NSNetService *)sender
    {
    self.netService.delegate = NULL;
    self.netService = NULL;

    STYCompletionBlock theBlock = sender.sty_userInfo;
    if (theBlock)
        {
        theBlock(NULL);
        sender.sty_userInfo = NULL;
        }
    }

#pragma mark -

- (void)applicationDidEnterBackground:(NSNotification *)inNotification
    {
    if (self.publishing == YES)
        {

//UIBackgroundTaskIdentifier theIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithName:(NSString *)taskName expirationHandler:(void(^)(void))handler NS_AVAILABLE_IOS(7_0);
        
        self.resumeOnForegrounding = YES;
        
        [self stopPublishing:NULL];
        }
    }

- (void)applicationWillEnterForeground:(NSNotification *)inNotification
    {
    if (self.resumeOnForegrounding == YES)
        {
        [self startPublishing:NULL];
        }
    }

- (void)applicationWillTerminate:(NSNotification *)inNotification
    {
    [self stopPublishing:NULL];
    }

@end
