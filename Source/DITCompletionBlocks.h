//
//  DITCompletionBlocks.h
//  DIT
//
//  Created by Jonathan Wight on 11/5/13.
//  Copyright (c) 2013 schwa.io. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^DITCompletionBlock)(NSError *error);
typedef void (^DITResultBlock)(id result, NSError *error);
