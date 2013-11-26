//
//  DITDataScanner.m
//  DIT
//
//  Created by Jonathan Wight on 11/4/13.
//  Copyright (c) 2013 schwa.io. All rights reserved.
//

#import "DITDataScanner.h"

@interface DITDataScanner ()
@property (readwrite, nonatomic, copy) NSData *data;
@property (readwrite, nonatomic) NSMutableArray *rangeStack;
@end

#pragma mark -

@implementation DITDataScanner

- (instancetype)init
    {
    if ((self = [super init]) != NULL)
        {
        _mode = DataScannerMode_Binary;
        _dataEndianness = DataScannerDataEndianness_Native;
        }
    return self;
    }

- (instancetype)initWithData:(NSData *)inData;
    {
    if ((self = [self init]) != NULL)
        {
        _data = inData;
        _range = (NSRange){ .location = 0, .length = [_data length] };
        }
    return self;
    }

#pragma mark -

- (NSData *)remainingData
    {
    return([self.data subdataWithRange:self.range]);
    }

- (void)feedData:(NSData *)inData;
    {
    NSMutableData *theData = [self.data mutableCopy] ?: [NSMutableData data];
    [theData appendData:inData];
    self.data = theData;
    self.range = (NSRange){ .location = self.range.location, .length = self.range.length + [inData length] };
    }

#pragma mark -

- (void)pushRange
    {
    if (_rangeStack == NULL)
        {
        _rangeStack = [NSMutableArray array];
        }

    [_rangeStack addObject:[NSValue valueWithRange:self.range]];
    }

- (NSRange)popRange
    {
    NSRange theRange = [[_rangeStack lastObject] rangeValue];
    [_rangeStack removeLastObject];
    return(theRange);
    }

#pragma mark -

- (BOOL)scanData:(NSData *__autoreleasing *)outValue length:(NSUInteger)inLength error:(NSError *__autoreleasing *)outError
    {
    if (_range.length < inLength)
        {
        [self _makeError:outError code:-1];
        return(NO);
        }

    NSData *theData = NULL;
    if (_shouldCopyData == NO)
        {
        theData = [NSData dataWithBytesNoCopy:(void *)([self.data bytes] + self.range.location) length:inLength freeWhenDone:NO];
        }
    else
        {
        theData = [NSData dataWithBytes:(void *)([self.data bytes] + self.range.location) length:inLength];
        }

    self.range = (NSRange){ .location = self.range.location + inLength, .length = self.range.length - inLength };

    if (outValue)
        {
        *outValue = theData;
        }

    return(YES);
    }

- (BOOL)scan_uint16:(uint16_t *)outValue error:(NSError *__autoreleasing *)outError
    {
    return([self scan_uint16_binary:outValue error:outError]);
    }

- (BOOL)scan_uint32:(uint32_t *)outValue error:(NSError *__autoreleasing *)outError
    {
    return([self scan_uint32_binary:outValue error:outError]);
    }

#pragma mark -

- (BOOL)scan_uint16_binary:(uint16_t *)outValue error:(NSError *__autoreleasing *)outError
    {
    if (_range.length < sizeof(*outValue))
        {
        [self _makeError:outError code:-1];
        return(NO);
        }

    uint16_t theValue = *(uint16_t *)((const char *)[_data bytes] + _range.location);
    switch (self.dataEndianness)
        {
        case DataScannerDataEndianness_Little:
            theValue = CFSwapInt16LittleToHost(theValue);
            break;
        case DataScannerDataEndianness_Big:
            theValue = CFSwapInt16BigToHost(theValue);
            break;
        default:
            break;
        }
    *outValue = theValue;

    self.range = (NSRange){ .location = self.range.location + sizeof(*outValue), .length = self.range.length - sizeof(*outValue) };

    return(YES);
    }

- (BOOL)scan_uint32_binary:(uint32_t *)outValue error:(NSError *__autoreleasing *)outError
    {
    if (_range.length < sizeof(*outValue))
        {
        [self _makeError:outError code:-1];
        return(NO);
        }

    uint32_t theValue = *(uint32_t *)((const char *)[_data bytes] + _range.location);
    switch (self.dataEndianness)
        {
        case DataScannerDataEndianness_Little:
            theValue = CFSwapInt32LittleToHost(theValue);
            break;
        case DataScannerDataEndianness_Big:
            theValue = CFSwapInt32BigToHost(theValue);
            break;
        default:
            break;
        }
    *outValue = theValue;

    self.range = (NSRange){ .location = self.range.location + sizeof(*outValue), .length = self.range.length - sizeof(*outValue) };

    return(YES);
    }

#pragma mark -


#pragma clang diagnostic push
//#pragma clang diagnostic ignored "-Wunused-variable"
// CLANG_ANALYZER_OBJC_NSCFERROR

- (BOOL)_makeError:(NSError *__autoreleasing *)outError code:(NSInteger)inCode
    {
    if (outError == NULL)
        {
        return(NO);
        }

    NSError *theError = [NSError errorWithDomain:@"TODO_DOMAIN" code:inCode userInfo:NULL];
    *outError = theError;
    return(YES);
    }

#pragma clang diagnostic pop


@end
