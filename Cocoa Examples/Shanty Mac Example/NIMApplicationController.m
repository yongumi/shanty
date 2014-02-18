//
//  NIMAppDelegate.m
//  Shanty Mac Example
//
//  Created by Jonathan Wight on 11/6/13.
//  Copyright (c) 2013 schwa.io. All rights reserved.
//

#import "NIMApplicationController.h"

#import <Shanty/Shanty.h>

#import "NIMMessagesWindowController.h"
#import "NIMShantyPeerBrowserViewController.h"
#import "NIMPeersWindowController.h"
#import "NIMApplicationModel.h"

@interface NIMApplicationController () <NIMShantyPeerBrowserViewControllerDelegate, STYServerDelegate>
@property (readwrite, nonatomic, assign) IBOutlet NSWindow *window;
@property (readwrite, nonatomic, assign) IBOutlet NSPopover *browserPopover;
@property (readwrite, nonatomic) NIMMessagesWindowController *messagesWindowController;
@property (readwrite, nonatomic) NIMPeersWindowController *peersWindowController;
@property (readwrite, nonatomic, copy) NSString *serverNetServiceDomain;
@property (readwrite, nonatomic, copy) NSString *serverNetServiceType;
@property (readwrite, nonatomic, copy) NSString *serverNetServiceName;
@property (readwrite, nonatomic, copy) NSString *clientNetServiceDomain;
@property (readwrite, nonatomic, copy) NSString *clientNetServiceType;
@property (readwrite, nonatomic) BOOL serving;
@property (readwrite, nonatomic) STYServer *server;
@end

#pragma mark -

@implementation NIMApplicationController

static id gSharedInstance = NULL;

+ (instancetype)sharedInstance
    {
    return(gSharedInstance);
    }

- (id)init
    {
    if ((self = [super init]) != NULL)
        {
        _messagesWindowController = [[NIMMessagesWindowController alloc] init];
        _peersWindowController = [[NIMPeersWindowController alloc] init];

        _serverNetServiceDomain = [STYServer defaultNetServiceDomain];
        _serverNetServiceType = [STYServer defaultNetServiceType];
        _serverNetServiceName = [STYServer defaultNetServiceName];

        _clientNetServiceDomain = [STYServer defaultNetServiceDomain];
        _clientNetServiceType = [STYServer defaultNetServiceType];

        gSharedInstance = self;
        }
    return self;
    }

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
    {
    }

- (IBAction)startServing:(id)sender
    {
    if (self.serving == NO)
        {
        self.serving = YES;

        self.server = [[STYServer alloc] initWithNetServiceDomain:self.serverNetServiceDomain type:self.serverNetServiceType name:NULL];
        self.server.delegate = self;

        [self.server startListening:^(NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (error != NULL)
                    {
                    [self presentError:error];
                    self.serving = NO;
                    self.server = NULL;
                    }
                });
            }];
        }
    }

- (IBAction)stopServing:(id)sender
    {
    if (self.serving == YES)
        {
        self.serving = NO;

        [self.server stopListening:^(NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (error != NULL)
                    {
                    [self presentError:error];
                    }
                self.server = NULL;
                });
            }];
        }
    }

- (void)presentError:(NSError *)inError
    {
    [[NSApplication sharedApplication] presentError:inError];
    }

- (IBAction)toggleWindow:(id)sender
    {
    [self.messagesWindowController.window makeKeyAndOrderFront:sender];
    }

- (IBAction)togglePeersWindow:(id)sender
    {
    [self.peersWindowController.window makeKeyAndOrderFront:sender];
    }

- (IBAction)browse:(id)sender
    {
    NIMShantyPeerBrowserViewController *theBrowser = [[NIMShantyPeerBrowserViewController alloc] init];
    theBrowser.netServiceDomain = self.clientNetServiceDomain;
    theBrowser.netServiceType = self.clientNetServiceType;
    theBrowser.delegate = self;
    
    self.browserPopover.contentViewController = theBrowser;
    [self.browserPopover showRelativeToRect:[sender bounds] ofView:sender preferredEdge:0];
    }

- (void)peerBrowserViewControllerDidConnectToPeer:(NIMShantyPeerBrowserViewController *)inBrowserViewController;
    {
    [self.browserPopover close];
    }

- (void)server:(STYServer *)inServer peerDidConnect:(STYMessagingPeer *)inPeer;
    {
    inPeer.tap = ^(STYMessagingPeer *inPeer, STYMessage *inMessage, NSError **outError) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NIMApplicationModel sharedInstance] addMessage:inMessage peer:inPeer direction:@"Received"];
            });
        return(NO);
        };
    }

@end
