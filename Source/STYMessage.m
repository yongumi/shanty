//
//  STYMessage.m
//  Shanty
//
//  Created by Jonathan Wight on 10/29/13.
//  Copyright (c) 2013 schwa.io. All rights reserved.
//

#import "STYMessage.h"

#import "STYDataScanner.h"

@interface STYMessage ()
@end

#pragma mark -

@implementation STYMessage

- (instancetype)initWithControlData:(NSDictionary *)inControlData metadata:(NSDictionary *)inMetadata data:(NSData *)inData
    {
    if ((self = [super init]) != NULL)
        {
        _controlData = inControlData;
        _metadata = inMetadata;
        _data = inData;
        }
    return self;
    }

- (instancetype)initWithDataBuffer:(NSData *)inDataBuffer error:(NSError *__autoreleasing *)outError
    {
    STYDataScanner *theScanner = [[STYDataScanner alloc] initWithData:inDataBuffer];
    theScanner.dataEndianness = DataScannerDataEndianness_Network;
    uint16_t theControlDataLength;
    if ([theScanner scan_uint16:&theControlDataLength error:outError] == NO)
        {
        self = NULL;
        return(NULL);
        }
    uint16_t theMetadataLength;
    if ([theScanner scan_uint16:&theMetadataLength error:outError] == NO)
        {
        self = NULL;
        return(NULL);
        }
    uint32_t theDataLength;
    if ([theScanner scan_uint32:&theDataLength error:outError] == NO)
        {
        self = NULL;
        return(NULL);
        }

    NSData *theControlData;
    if ([theScanner scanData:&theControlData length:theControlDataLength error:outError] == NO)
        {
        self = NULL;
        return(NULL);
        }
    NSDictionary *theControlDataObject = [[self class] decode:theControlData error:outError];

    NSData *theMetadata;
    if ([theScanner scanData:&theMetadata length:theMetadataLength error:outError] == NO)
        {
        self = NULL;
        return(NULL);
        }
    NSDictionary *theMetadataObject = [[self class] decode:theMetadata error:outError];

    NSData *theData;
    if ([theScanner scanData:&theData length:theDataLength error:outError] == NO)
        {
        self = NULL;
        return(NULL);
        }

    if ((self = [super init]) != NULL)
        {
        _controlData = theControlDataObject;
        _metadata = theMetadataObject;
        _data = theData;
        }
    return self;
    }

- (NSString *)description
    {
    return([NSString stringWithFormat:@"%@ (%@, %@, %@)", [super description], self.controlData, self.metadata, self.data]);
    }

+ (NSData *)encode:(NSDictionary *)inData error:(NSError *__autoreleasing *)outError
    {
    if (inData == NULL)
        {
        return(NULL);
        }
    NSData *theData = [NSJSONSerialization dataWithJSONObject:inData options:0 error:outError];
    // TODO zip...
    return(theData);
    }

+ (NSDictionary *)decode:(NSData *)inData error:(NSError *__autoreleasing *)outError
    {
    NSDictionary *theDictionary = [NSJSONSerialization JSONObjectWithData:inData options:0 error:outError];
    // TODO zip...
    return(theDictionary);
    }


- (NSData *)buffer:(NSError *__autoreleasing *)outError
    {
    NSMutableData *theBuffer = [NSMutableData data];

    u_int16_t theControlDataLength;
    NSData *theControlData = [[self class] encode:self.controlData error:NULL];;
    theControlDataLength = CFSwapInt16HostToBig(theControlData.length);
    [theBuffer appendBytes:&theControlDataLength length:sizeof(theControlDataLength)];

    u_int16_t theMetadataLength;
    NSData *theMetadata = [[self class] encode:self.metadata error:NULL];;
    theMetadataLength = CFSwapInt16HostToBig(theMetadata.length);
    [theBuffer appendBytes:&theMetadataLength length:sizeof(theMetadataLength)];

    u_int32_t theLength;
    NSData *theData = self.data;
    theLength = CFSwapInt32HostToBig((uint32_t)theData.length);
    [theBuffer appendBytes:&theLength length:sizeof(theLength)];

    [theBuffer appendData:theControlData];
    [theBuffer appendData:theMetadata];
    [theBuffer appendData:theData];

    return(theBuffer);
    }



@end
