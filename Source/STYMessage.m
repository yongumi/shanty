//
//  STYMessage.m
//  Shanty
//
//  Created by Jonathan Wight on 10/29/13.
//  Copyright (c) 2013 schwa.io. All rights reserved.
//

#import "STYMessage.h"

#import "STYConstants.h"

@interface STYMessage ()
@property (readwrite, nonatomic, copy) NSDictionary *controlData;
@property (readwrite, nonatomic, copy) NSDictionary *metadata;
@property (readwrite, nonatomic, copy) NSData *data;
@property (readwrite, nonatomic) STYMessageDirection direction;
@end

#pragma mark -

@implementation STYMessage

+ (NSData *)encode:(NSDictionary *)inData error:(NSError *__autoreleasing *)outError
    {
    if (inData == NULL)
        {
        return(NULL);
        }
    NSData *theData = [NSJSONSerialization dataWithJSONObject:inData options:0 error:outError];
    return(theData);
    }

+ (NSDictionary *)decode:(NSData *)inData error:(NSError *__autoreleasing *)outError
    {
    NSDictionary *theDictionary = [NSJSONSerialization JSONObjectWithData:inData options:0 error:outError];
    // TODO zip...
    return(theDictionary);
    }
    
+ (NSDictionary *)defaultControlData
    {
    return @{
        @"created": @([[NSDate date] timeIntervalSince1970]),
#if DEBUG == 1
        @"UUID": [[NSUUID UUID] UUIDString],
#endif
        };
    }

+ (NSDictionary *)controlDataWithCommand:(NSString *)inCommand replyTo:(STYMessage *)inMessage moreComing:(BOOL)inMoreComing extras:(NSDictionary *)inExtras
    {
    NSMutableDictionary *theControlData = [NSMutableDictionary dictionary];

    if (inCommand != NULL)
        {
        theControlData[kSTYCommandKey] = inCommand;
        }

    if (inMessage != NULL)
        {
        theControlData[kSTYInReplyToKey] = inMessage.controlData[kSTYMessageIDKey];
        }

    theControlData[kSTYMoreComing] = @(inMoreComing);

    if (inExtras.count > 0)
        {
        [theControlData addEntriesFromDictionary:inExtras];
        }

    return(theControlData);
    }


- (instancetype)initWithControlData:(NSDictionary *)inControlData metadata:(NSDictionary *)inMetadata data:(NSData *)inData
    {
    if ((self = [super init]) != NULL)
        {
        _direction = kSTYMessageDirection_Outgoing; // TODO - guessing direction is probably bad

        NSMutableDictionary *theControlData = [[self.class defaultControlData] mutableCopy];
        if (inControlData)
            {
            [theControlData addEntriesFromDictionary:inControlData];
            }

        _controlData = [theControlData copy];
        _metadata = [inMetadata copy];
        _data = [inData copy];
        
        NSLog(@"%@", self);
        }
    return self;
    }

- (NSString *)description
    {
    return([NSString stringWithFormat:@"%@ (%@, %@, %@)", [super description], self.controlData, self.metadata, self.data]);
    }

- (id)copyWithZone:(NSZone *)inZone
    {
    STYMessage *theCopy = [[STYMessage alloc] init];
    theCopy.controlData = self.controlData;
    theCopy.metadata = self.metadata;
    theCopy.data = self.data;

    theCopy->_direction = self.direction; // TODO - lazy
    return(theCopy);
    }

- (id)mutableCopyWithZone:(NSZone *)zone;
    {
    STYMessage *theCopy = [[STYMutableMessage alloc] init];
    theCopy.controlData = self.controlData;
    theCopy.metadata = self.metadata;
    theCopy.data = self.data;

    theCopy->_direction = self.direction; // TODO - lazy
    return(theCopy);
    }

#pragma mark -

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

- (instancetype)replyWithControlData:(NSDictionary *)inControlData metadata:(NSDictionary *)inMetadata data:(NSData *)inData
    {
    NSMutableDictionary *theControlData = [NSMutableDictionary dictionary];
    theControlData[kSTYInReplyToKey] = self.controlData[kSTYMessageIDKey];
    [theControlData addEntriesFromDictionary:inControlData];
    return([[[self class] alloc] initWithControlData:theControlData metadata:inMetadata data:inData]);
    }

- (NSString *)command
    {
    return(self.controlData[kSTYCommandKey]);
    }

- (NSInteger)messageID
    {
    return([self.controlData[kSTYMessageIDKey] integerValue]);
    }

- (BOOL)moreComing
    {
    return([self.controlData[kSTYMoreComing] boolValue]);
    }

@end

#pragma mark -

@implementation STYMutableMessage

- (void)setCommand:(NSString *)command
    {
    NSMutableDictionary *theControlData = [self.controlData mutableCopy];
    theControlData[kSTYCommandKey] = command;
    self.controlData = theControlData;
    }

- (void)setMessageID:(NSInteger)messageID
    {
    NSMutableDictionary *theControlData = [self.controlData mutableCopy];
    theControlData[kSTYMessageIDKey] = @(messageID);
    self.controlData = theControlData;
    }

@end
