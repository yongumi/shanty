//
//  STYPeerBrowserViewController.h
//  Shanty Examples
//
//  Created by Jonathan Wight on 2/19/14.
//  Copyright (c) 2014 schwa.io. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class STYPeer;

@protocol STYPeerBrowserViewControllerDelegate;

@interface STYPeerBrowserViewController : NSViewController

@property (readwrite, nonatomic, copy) NSString *netServiceDomain;
@property (readwrite, nonatomic, copy) NSString *netServiceType;
@property (readwrite, nonatomic, weak) id <STYPeerBrowserViewControllerDelegate> delegate;

- (instancetype)init;

- (IBAction)connect:(id)sender;
- (IBAction)cancel:(id)sender;

@end

#pragma mark -

@protocol STYPeerBrowserViewControllerDelegate <NSObject>
@optional
- (void)peerBrowser:(STYPeerBrowserViewController *)inBrowserViewController didCreatePeer:(STYPeer *)inPeer;
- (void)peerBrowser:(STYPeerBrowserViewController *)inBrowserViewController willConnectToPeer:(STYPeer *)inPeer;
- (void)peerBrowser:(STYPeerBrowserViewController *)inBrowserViewController didConnectToPeer:(STYPeer *)inPeer;
- (void)peerBrowser:(STYPeerBrowserViewController *)inBrowserViewController didfailToConnect:(NSError *)inError;
- (void)peerBrowserDidCancel:(STYPeerBrowserViewController *)inBrowserViewController;
@end