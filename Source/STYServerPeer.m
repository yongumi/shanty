//
//  STYServerPeer.m
//  shanty
//
//  Created by Jonathan Wight on 8/28/14.
//  Copyright (c) 2014 schwa.io. All rights reserved.
//

#import "STYServerPeer.h"

@implementation STYServerPeer

- (id)init
    {
    if ((self = [super init]) != NULL)
        {
        self.systemHandler = [self _makeSystemHandler];
        }
    return self;
    }

- (STYMessageHandler *)_makeSystemHandler
    {
    STYMessageHandler *theHandler = [[STYMessageHandler alloc] init];

    __weak typeof(self) weak_self = self;

    // TODO: Technically we only need this if the peer is a server.
    [theHandler addCommand:kSTYHelloCommand block:^(STYPeer *inPeer, STYMessage *inMessage, NSError **outError) {
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

        NSDictionary *theMetadata = [self makeHelloMetadata:@{ @"requiresChallenge": @(YES) }];
//        NSDictionary *theMetadata = [self _makeHelloMetadata:NULL];

        STYMessage *theResponse = [[STYMessage alloc] initWithControlData:theControlData metadata:theMetadata data:NULL];
        [inPeer sendMessage:theResponse completion:NULL];

        NSCParameterAssert(strong_self.state == kSTYPeerStateHandshaking);
        strong_self.state = kSTYPeerStateReady;

        return YES;
        }];

    [theHandler addCommand:@"_secret" block:^(STYPeer *inPeer, STYMessage *inMessage, NSError **outError) {
        __strong typeof(self) strong_self = weak_self;

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
            }
        
    
    
        return YES;
    }];

        
    return theHandler;
    }


@end
