//
//  ShantyDataScanner+Message.h
//  Shanty
//
//  Created by Jonathan Wight on 11/4/13.
//  Copyright (c) 2013 schwa.io. All rights reserved.
//

#import "ShantyDataScanner.h"

@class ShantyMessage;

@interface ShantyDataScanner (Message)

- (BOOL)scanMessage:(ShantyMessage *__autoreleasing *)outValue error:(NSError *__autoreleasing *)outError;

@end
