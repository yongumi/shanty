//
//  STYDataScanner+Message.h
//  Shanty
//
//  Created by Jonathan Wight on 11/4/13.
//  Copyright (c) 2013 schwa.io. All rights reserved.
//

#import "STYDataScanner.h"

@class STYMessage;

@interface STYDataScanner (Message)

- (BOOL)scanMessage:(STYMessage *__autoreleasing *)outValue error:(NSError *__autoreleasing *)outError;

@end
