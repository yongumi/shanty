//
//  STYNetService.h
//  STYNetBrowser
//
//  Created by Jonathan Wight on 11/4/14.
//  Copyright (c) 2014 schwa.io. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol STYNetServiceDelegate;

#pragma mark -

@interface STYNetService : NSObject

@property (readwrite, nonatomic, strong) dispatch_queue_t queue; // TODO: Only main queue supported for now.
@property (readonly, nonatomic, copy) NSString *domain;
@property (readonly, nonatomic, copy) NSString *type;
@property (readonly, nonatomic, copy) NSString *name;
@property (readonly, nonatomic, copy) NSString *hostName;
@property (readonly, nonatomic, copy) NSArray *addresses;
@property (readonly, nonatomic) NSInteger port;
@property (readonly, nonatomic, copy) NSData *TXTRecordData;

@property (readwrite, nonatomic, weak) id <STYNetServiceDelegate> delegate;

- (instancetype)initWithDomain:(NSString *)domain type:(NSString *)type name:(NSString *)name port:(NSInteger)port;
- (instancetype)initWithDomain:(NSString *)domain type:(NSString *)type name:(NSString *)name;
- (void)resolve;
- (void)publish:(BOOL)inLocalhostOnly;
- (void)stop;

@end

#pragma mark -

@interface STYNetService (Extras)
@property (readwrite, nonatomic, strong) id userInfo;
@property (readonly, nonatomic, copy) NSString *key; // Unique ID for service.
@end

#pragma mark -

@protocol STYNetServiceDelegate <NSObject>
@optional
- (void)netServiceWillPublish:(STYNetService *)sender;
- (void)netServiceDidPublish:(STYNetService *)sender;
- (void)netService:(STYNetService *)sender didNotPublish:(NSError *)error;

- (void)netServiceWillResolve:(STYNetService *)sender;
- (void)netServiceDidResolveAddress:(STYNetService *)sender;
- (void)netService:(STYNetService *)sender didNotResolve:(NSError *)error;
- (void)netServiceDidStop:(STYNetService *)sender;
@end
