//
//  DITDataScanner+Message.h
//  DIT
//
//  Created by Jonathan Wight on 11/4/13.
//  Copyright (c) 2013 schwa.io. All rights reserved.
//

#import "DITDataScanner.h"

@class DITMessage;

@interface DITDataScanner (Message)

- (BOOL)scanMessage:(DITMessage *__autoreleasing *)outValue error:(NSError *__autoreleasing *)outError;

@end
