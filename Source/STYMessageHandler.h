//
//  STYMessageHandler.h
//  Shanty Examples
//
//  Created by Jonathan Wight on 12/10/13.
//  Copyright (c) 2013 schwa.io. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STYPeer.h"

// TODO: Refactor this.
@interface STYMessageHandler : NSObject

- (void)addCommand:(NSString *)inCommand block:(STYMessageBlock)inBlock;

- (STYMessageBlock)blockForMessage:(STYMessage *)inMessage error:(NSError *__autoreleasing *)outError;

@end
