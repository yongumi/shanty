//
//  STYDataScanner+Message.m
//  Shanty
//
//  Created by Jonathan Wight on 11/4/13.
//  Copyright (c) 2013 schwa.io. All rights reserved.
//

#import "STYDataScanner+Message.h"

#import "STYMessage.h"

@implementation STYDataScanner (Message)

- (BOOL)scanMessage:(STYMessage *__autoreleasing *)outValue error:(NSError *__autoreleasing *)outError
    {
    [self pushRange];

    uint16_t theControlDataLength;
    if ([self scan_uint16:&theControlDataLength error:outError] == NO)
        {
        self.range = [self popRange];
        return(NO);
        }
    uint16_t theMetadataLength;
    if ([self scan_uint16:&theMetadataLength error:outError] == NO)
        {
        self.range = [self popRange];
        return(NO);
        }
    uint32_t theDataLength;
    if ([self scan_uint32:&theDataLength error:outError] == NO)
        {
        self.range = [self popRange];
        return(NO);
        }

    NSData *theControlData;
    if ([self scanData:&theControlData length:theControlDataLength error:outError] == NO)
        {
        self.range = [self popRange];
        return(NO);
        }
    NSDictionary *theControlDataObject = [[STYMessage class] decode:theControlData error:outError];

    NSData *theMetadata;
    if ([self scanData:&theMetadata length:theMetadataLength error:outError] == NO)
        {
        self.range = [self popRange];
        return(NO);
        }
    NSDictionary *theMetadataObject = [[STYMessage class] decode:theMetadata error:outError];

    NSData *theData;
    if ([self scanData:&theData length:theDataLength error:outError] == NO)
        {
        self.range = [self popRange];
        return(NO);
        }

    if (outValue)
        {
        STYMutableMessage *theMessage = [[STYMutableMessage alloc] initWithControlData:theControlDataObject metadata:theMetadataObject data:theData];
        theMessage.direction = kSTYMessageDirection_Incoming; // TODO this is a bit fake...
        *outValue = theMessage;
        }

    [self popRange];

    return(YES);
    }

@end
