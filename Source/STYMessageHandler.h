//
//  STYMessageHandler.h
//  Shanty Examples
//
//  Created by Jonathan Wight on 12/10/13.
//  Copyright (c) 2013 schwa.io. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STYMessagingPeer.h"

@interface STYMessageHandler : NSObject

- (void)addCommand:(NSString *)inCommand handler:(STYMessageBlock)inBlock;

- (STYMessageBlock)handlerForMessage:(STYMessage *)inMessage;

@end
