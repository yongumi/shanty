//
//  TXJSONRPCProxy.m
//  Shanty
//
//  Created by Jonathan Wight on 5/2/14.
//  Copyright (c) 2014 schwa.io. All rights reserved.
//

#import "TXJSONRPCProxy.h"

#import <objc/runtime.h>

#import <Shanty/Shanty.h>
#import "TXJSONRPCFunctionCall.h"
#import "TXJSONRPCFunctionResult.h"
#import "NSInvocation+JSONRPCExtensions.h"

@interface TXJSONRPCProxy ()
@property (readwrite, nonatomic, weak) Protocol *protocol;
@property (readwrite, nonatomic) NSUInteger nextIdentifier;
@end

#pragma mark -

@implementation TXJSONRPCProxy

- (id)initWithProtocol:(Protocol *)inProtocol delegate:(id <TXJSONRPCProxyDelegate>)inDelegate;
    {
    NSParameterAssert(inProtocol != NULL);
    NSParameterAssert(inDelegate != NULL);

    _protocol = inProtocol;
    _delegate = inDelegate;

    return self;
    }

- (NSString *)description
    {
    return([NSString stringWithFormat:@"<TXJSONRPCProxy: %p> (%@ %@)", self, NSStringFromProtocol(self.protocol), self.delegate]);
    }
   

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
    {
    struct objc_method_description theDescription = protocol_getMethodDescription(_protocol, aSelector, YES, YES);
    if (theDescription.name == NULL)
        {
        theDescription = protocol_getMethodDescription(_protocol, aSelector, NO, YES);
        }
    NSMethodSignature *theMethodSignature = [NSMethodSignature signatureWithObjCTypes:theDescription.types];
    return(theMethodSignature);
    }

- (void)forwardInvocation:(NSInvocation *)invocation
    {
    NSMutableArray *theParameters = [NSMutableArray array];

    NSString *theSelector = NSStringFromSelector(invocation.selector);
    NSString *theMethodName = [theSelector stringByReplacingOccurrencesOfString:@":" withString:@""];

    const NSUInteger theNumberOfArguments = invocation.methodSignature.numberOfArguments;
    NSParameterAssert(theNumberOfArguments >= 2);

    for (NSInteger N = 2; N != theNumberOfArguments; ++N)
        {
        id theArgument = [invocation getArgumentValueObjectAtIndex:N];
        [theParameters addObject:theArgument];
        }

    NSString *theIdentifier = [NSString stringWithFormat:@"%lu", (unsigned long)self.nextIdentifier++];
    TXJSONRPCFunctionCall *theCall = [[TXJSONRPCFunctionCall alloc] initWithIdentifier:theIdentifier methodName:theMethodName indexedParameters:theParameters];

    TXJSONRPCFunctionResult *theResult = [self.delegate JSONRPCProxy:self call:theCall];
    [invocation setReturnValueObject:theResult.result];
    [invocation retainArguments];
    }

@end
