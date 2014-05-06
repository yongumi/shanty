//
//  TXJSONRPCFunctionResult.m
//  Shanty
//
//  Created by Jonathan Wight on 5/5/14.
//  Copyright (c) 2014 schwa.io. All rights reserved.
//

#import "TXJSONRPCFunctionResult.h"

@implementation TXJSONRPCFunctionResult

- (instancetype)initWithIdentifier:(NSString *)inIdentifier result:(id <NSObject, NSCopying>)inResult error:(NSError *)inError;
    {
    NSParameterAssert(inIdentifier != NULL);

    if ((self = [super init]) != NULL)
        {
        // TODO copy
        _identifier = inIdentifier;
        _result = inResult;
        _error = inError;
        }
    return self;
    }

- (instancetype)initWithIdentifier:(NSString *)inIdentifier
    {
    return [self initWithIdentifier:inIdentifier result:NULL error:NULL];
    }

- (instancetype)initWithIdentifier:(NSString *)inIdentifier result:(id <NSObject, NSCopying>)inResult
    {
    return [self initWithIdentifier:inIdentifier result:inResult error:NULL];
    }

- (instancetype)initWithIdentifier:(NSString *)inIdentifier error:(NSError *)inError
    {
    return [self initWithIdentifier:inIdentifier result:NULL error:inError];
    }

#pragma mark -

- (instancetype)initWithJSONData:(NSData *)inJSONData error:(NSError **)outError
    {
    NSDictionary *theDictionary = [NSJSONSerialization JSONObjectWithData:inJSONData options:0 error:outError];
    // TODO - test JSON-RPC version
    // TODO - identifier

    NSString *theIdentifier = theDictionary[@"id"];
    id theResult = theDictionary[@"result"];
    NSError *theError = NULL;
    if (theDictionary[@"error"] != NULL)
        {
        theError = [NSError errorWithDomain:@"JSON-RPC" code:[theDictionary[@"error"][@"code"] intValue] userInfo:@{ NSLocalizedDescriptionKey: theDictionary[@"error"][@"message"] ?: @"Unknown resason" }];
        }

    return [self initWithIdentifier:theIdentifier result:theResult error:theError];
    }

- (NSData *)asJSON:(NSError **)outError
    {
    // TODO: id

    NSDictionary *theDictionary = NULL;
    if (self.result != NULL)
        {
        theDictionary = @{
            @"jsonrpc": @"2.0",
            @"id": self.identifier,
            @"result": self.result
            };
        }
    else if (self.error != NULL)
        {
        NSParameterAssert([self.error.domain isEqualToString:@"json-rpc"]);
        theDictionary = @{
            @"jsonrpc": @"2.0",
            @"id": self.identifier,
            @"error": @{
                @"code": @(self.error.code),
                @"message": self.error.userInfo[NSLocalizedDescriptionKey],
                },
            };
        }
    else
        {
        theDictionary = @{
            @"jsonrpc": @"2.0",
            @"id": self.identifier,
            };
        }
    return [NSJSONSerialization dataWithJSONObject:theDictionary options:0 error:outError];
    }

@end
