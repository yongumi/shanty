//
//  TXJSONRPCFunctionCall.h
//  Shanty
//
//  Created by Jonathan Wight on 5/5/14.
//  Copyright (c) 2014 schwa.io. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TXJSONRPCFunctionCall : NSObject
@property (readonly, nonatomic, copy) NSString *identifier;
@property (readonly, nonatomic, copy) NSString *methodName;
@property (readonly, nonatomic, copy) NSArray *indexedParameters;
//@property (readonly, nonatomic, copy) NSDictionary *namedParameters;

- (instancetype)initWithIdentifier:(NSString *)inIdentifier methodName:(NSString *)inMethodName indexedParameters:(NSArray *)inIndexedParameters;
- (instancetype)initWithIdentifier:(NSString *)inIdentifier methodName:(NSString *)inMethodName;

- (instancetype)initWithJSONData:(NSData *)inJSONData error:(NSError **)outError;
- (NSData *)asJSONWithID:(NSString *)inID error:(NSError **)outError;

@end
