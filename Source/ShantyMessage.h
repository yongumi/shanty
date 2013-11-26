//
//  ShantyMessage.h
//  Shanty
//
//  Created by Jonathan Wight on 10/29/13.
//  Copyright (c) 2013 schwa.io. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ShantyMessage : NSObject

@property (readonly, nonatomic, copy) NSDictionary *controlData;
@property (readonly, nonatomic, copy) NSDictionary *metadata;
@property (readonly, nonatomic, copy) NSData *data;

+ (NSData *)encode:(NSDictionary *)inData error:(NSError *__autoreleasing *)outError;
+ (NSDictionary *)decode:(NSData *)inData error:(NSError *__autoreleasing *)outError;

- (instancetype)initWithControlData:(NSDictionary *)inControlData metadata:(NSDictionary *)inMetadata data:(NSData *)inData;
- (instancetype)initWithDataBuffer:(NSData *)inDataBuffer error:(NSError *__autoreleasing *)outError;

- (NSData *)buffer:(NSError *__autoreleasing *)outError;

@end
