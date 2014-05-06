//
//  TXJSONRPCFunctionResult.h
//  Shanty
//
//  Created by Jonathan Wight on 5/5/14.
//  Copyright (c) 2014 schwa.io. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TXJSONRPCFunctionResult : NSObject
@property (readonly, nonatomic, copy) NSString *identifier;
@property (readonly, nonatomic, copy) id <NSObject, NSCopying> result;
@property (readonly, nonatomic, copy) NSError *error;

- (instancetype)initWithIdentifier:(NSString *)inIdentifier result:(id <NSObject, NSCopying>)inResult error:(NSError *)inError;
- (instancetype)initWithIdentifier:(NSString *)inIdentifier;
- (instancetype)initWithIdentifier:(NSString *)inIdentifier error:(NSError *)inError;
- (instancetype)initWithIdentifier:(NSString *)inIdentifier result:(id <NSObject, NSCopying>)inResult;

- (instancetype)initWithJSONData:(NSData *)inJSONData error:(NSError **)outError;
- (NSData *)asJSON:(NSError **)outError;

@end
