//
//  STYMessageHandler.m
//  Shanty Examples
//
//  Created by Jonathan Wight on 12/10/13.
//  Copyright (c) 2013 schwa.io. All rights reserved.
//

#import "STYMessageHandler.h"

#import "STYMessage.h"

@interface STYMessageHandler ()
@property (readwrite, nonatomic) NSMutableDictionary *handlers;
@end

#pragma mark -

@implementation STYMessageHandler

- (id)init
    {
    if ((self = [super init]) != NULL)
        {
        _handlers = [NSMutableDictionary dictionary];

        [self _addSystemHandlers];
        }
    return self;
    }

- (void)addCommand:(NSString *)inCommand handler:(STYMessageBlock)inBlock;
    {
    [self.handlers setObject:inBlock forKey:inCommand];
    }

- (STYMessageBlock)handlerForMessage:(STYMessage *)inMessage
    {
    STYMessageBlock theHandler = self.handlers[inMessage.controlData[@"cmd"]];
    return(theHandler);
    }

- (void)_addSystemHandlers
    {
    __weak typeof(self) weak_self = self;
    [self addCommand:@"hello" handler:^(STYMessagingPeer *inPeer, STYMessage *inMessage, NSError **outError) {

        NSDictionary *theControlData = @{
            @"cmd": @"hello.reply",
            @"in-reply-to": inMessage.controlData[@"msgid"],
            };

        STYMessage *theResponse = [[STYMessage alloc] initWithControlData:theControlData metadata:NULL data:NULL];
        [inPeer sendMessage:theResponse replyBlock:NULL];

        NSLog(@"%@", inMessage);
        return(YES);
        }];
    [self addCommand:@"hello.reply" handler:^(STYMessagingPeer *inPeer, STYMessage *inMessage, NSError **outError) {
        NSLog(@"%@", inMessage);
        return(YES);
        }];

    }

@end
