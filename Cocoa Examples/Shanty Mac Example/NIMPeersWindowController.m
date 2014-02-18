//
//  NIMPeersWindowViewControllerWindowController.m
//  Shanty Examples
//
//  Created by Jonathan Wight on 2/19/14.
//  Copyright (c) 2014 schwa.io. All rights reserved.
//

#import "NIMPeersWindowController.h"

#import <Shanty/Shanty.h>

#import "NIMApplicationModel.h"
#import "NSObject+KVOBlock.h"

@interface NIMPeersWindowController ()
@property (readwrite, nonatomic, assign) IBOutlet NSArrayController *peersArrayController;
@property (readwrite, nonatomic) id observer;
@end

#pragma mark -

@implementation NIMPeersWindowController

- (instancetype)init
    {
    if ((self = [super initWithWindowNibName:NSStringFromClass([self class])]) != NULL)
        {
        _observer = [[NIMApplicationModel sharedInstance] addKVOBlockForKeyPath:@"peers" options:0 handler:^(NSString *keyPath, id object, NSDictionary *change) {
            [self willChangeValueForKey:@"peers"];
            [self didChangeValueForKey:@"peers"];
            }];
        }
    return(self);
    }

- (void)dealloc
    {
    [[NIMApplicationModel sharedInstance] removeKVOBlockForToken:_observer];
    }

- (NSSet *)peers
    {
    return([NIMApplicationModel sharedInstance].peers);
    }

- (IBAction)disconnect:(id)sender
    {
    STYMessagingPeer *theSelectedService = [self.peersArrayController.selectedObjects lastObject];

    [theSelectedService close:^(NSError *error) {
        NSLog(@"CLOSED: %@", error);
        }];
    }

- (IBAction)reconnect:(id)sender
    {
//    STYMessagingPeer *theSelectedService = [self.peersArrayController.selectedObjects lastObject];
//
//    [theSelectedService reconnect:^(NSError *error) {
//        NSLog(@"RECONNECT: %@", error);
//        }];
    }


- (IBAction)send:(id)sender
    {
    }



@end
