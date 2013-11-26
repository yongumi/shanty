//
//  STYServer.h
//  Shanty
//
//  Created by Jonathan Wight on 10/29/13.
//  Copyright (c) 2013 schwa.io. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STYCompletionBlocks.h"

typedef BOOL (^STYServerConnectBlock)(CFSocketRef inSocket, NSData *inAddress, NSError **outError);

@interface STYServer : NSObject

@property (readwrite, nonatomic, copy) NSString *host;
@property (readwrite, nonatomic) unsigned short port;
@property (readwrite, nonatomic, copy) NSString *netServiceDomain;
@property (readwrite, nonatomic, copy) NSString *netServiceType;
@property (readwrite, nonatomic, copy) NSString *netServiceName;
@property (readwrite, nonatomic, strong) STYServerConnectBlock connectHandler;

- (void)startListening:(STYCompletionBlock)inResultHandler;
- (void)stopListening:(STYCompletionBlock)inResultHandler;

@end
