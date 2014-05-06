//
//  TXJSONRPCFunctionCall.m
//  Shanty
//
//  Created by Jonathan Wight on 5/5/14.
//  Copyright (c) 2014 schwa.io. All rights reserved.
//

#import "TXJSONRPCFunctionCall.h"

@implementation TXJSONRPCFunctionCall

- (instancetype)initWithIdentifier:(NSString *)inIdentifier methodName:(NSString *)inMethodName indexedParameters:(NSArray *)inIndexedParameters
    {
    NSParameterAssert(inIdentifier != NULL);
    NSParameterAssert(inMethodName.length > 0);
    if ((self = [super init]) != NULL)
        {
        _identifier = inIdentifier;
        _methodName = inMethodName;
        _indexedParameters = inIndexedParameters;
        }
    return self;
    }

- (instancetype)initWithIdentifier:(NSString *)inIdentifier methodName:(NSString *)inMethodName
    {
    return [self initWithIdentifier:inIdentifier methodName:inMethodName indexedParameters:NULL];
    }

#pragma mark -

- (instancetype)initWithJSONData:(NSData *)inJSONData error:(NSError **)outError
    {
    // TODO - name parameters
    // TODO - jsonrpc version checking
    // TODO - test method name exists
    NSDictionary *theDictionary = [NSJSONSerialization JSONObjectWithData:inJSONData options:0 error:outError];
    if (theDictionary == NULL)
        {
        self = NULL;
        return NULL;
        }
    return [self initWithIdentifier:theDictionary[@"id"] methodName:theDictionary[@"method"] indexedParameters:theDictionary[@"params"]];
    }

- (NSData *)asJSONWithID:(NSString *)inID error:(NSError **)outError
    {
    NSParameterAssert(inID != NULL);
    NSDictionary *theDictionary = @{
        @"jsonrpc": @"2.0",
        @"id": inID,
        @"method": self.methodName,
        @"params": self.indexedParameters,
        };
    return [NSJSONSerialization dataWithJSONObject:theDictionary options:0 error:outError];
    }

@end
