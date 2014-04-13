//
//  STYPeerBrowserViewController.m
//  Shanty Examples
//
//  Created by Jonathan Wight on 2/19/14.
//  Copyright (c) 2014 schwa.io. All rights reserved.
//

#import "STYPeerBrowserViewController.h"

#import <Shanty/Shanty.h>

@interface STYPeerBrowserViewController ()
@property (readwrite, nonatomic) STYServiceDiscoverer *discoverer;
@property (readwrite, nonatomic, assign) IBOutlet NSArrayController *servicesArrayController;
@end

@implementation STYPeerBrowserViewController

- (id)init
{
    self = [super initWithNibName:NSStringFromClass([self class]) bundle:[NSBundle bundleForClass:[self class]]];
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

        [peer open:^(NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{

                if ([self.delegate respondsToSelector:@selector(peerBrowser:didConnectToPeer:)])
                    {
                    [self.delegate peerBrowser:self didConnectToPeer:peer];
                    }
                });
            }];

        }];
    }

@end