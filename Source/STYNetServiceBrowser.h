//
//  STYNetServiceBrowser.h
//  shanty
//
//  Created by Jonathan Wight on 11/6/14.
//  Copyright (c) 2014 schwa.io. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol STYNetServiceBrowserDelegate;
@class STYNetService;

#pragma mark -

@interface STYNetServiceBrowser : NSObject

@property (readwrite, nonatomic, strong) dispatch_queue_t queue;
@property (readwrite, nonatomic) BOOL localOnly;
@property (readwrite, nonatomic, weak) id <STYNetServiceBrowserDelegate> delegate;

- (void)searchForServicesOfType:(NSString *)type inDomain:(NSString *)domainString;
- (void)stop;

@end

#pragma mark -

@protocol STYNetServiceBrowserDelegate <NSObject>
@optional
- (void)netServiceBrowserWillSearch:(STYNetServiceBrowser *)aNetServiceBrowser;
- (void)netServiceBrowserDidStopSearch:(STYNetServiceBrowser *)aNetServiceBrowser;
- (void)netServiceBrowser:(STYNetServiceBrowser *)aNetServiceBrowser didNotSearch:(NSError *)error;
- (void)netServiceBrowser:(STYNetServiceBrowser *)aNetServiceBrowser didFindService:(STYNetService *)aNetService moreComing:(BOOL)moreComing;
- (void)netServiceBrowser:(STYNetServiceBrowser *)aNetServiceBrowser didRemoveService:(STYNetService *)aNetService moreComing:(BOOL)moreComing;
@end
