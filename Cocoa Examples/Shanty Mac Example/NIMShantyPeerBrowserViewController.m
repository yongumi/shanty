//
//  NIMShantyPeerBrowserViewController.m
//  Shanty Examples
//
//  Created by Jonathan Wight on 2/19/14.
//  Copyright (c) 2014 schwa.io. All rights reserved.
//

#import "NIMShantyPeerBrowserViewController.h"

#import <Shanty/Shanty.h>

#import "NIMApplicationModel.h"

@interface NIMShantyPeerBrowserViewController ()
@property (readwrite, nonatomic) STYServiceDiscoverer *discoverer;
@property (readwrite, nonatomic, assign) IBOutlet NSArrayController *servicesArrayController;
@end

@implementation NIMShantyPeerBrowserViewController

- (id)init
{
    self = [super initWithNibName:NSStringFromClass([self class]) bundle:NULL];
    if (self) {
    }
    return self;
}

- (void)loadView
    {
    [super loadView];

    self.discoverer = [[STYServiceDiscoverer alloc] initWithType:self.netServiceType domain:self.netServiceDomain];
    [self.discoverer start];
    }

- (IBAction)connect:(id)sender
    {
    NSNetService *theSelectedService = [self.servicesArrayController.selectedObjects lastObject];

    [self.discoverer connectToService:theSelectedService openPeer:NO completion:^(STYMessagingPeer *peer, NSError *error) {

        peer.tap = ^(STYMessagingPeer *inPeer, STYMessage *inMessage, NSError **outError) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NIMApplicationModel sharedInstance] addMessage:inMessage peer:inPeer direction:@"?"];
                });
            return(NO);
            };

        [peer open:^(NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NIMApplicationModel sharedInstance] addPeer:peer];

                if ([self.delegate respondsToSelector:@selector(peerBrowserViewControllerDidConnectToPeer:)])
                    {
                    [self.delegate peerBrowserViewControllerDidConnectToPeer:self];
                    }
                });
            }];

        }];
    }

@end
