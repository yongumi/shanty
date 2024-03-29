//
//  STYDataScanner.h
//  Shanty
//
//  Created by Jonathan Wight on 11/4/13.
//  Copyright (c) 2013 schwa.io. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, EDataScannerMode) {
	DataScannerMode_Binary,
	DataScannerMode_Text,
	};

typedef NS_ENUM(NSInteger, EDataScannerDataEndianness) {
	DataScannerDataEndianness_Native,
	DataScannerDataEndianness_Little,
	DataScannerDataEndianness_Big,
	DataScannerDataEndianness_Network = DataScannerDataEndianness_Big,
	};

@interface STYDataScanner : NSObject

@property (readonly, nonatomic, copy) NSData *data;
@property (readwrite, nonatomic) NSRange range;
@property (readwrite, nonatomic) EDataScannerMode mode;
@property (readwrite, nonatomic) EDataScannerDataEndianness dataEndianness;
@property (readwrite, nonatomic) BOOL shouldCopyData;

- (instancetype)init;
- (instancetype)initWithData:(NSData *)inData;

- (NSData *)remainingData;

- (void)feedData:(NSData *)inData;

- (void)pushRange;
- (NSRange)popRange;

- (BOOL)scanData:(NSData *__autoreleasing *)outValue length:(NSUInteger)inLength error:(NSError *__autoreleasing *)outError;

- (BOOL)scan_uint16:(uint16_t *)outValue error:(NSError *__autoreleasing *)outError;
- (BOOL)scan_uint32:(uint32_t *)outValue error:(NSError *__autoreleasing *)outError;

@end
