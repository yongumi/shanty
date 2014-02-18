//
//  NIMMessagesWindowController.h
//  Shanty Examples
//
//  Created by Jonathan Wight on 2/18/14.
//  Copyright (c) 2014 schwa.io. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class STYMessage;
@class STYMessagingPeer;

@interface NIMMessagesWindowController : NSWindowController

@property (readonly, nonatomic) NSArray *messages;

- (instancetype)init;

@end
