//
//  NIMApplicationModel.h
//  Shanty Examples
//
//  Created by Jonathan Wight on 2/19/14.
//  Copyright (c) 2014 schwa.io. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Shanty/Shanty.h>

@interface NIMApplicationModel : NSObject

@property (readonly, nonatomic) NSSet *peers;
@property (readonly, nonatomic) NSArray *messages;

+ (instancetype)sharedInstance;

- (void)addPeer:(STYMessagingPeer *)inPeer;
- (void)removePeer:(STYMessagingPeer *)inPeer;

- (void)addMessage:(STYMessage *)inMessage peer:(STYMessagingPeer *)inPeer direction:(NSString *)inDirection;


@end
