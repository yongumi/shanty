//
//  STYCompletionBlocks.h
//  Shanty
//
//  Created by Jonathan Wight on 11/5/13.
//  Copyright (c) 2013 schwa.io. All rights reserved.
//

#import <Foundation/Foundation.h>

// TODO: Rename to STYBlockTypes.h???

@class STYPeer;
@class STYMessage;

typedef void (^STYCompletionBlock)(NSError *error);
typedef void (^STYResultBlock)(id result, NSError *error);
typedef BOOL (^STYMessageBlock)(STYPeer *inPeer, STYMessage *inMessage, NSError **outError);
