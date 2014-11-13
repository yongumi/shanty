//
//  STYMessage.h
//  Shanty
//
//  Created by Jonathan Wight on 10/29/13.
//  Copyright (c) 2013 schwa.io. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, STYMessageDirection) {
	kSTYMessageDirection_Unknown,
	kSTYMessageDirection_Incoming,
	kSTYMessageDirection_Outgoing,
	};

@interface STYMessage : NSObject <NSCopying, NSMutableCopying>

@property (readonly, nonatomic, copy) NSDictionary *controlData;
@property (readonly, nonatomic, copy) NSDictionary *metadata;
@property (readonly, nonatomic, copy) NSData *data;

@property (readonly, nonatomic) STYMessageDirection direction;

+ (NSData *)encode:(NSDictionary *)inData error:(NSError *__autoreleasing *)outError;
+ (NSDictionary *)decode:(NSData *)inData error:(NSError *__autoreleasing *)outError;

+ (NSDictionary *)defaultControlData;
+ (NSDictionary *)controlDataWithCommand:(NSString *)inCommand replyTo:(STYMessage *)inMessage moreComing:(BOOL)inMoreComing extras:(NSDictionary *)inExtras;

- (instancetype)initWithControlData:(NSDictionary *)inControlData metadata:(NSDictionary *)inMetadata data:(NSData *)inData;
//- (instancetype)initWithCommand:(NSString *)inCommand metadata:(NSDictionary *)inMetadata data:(NSData *)inData;

- (NSData *)buffer:(NSError *__autoreleasing *)outError;

- (instancetype)replyWithControlData:(NSDictionary *)inControlData metadata:(NSDictionary *)inMetadata data:(NSData *)inData;
//- (instancetype)replyWithCommand:(NSString *)inCommand metadata:(NSDictionary *)inMetadata data:(NSData *)inData;

// Convenience property accessors
@property (readonly, nonatomic, copy) NSString *command;
@property (readonly, nonatomic) NSInteger messageID;
@property (readonly, nonatomic) BOOL moreComing;

@end

#pragma mark -

@interface STYMutableMessage : STYMessage

@property (readwrite, nonatomic, copy) NSDictionary *controlData;
@property (readwrite, nonatomic, copy) NSDictionary *metadata;
@property (readwrite, nonatomic, copy) NSData *data;

@property (readwrite, nonatomic) STYMessageDirection direction;

@property (readwrite, nonatomic, copy) NSString *command;
@property (readwrite, nonatomic) NSInteger messageID;

@end