//
//  STYServerPeer.m
//  shanty
//
//  Created by Jonathan Wight on 8/28/14.
//  Copyright (c) 2014 schwa.io. All rights reserved.
//

#import "STYServerPeer.h"

#import "STYMessageHandler.h"
#import "STYConstants.h"
#import "STYMessage.h"
#import "STYLogger.h"

@implementation STYServerPeer

- (id)init
    {
    if ((self = [super init]) != NULL)
        {
        }
    return self;
    }

- (void)prepareSystemHandler
    {
    [super prepareSystemHandler];

    __weak typeof(self) weak_self = self;

    // TODO: Technically we only need this if the peer is a server.
    [self.systemHandler addCommand:kSTYHelloCommand block:^(STYPeer *inPeer, STYMessage *inMessage, NSError **outError) {
        __strong typeof(self) strong_self = weak_self;
        if (strong_self == NULL)
            {
            STYLogWarning_(@"Self has been deallocated before block called.");
            return NO;
            }
        
        NSDictionary *theControlData = @{
            kSTYCommandKey: kSTYHelloReplyCommand,
            kSTYInReplyToKey: inMessage.controlData[kSTYMessageIDKey],
            };

        NSMutableDictionary *theExtraMetadata = [NSMutableDictionary dictionary];

        if (strong_self.requiresChallenge == YES)
            {
            theExtraMetadata[@"requiresChallenge"] = @(YES);
            }

        NSDictionary *theMetadata = [strong_self makeHelloMetadata:theExtraMetadata];

        STYMessage *theResponse = [[STYMessage alloc] initWithControlData:theControlData metadata:theMetadata data:NULL];
        [inPeer sendMessage:theResponse completion:NULL];

        NSCParameterAssert(strong_self.state == kSTYPeerStateHandshaking);
        strong_self.state = kSTYPeerStateReady;

        return YES;
        }];

    [theHandler addCommand:@"_secret" block:^(STYPeer *inPeer, STYMessage *inMessage, NSError **outError) {
        __strong typeof(self) strong_self = weak_self;

        if (strong_self.requiresChallenge == NO)
            {
            if (outError != NULL)
                {
                *outError = [NSError errorWithDomain:kSTYErrorDomain code:kSTYErrorCode_Unknown userInfo:NULL];
                }
            return NO;
            }

        if (strong_self.secret.length < 4)
            {
            if (outError != NULL)
                {
                *outError = [NSError errorWithDomain:kSTYErrorDomain code:kSTYErrorCode_Unknown userInfo:NULL];
                }

            return NO;
            }

        if ([strong_self.secret isEqualToString:inMessage.metadata[@"secret"]] == YES)
            {
            STYMessage *theResponse = [inMessage replyWithControlData:@{kSTYCommandKey: @"_secret.reply"} metadata:NULL data:NULL];
            [inPeer sendMessage:theResponse completion:NULL];
//            NSCParameterAssert(strong_self.state == kSTYPeerStateChallengeResponse);
            strong_self.state = kSTYPeerStateReady;
            }
        else
            {
            [self close:NULL];

            if (outError != NULL)
                {
                *outError = [NSError errorWithDomain:kSTYErrorDomain code:kSTYErrorCode_Unknown userInfo:NULL];
                }

            return NO;
            }
        return YES;
    }];

        
    return theHandler;
    }


@end
