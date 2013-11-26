//
//  ShantyCompletionBlocks.h
//  Shanty
//
//  Created by Jonathan Wight on 11/5/13.
//  Copyright (c) 2013 schwa.io. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^ShantyCompletionBlock)(NSError *error);
typedef void (^ShantyResultBlock)(id result, NSError *error);
