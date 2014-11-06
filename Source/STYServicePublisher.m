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
#import "STYConstants.h"
#import "STYLogger.h"
#import "STYNetService.h"

@interface STYServicePublisher () <STYNetServiceDelegate>
@property (readwrite, nonatomic) STYNetService *netService;
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

- (instancetype)initWithNetServiceDomain:(NSString *)inDomain type:(NSString *)inType name:(NSString *)inName port:(uint16_t)inPort
    {
    if ((self = [self init]) != NULL)
        {
        _netServiceDomain = [(inDomain ?: [[self class] defaultNetServiceDomain]) copy];
        _netServiceType = [(inType ?: [[self class] defaultNetServiceType]) copy];
        _netServiceName = [(inName ?: [[self class] defaultNetServiceName]) copy];
        _netServiceSubtypes = @[];
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

- (instancetype)initWithPort:(uint16_t)inPort
    {
    if ((self = [self initWithNetServiceDomain:NULL type:NULL name:NULL port:inPort]) != NULL)
        {
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

    if (IsNetServiceNameValid(self.netServiceType) == NO)
        {
        STYLogWarning_(@"\"%@\" is an invalid DNSSD type", self.netServiceType);
        }

    if (self.netServiceName.length > 63)
        {
        STYLogWarning_(@"\"%@\" is an invalid DNSSD name", self.netServiceName);
        }

    self.netService = [[STYNetService alloc] initWithDomain:self.netServiceDomain type:self.netServiceType name:self.netServiceName port:self.port];
    self.netService.userInfo = [inResultHandler copy];
    self.netService.delegate = self;
    [self.netService publish:self.localhostOnly];
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

    self.netService.userInfo = inResultHandler;
    [self.netService stop];
    self.publishing = NO;
    }
    
#pragma mark -

- (void)netServiceDidPublish:(STYNetService *)sender
    {
    STYCompletionBlock theBlock = sender.userInfo;
    if (theBlock)
        {
        theBlock(NULL);
        sender.userInfo = NULL;
        }
    }

- (void)netService:(STYNetService *)sender didNotPublish:(NSError *)error
    {
    STYCompletionBlock theBlock = sender.userInfo;
    if (theBlock)
        {
        theBlock(error);
        sender.userInfo = NULL;
        }
    }
    
- (void)netServiceDidStop:(STYNetService *)sender
    {
    self.netService.delegate = NULL;
    self.netService = NULL;

    STYCompletionBlock theBlock = sender.userInfo;
    if (theBlock)
        {
        theBlock(NULL);
        sender.userInfo = NULL;
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

#pragma mark -

static BOOL IsNetServiceNameValid(NSString *inName)
    {
    NSRegularExpression *theExpression = [NSRegularExpression regularExpressionWithPattern:@"^_([0-9a-z\\-]{1,10})\\.(_tcp|_udp)$" options:NSRegularExpressionCaseInsensitive error:NULL];
    return [theExpression firstMatchInString:inName options:0 range:(NSRange){ .length = inName.length }] != NULL;
   
    }

@end
