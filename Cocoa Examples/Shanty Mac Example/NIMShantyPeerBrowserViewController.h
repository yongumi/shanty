//
//  NIMShantyPeerBrowserViewController.h
//  Shanty Examples
//
//  Created by Jonathan Wight on 2/19/14.
//  Copyright (c) 2014 schwa.io. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol NIMShantyPeerBrowserViewControllerDelegate;

@interface NIMShantyPeerBrowserViewController : NSViewController

@property (readwrite, nonatomic, copy) NSString *netServiceDomain;
@property (readwrite, nonatomic, copy) NSString *netServiceType;
@property (readwrite, nonatomic, weak) id <NIMShantyPeerBrowserViewControllerDelegate> delegate;

@end

#pragma mark -

@protocol NIMShantyPeerBrowserViewControllerDelegate <NSObject>
- (void)peerBrowserViewControllerDidConnectToPeer:(NIMShantyPeerBrowserViewController *)inBrowserViewController;
@end