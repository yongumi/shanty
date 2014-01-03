//
//  STYMessageHandler.m
//  Shanty Examples
//
//  Created by Jonathan Wight on 12/10/13.
//  Copyright (c) 2013 schwa.io. All rights reserved.
//

#import "STYMessageHandler.h"

#import "STYMessage.h"
#import "STYConstants.h"

@interface STYMessageHandler ()
@property (readwrite, nonatomic) NSMutableArray *handlers;
@end

#pragma mark -

@implementation STYMessageHandler

- (instancetype)init
    {
    if ((self = [super init]) != NULL)
        {
        _handlers = [NSMutableArray array];

        [self _addSystemHandlers];
        }
    return self;
    }

- (void)addCommand:(NSString *)inCommand handler:(STYMessageBlock)inBlock;
    {
    [self.handlers insertObject:@[ inCommand ?: [NSNull null], inBlock ] atIndex:0];
    }

- (STYMessageBlock)handlerForMessage:(STYMessage *)inMessage
    {
    for (NSArray *theHandler in self.handlers)
        {
        id theCommand = theHandler[0];
        STYMessageBlock theBlock = theHandler[1];
        if (theCommand == [NSNull null] || [inMessage.controlData[kSTYCommandKey] isEqualToString:theCommand])
            {
            return(theBlock);
            }
        }

    return(NULL);
    }

- (void)_addSystemHandlers
    {
    [self addCommand:kSTYHelloCommand handler:^(STYMessagingPeer *inPeer, STYMessage *inMessage, NSError **outError) {

        NSDictionary *theControlData = @{
            kSTYCommandKey: kSTYHelloReplyCommand,
            kSTYInReplyToKey: inMessage.controlData[kSTYMessageIDKey],
            };

        STYMessage *theResponse = [[STYMessage alloc] initWithControlData:theControlData metadata:NULL data:NULL];
        [inPeer sendMessage:theResponse replyBlock:NULL];

        NSLog(@"%@", inMessage);
        return(YES);
        }];
    [self addCommand:kSTYHelloReplyCommand handler:^(STYMessagingPeer *inPeer, STYMessage *inMessage, NSError **outError) {
        NSLog(@"%@", inMessage);
        return(YES);
        }];

    }

@end
