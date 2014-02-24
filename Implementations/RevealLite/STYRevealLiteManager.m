//
//  STYRevealLiteManager.m
//  EmbeddingTest
//
//  Created by Jonathan Wight on 2/13/14.
//  Copyright (c) 2014 schwa. All rights reserved.
//

#import "STYRevealLiteManager.h"

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#endif /* TARGET_OS_IPHONE */

#import <Shanty/Shanty.h>

@interface STYRevealLiteManager () <STYServerDelegate>
@property (readwrite, nonatomic) STYServer *server;
@end

#pragma mark -

@implementation STYRevealLiteManager

#if TARGET_OS_IPHONE
+ (void)load
    {
    [(STYRevealLiteManager *)[self sharedInstance] start];
    }
#endif /* TARGET_OS_IPHONE */

static id gSharedInstance = NULL;

+ (NSString *)netServiceType
    {
    return(@"_io-schwa-reveallite._tcp");
    }

+ (instancetype)sharedInstance
    {
    static dispatch_once_t sOnceToken = 0;
    dispatch_once(&sOnceToken, ^{
        gSharedInstance = [[self alloc] init];
        });
    return(gSharedInstance);
    }

#if TARGET_OS_IPHONE
- (void)start
    {
    self.server = [[STYServer alloc] init];
    self.server.netServiceType = [STYRevealLiteManager netServiceType];
    self.server.delegate = self;

    __weak typeof(self) weak_self = self;

    [self.server.messageHandler addCommand:@"io.schwa.reveallite" handler:^BOOL(STYMessagingPeer *inPeer, STYMessage *inMessage, NSError *__autoreleasing *outError) {

        __strong typeof(weak_self) strong_self = weak_self;
        if (strong_self == NULL)
            {
            return(NO);
            }

        dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"INSPECT");

        UIWindow *theMainWindow = [UIApplication sharedApplication].keyWindow;

            _Walk(NULL, theMainWindow, @"subviews", YES, ^BOOL (id parent, id child) {

                NSDictionary *theMetadata = @{
                    @"Content-Type": @"application/json",
                    @"Filename": [[strong_self _pathForView:child root:theMainWindow] stringByAppendingPathComponent:@"view.json"],
                    };
                NSDictionary *theDictionary = [strong_self _dictionaryForView:child];

                STYMessage *theReply = NULL;

                NSData *theDictionaryData = [NSJSONSerialization dataWithJSONObject:theDictionary options:NSJSONWritingPrettyPrinted error:NULL];

    //            NSLog(@"%@ %@", NSStringFromClass([child class]), [strong_self pathForView:child root:theMainWindow]);

                theReply = [inMessage replyWithControlData:[STYMessage controlDataWithCommand:@"io.schwa.view-dictionary" replyTo:inMessage moreComing:YES extras:NULL] metadata:theMetadata data:theDictionaryData];
                [inPeer sendMessage:theReply completion:NULL];

                BOOL theIncludeChildrenFlag = [child isKindOfClass:[UIControl class]] == NO;

                NSData *theImageData = [strong_self _imageDataForView:child hideChildren:theIncludeChildrenFlag];
                if (theImageData)
                    {
                    theMetadata = @{
                        @"Content-Type": @"image/png",
                        @"Filename": [[strong_self _pathForView:child root:theMainWindow] stringByAppendingPathComponent:@"snapshot.png"],
                        };
                    theReply = [inMessage replyWithControlData:[STYMessage controlDataWithCommand:@"io.schwa.view-snapshot" replyTo:inMessage moreComing:YES extras:NULL] metadata:theMetadata data:theImageData];

                    [inPeer sendMessage:theReply completion:NULL];
                    }

                return(theIncludeChildrenFlag);
                });

            STYMessage *theMessage = [inMessage replyWithControlData:[STYMessage controlDataWithCommand:@"done" replyTo:inMessage moreComing:NO extras:NULL] metadata:NULL data:NULL];
            [inPeer sendMessage:theMessage completion:NULL];
            });


        return(YES);
        }];


    [self.server startListening:^(NSError *error) {
        NSLog(@"Listening");
        }];
    }

- (NSDictionary *)_dictionaryForView:(UIView *)inView
    {
    NSMutableDictionary *theDictionary = [NSMutableDictionary dictionary];
    theDictionary[@"className"] = NSStringFromClass([inView class]);
    theDictionary[@"address"] = [NSString stringWithFormat:@"0x%016llX", (uint64_t)(__bridge void *)inView];

    theDictionary[@"frame.origin.x"] = @(inView.frame.origin.x);
    theDictionary[@"frame.origin.y"] = @(inView.frame.origin.y);
    theDictionary[@"frame.size.width"] = @(inView.frame.size.width);
    theDictionary[@"frame.size.height"] = @(inView.frame.size.height);

    theDictionary[@"bounds.origin.x"] = @(inView.bounds.origin.x);
    theDictionary[@"bounds.origin.y"] = @(inView.bounds.origin.y);
    theDictionary[@"bounds.size.width"] = @(inView.bounds.size.width);
    theDictionary[@"bounds.size.height"] = @(inView.bounds.size.height);

    if (inView.backgroundColor != NULL)
        {
        theDictionary[@"backgroundColor"] = NSDictionaryFromUIColor(inView.backgroundColor);
        }
    if (inView.superview != NULL)
        {
        theDictionary[@"index"] = @([inView.superview.subviews indexOfObject:inView]);
        theDictionary[@"parentAddress"] = [NSString stringWithFormat:@"0x%016llX", (uint64_t)(__bridge void *)inView.superview];
        }
    if (inView.accessibilityLabel != NULL)
        {
        theDictionary[@"accessibilityLabel"] = inView.accessibilityLabel;
        }

    return(theDictionary);
    }

- (NSData *)_imageDataForView:(UIView *)inView hideChildren:(BOOL)inHideChildren
    {
    if (inView.frame.size.width == 0 || inView.frame.size.height == 0)
        {
        return(NULL);
        }

    NSArray *theChildren = NULL;

    if (inHideChildren == YES)
        {
        theChildren = [inView.subviews copy];;

        for (UIView *theChild in theChildren)
            {
            [theChild removeFromSuperview];
            }
        }

    CGSize theSize = inView.frame.size;
    UIImage *theImage = NULL;
    UIGraphicsBeginImageContext(theSize);
    if (UIGraphicsGetCurrentContext())
        {
        [inView drawViewHierarchyInRect:(CGRect){ .size = theSize } afterScreenUpdates:YES];
        theImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        }
    else
        {
        NSLog(@"Could not make image context!");
        }

    if (inHideChildren == YES)
        {
        for (UIView *theChild in theChildren)
            {
            [inView addSubview:theChild];
            }
        }


    NSData *theData = UIImagePNGRepresentation(theImage);
    return(theData);
    }

- (NSString *)_pathForView:(UIView *)inView root:(UIView *)inRoot
    {
    if (inView == inRoot)
        {
        return(@"root");
        }
    else
        {
        NSString *thePath = [self _pathForView:inView.superview root:inRoot];
        thePath = [thePath stringByAppendingPathComponent:[@([inView.superview.subviews indexOfObject:inView]) stringValue]];
        return(thePath);
        }
    }

#pragma mark -

NSDictionary *NSDictionaryFromUIColor(UIColor *color)
    {
    CGFloat red, green, blue, alpha, white, hue, saturation, brightness;

    if ([color getRed:&red green:&green blue:&blue alpha:&alpha] == YES)
        {
        return(@{ @"red": @(red), @"green": @(green), @"blue": @(blue), @"alpha": @(alpha) });
        }
    else if ([color getWhite:&white alpha:&alpha] == YES)
        {
        return(@{ @"white": @(white), @"alpha": @(alpha) });
        }
    else if ([color getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha] == YES)
        {
        return(@{ @"hue": @(hue), @"saturation": @(saturation), @"brightness": @(brightness), @"alpha": @(alpha) });
        }
    else
        {
        return(@{});
        }
    }
#endif /* TARGET_OS_IPHONE */

static void _Walk(id parent, id object, NSString *childKey, BOOL reversed, BOOL (^inBlock)(id parent, id child))
    {
    BOOL theStopFlag = inBlock(parent, object);
    if (theStopFlag == NO)
        {
        return;
        }

    NSArray *theChildren = [object valueForKey:childKey];
    if (reversed == YES)
        {
        theChildren = [[theChildren reverseObjectEnumerator] allObjects];
        }

    for (id theChild in theChildren)
        {
        _Walk(object, theChild, childKey, reversed, inBlock);
        }
    }


- (void)fetch:(STYMessagingPeer *)inPeer toDirectory:(NSURL *)inURL completion:(void (^)(NSError *))completion
    {
    STYMessage *theMessage = [[STYMessage alloc] initWithCommand:@"io.schwa.reveallite" metadata:NULL data:NULL];
    [inPeer sendMessage:theMessage replyHandler:^BOOL(STYMessagingPeer *inPeer, STYMessage *inMessage, NSError *__autoreleasing *outError) {
        if (inMessage.metadata[@"Filename"] != NULL)
            {
            NSURL *theURL = [inURL URLByAppendingPathComponent:inMessage.metadata[@"Filename"]];

            NSURL *theDirectory = [theURL URLByDeletingLastPathComponent];
            if ([theDirectory checkResourceIsReachableAndReturnError:NULL] == NO)
                {
                [[NSFileManager defaultManager] createDirectoryAtURL:theDirectory withIntermediateDirectories:YES attributes:NULL error:NULL];
                }


            [inMessage.data writeToURL:theURL options:0 error:NULL];
            }


        if (inMessage.moreComing == NO)
            {
            completion(NULL);
            }


        return(YES);
        } completion:NULL];
    }

@end
