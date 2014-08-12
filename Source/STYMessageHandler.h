//
//  STYMessageHandler.h
//  Shanty Examples
//
//  Created by Jonathan Wight on 12/10/13.
//  Copyright (c) 2013 schwa.io. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STYPeer.h"

// Misnamed. This isn't a handler. It's a "message handler group"
@interface STYMessageHandler : NSObject

- (void)addCommand:(NSString *)inCommand block:(STYMessageBlock)inBlock;

- (NSArray *)blocksForMessage:(STYMessage *)inMessage;

@end
