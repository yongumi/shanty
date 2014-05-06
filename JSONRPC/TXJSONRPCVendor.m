//
//  JSONRPCTest.m
//  Shanty
//
//  Created by Jonathan Wight on 5/1/14.
//  Copyright (c) 2014 schwa.io. All rights reserved.
//

#import "TXJSONRPCVendor.h"

#import <objc/runtime.h>

#import "NSInvocation+JSONRPCExtensions.h"
#import "TXJSONRPCFunctionCall.h"
#import "TXJSONRPCFunctionResult.h"

@interface TXJSONRPCVendor ()
@property (readwrite, nonatomic, assign) Protocol *protocol;
@property (readwrite, nonatomic, strong) id object;
@end

#pragma mark -

@implementation TXJSONRPCVendor

- (id)initWithProtocol:(Protocol *)inProtocol object:(id)inObject error:(NSError *__autoreleasing *)outError
    {
    if ((self = [super init]) != NULL)
        {
        NSParameterAssert(inProtocol != NULL);
        NSParameterAssert([[inObject class] conformsToProtocol:inProtocol] == YES);
        NSParameterAssert(inObject != NULL);
        _protocol = inProtocol;
        _object = inObject;
        }
    return self;
    }

- (TXJSONRPCFunctionResult *)call:(TXJSONRPCFunctionCall *)inFunctionCall
    {
    NSInvocation *theInvocation = [self _invocationForCall:inFunctionCall];
    if (theInvocation == NULL)
        {
        return [[TXJSONRPCFunctionResult alloc] initWithIdentifier:inFunctionCall.identifier error:[NSError errorWithDomain:@"JSON-RPC" code:-32601 userInfo:@{ NSLocalizedDescriptionKey: @"Method not found" }]];
        }
    [theInvocation setTarget:self.object];
    NSMethodSignature *theMethodSignature = theInvocation.methodSignature;
    for (int N = 2; N != [theMethodSignature numberOfArguments]; ++N)
        {
        [theInvocation setArgumentValueObject:inFunctionCall.indexedParameters[N - 2] atIndex:N];
        }
    [theInvocation invoke];

    NSError *theError = NULL;
    id theResult = [theInvocation getReturnValueObject:&theError];
    if (theResult)
        {
        return [[TXJSONRPCFunctionResult alloc] initWithIdentifier:inFunctionCall.identifier result:theResult];
        }
    else
        {
        if (theError != NULL)
            {
            return [[TXJSONRPCFunctionResult alloc] initWithIdentifier:inFunctionCall.identifier error:theError];
            }
        else
            {
            return [[TXJSONRPCFunctionResult alloc] initWithIdentifier:inFunctionCall.identifier];
            }
        }
    }

- (NSArray *)callBatch:(NSArray *)inCalls
    {
    NSMutableArray *theResults = [NSMutableArray arrayWithCapacity:[inCalls count]];
    for (TXJSONRPCFunctionCall *theCall in inCalls)
        {
        TXJSONRPCFunctionResult *theResult = [self call:theCall];
        [theResults addObject:theResult];
        }
    return theResults;
    }

- (NSInvocation *)_invocationForCall:(TXJSONRPCFunctionCall *)inCall
    {
    unsigned int theCount = 0;
    struct objc_method_description *theMethods = protocol_copyMethodDescriptionList(self.protocol, YES, YES, &theCount);
    for (unsigned int N = 0; N != theCount; ++N)
        {
        NSString *theName = [self _nameForSelector:theMethods[N].name];
        if ([theName isEqualToString:inCall.methodName])
            {
            NSMethodSignature *theSignature = [self.object methodSignatureForSelector:theMethods[N].name];
            NSParameterAssert(theSignature != NULL);
            NSInvocation *theInvocation = [NSInvocation invocationWithMethodSignature:theSignature];
            NSParameterAssert(theInvocation != NULL);
            [theInvocation setSelector:theMethods[N].name];
            return theInvocation;
            }
        }
    theMethods = protocol_copyMethodDescriptionList(self.protocol, NO, YES, &theCount);
    for (unsigned int N = 0; N != theCount; ++N)
        {
        NSString *theName = [self _nameForSelector:theMethods[N].name];
        if ([theName isEqualToString:inCall.methodName])
            {
            NSMethodSignature *theSignature = [self.object methodSignatureForSelector:theMethods[N].name];
            NSParameterAssert(theSignature != NULL);
            NSInvocation *theInvocation = [NSInvocation invocationWithMethodSignature:theSignature];
            NSParameterAssert(theInvocation != NULL);
            [theInvocation setSelector:theMethods[N].name];
            return theInvocation;
            }
        }

    return NULL;
    }

- (NSString *)_nameForSelector:(SEL)inSelector
    {
    NSString *theName = NSStringFromSelector(inSelector);
    theName = [theName stringByReplacingOccurrencesOfString:@":" withString:@""];
    return theName;
    }

@end
