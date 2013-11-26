//
//  ShantyServer.h
//  Shanty
//
//  Created by Jonathan Wight on 10/29/13.
//  Copyright (c) 2013 schwa.io. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ShantyCompletionBlocks.h"

typedef BOOL (^ConnectBlock)(CFSocketRef inSocket, NSData *inAddress, NSError **outError);

@interface ShantyServer : NSObject

@property (readwrite, nonatomic, copy) NSString *host;
@property (readwrite, nonatomic) unsigned short port;
@property (readwrite, nonatomic, copy) NSString *netServiceDomain;
@property (readwrite, nonatomic, copy) NSString *netServiceType;
@property (readwrite, nonatomic, copy) NSString *netServiceName;
@property (readwrite, nonatomic, strong) ConnectBlock connectHandler;

- (void)startListening:(ShantyCompletionBlock)inResultHandler;
- (void)stopListening:(ShantyCompletionBlock)inResultHandler;

@end
