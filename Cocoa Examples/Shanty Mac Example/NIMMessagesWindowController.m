//
//  NIMMessagesWindowController.m
//  Shanty Examples
//
//  Created by Jonathan Wight on 2/18/14.
//  Copyright (c) 2014 schwa.io. All rights reserved.
//

#import "NIMMessagesWindowController.h"

#import "NIMApplicationModel.h"
#import "NSObject+KVOBlock.h"

@interface NIMMessagesWindowController ()
@property (readwrite, nonatomic) id observer;
@end

#pragma mark -

@implementation NIMMessagesWindowController

- (instancetype)init
    {
    if ((self = [super initWithWindowNibName:NSStringFromClass([self class])]) != NULL)
        {
        _observer = [[NIMApplicationModel sharedInstance] addKVOBlockForKeyPath:@"messages" options:0 handler:^(NSString *keyPath, id object, NSDictionary *change) {
            [self willChangeValueForKey:@"messages"];
            [self didChangeValueForKey:@"messages"];
            }];
        }
    return(self);
    }

- (void)dealloc
    {
    [[NIMApplicationModel sharedInstance] removeKVOBlockForToken:_observer];
    }

- (NSArray *)messages
    {
    return([NIMApplicationModel sharedInstance].messages);
    }

@end
