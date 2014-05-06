//
//  NSInvocation+JSONRPCExtensions.m
//  Shanty
//
//  Created by Jonathan Wight on 5/5/14.
//  Copyright (c) 2014 schwa.io. All rights reserved.
//

#import "NSInvocation+JSONRPCExtensions.h"

#define _GET_SCALAR(type, invocation, index) ({ type theArgument; [invocation getArgument:&theArgument atIndex:index]; @(theArgument); })

#define _SET_SCALAR_RETURN_VALUE(object, type, converter, invocation) { \
    if ([object isKindOfClass:[NSNumber class]] == NO) \
        { \
        @throw [NSException exceptionWithName:@"TODO" reason:@"NO" userInfo:NULL]; \
        } \
    type theReturnValue = [object converter]; \
    [invocation setReturnValue:&theReturnValue]; \
    }

@implementation NSInvocation (JSONRPCExtensions)

- (id)getReturnValueObject:(NSError **)outError
    {
    NSMethodSignature *theMethodSignature = self.methodSignature;
    const char *theReturnType = [theMethodSignature methodReturnType];
    switch (theReturnType[0])
        {
        case 'c': /* A char */
            {
            char theValue;
            [self getReturnValue:&theValue];
            return @(theValue);
            }
            break;
        case 'i': /* An int */
            {
            int theValue;
            [self getReturnValue:&theValue];
            return @(theValue);
            }
            break;
        case 's': /* A short */
            {
            short theValue;
            [self getReturnValue:&theValue];
            return @(theValue);
            }
            break;
        case 'l': /* A long, l is treated as a 32-bit quantity on 64-bit programs */
            {
            long theValue;
            [self getReturnValue:&theValue];
            return @(theValue);
            }
            break;
        case 'q': /* A long long */
            {
            long long theValue;
            [self getReturnValue:&theValue];
            return @(theValue);
            }
            break;
        case 'C': /* An unsigned char */
            {
            unsigned char theValue;
            [self getReturnValue:&theValue];
            return @(theValue);
            }
            break;
        case 'I': /* An unsigned int */
            {
            unsigned int theValue;
            [self getReturnValue:&theValue];
            return @(theValue);
            }
            break;
        case 'S': /* An unsigned short */
            {
            unsigned short theValue;
            [self getReturnValue:&theValue];
            return @(theValue);
            }
            break;
        case 'L': /* An unsigned long */
            {
            unsigned long theValue;
            [self getReturnValue:&theValue];
            return @(theValue);
            }
            break;
        case 'Q': /* An unsigned long long */
            {
            unsigned long long theValue;
            [self getReturnValue:&theValue];
            return @(theValue);
            }
            break;
        case 'f': /* A float */
            {
            float theValue;
            [self getReturnValue:&theValue];
            return @(theValue);
            }
            break;
        case 'd': /* A double */
            {
            double theValue;
            [self getReturnValue:&theValue];
            return @(theValue);
            }
            break;
        case 'B': /* A C++ bool or a C99 _Bool */
            {
            bool theValue;
            [self getReturnValue:&theValue];
            return @(theValue);
            }
            break;
        case 'v': /* A void */
            {
            return NULL;
            }
            break;
        case '*': /* A character string (char *) */
            {
            char *theValue;
            [self getReturnValue:&theValue];
            // TODO - we assume UTF8
            return [NSString stringWithUTF8String:theValue];
            }
            break;
        case '@': /* An object (whether statically typed or typed id) */
            {
            __unsafe_unretained id theObjectResult = NULL;
            [self getReturnValue:&theObjectResult];
            return theObjectResult;
            }
            break;
        default:
            {
            if (strcmp(theReturnType, @encode(CGPoint)) == 0)
                {
                CGPoint theValue;
                [self getReturnValue:&theValue];
                return @{ @"type": @"CGPoint", @"x": @(theValue.x), @"y": @(theValue.y) };
                }
            else
                {
                if (outError)
                    {
                    *outError = [NSError errorWithDomain:@"TXJSONRPC" code:-1 userInfo:@{ NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Unknown type %c", theReturnType[0]] }];
                    }
                return NULL;
                }
            }
        // TODO https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtTypeEncodings.html
        }
    }

- (void)setReturnValueObject:(id)inObject
    {
    const char *theReturnType = [self.methodSignature methodReturnType];
    NSParameterAssert(theReturnType != NULL);
    NSParameterAssert(strlen(theReturnType) >= 0);
    switch (theReturnType[0])
        {
        case 'c': /* A char */
            _SET_SCALAR_RETURN_VALUE(inObject, char, charValue, self);
            break;
        case 'i': /* An int */
            _SET_SCALAR_RETURN_VALUE(inObject, int, intValue, self);
            break;
        case 's': /* A short */
            _SET_SCALAR_RETURN_VALUE(inObject, short, shortValue, self);
            break;
        case 'l': /* A long, l is treated as a 32-bit quantity on 64-bit programs */
            _SET_SCALAR_RETURN_VALUE(inObject, long, longValue, self);
            break;
        case 'q': /* A long long */
            _SET_SCALAR_RETURN_VALUE(inObject, long long, longLongValue, self);
            break;
        case 'C': /* An unsigned char */
            _SET_SCALAR_RETURN_VALUE(inObject, unsigned char, unsignedCharValue, self);
            break;
        case 'I': /* An unsigned int */
            _SET_SCALAR_RETURN_VALUE(inObject, unsigned int, unsignedIntValue, self);
            break;
        case 'S': /* An unsigned short */
            _SET_SCALAR_RETURN_VALUE(inObject, unsigned short, unsignedShortValue, self);
            break;
        case 'L': /* An unsigned long */
            _SET_SCALAR_RETURN_VALUE(inObject, unsigned long, unsignedLongValue, self);
            break;
        case 'Q': /* An unsigned long long */
            _SET_SCALAR_RETURN_VALUE(inObject, unsigned long long, unsignedLongLongValue, self);
            break;
        case 'f': /* A float */
            _SET_SCALAR_RETURN_VALUE(inObject, float, floatValue, self);
            break;
        case 'd': /* A double */
            _SET_SCALAR_RETURN_VALUE(inObject, double, doubleValue, self);
            break;
        case 'B': /* A C++ bool or a C99 _Bool */
            _SET_SCALAR_RETURN_VALUE(inObject, bool, boolValue, self);
            break;
        case 'v': /* A void */
            {
            // Nothing to do here!
            }
            break;
        case '@': /* An object (whether statically typed or typed id) */
            {
            id theReturnValue = inObject;
            [self setReturnValue:&theReturnValue];
            }
            break;
        default:
            {
            if (strcmp(theReturnType, @encode(CGPoint)) == 0)
                {
//                return @{ @"type": @"CGPoint", @"x": @(theValue.x), @"y": @(theValue.y) };

                // TODO validate. Break into own function/method

                CGPoint theValue;
                theValue.x = [inObject[@"x"] doubleValue];
                theValue.y = [inObject[@"y"] doubleValue];
                [self setReturnValue:&theValue];
                }
            else
                {
                NSParameterAssert(NULL);
                }
            }
        }
    }

- (id)getArgumentValueObjectAtIndex:(NSInteger)idx
    {
    const char *theArgumentType = [self.methodSignature getArgumentTypeAtIndex:idx];
    NSParameterAssert(theArgumentType != NULL);
    NSParameterAssert(strlen(theArgumentType) >= 0);
    switch (theArgumentType[0])
        {
        case 'c': /* A char */
            return _GET_SCALAR(char, self, idx);
            break;
        case 'i': /* An int */
            return _GET_SCALAR(int, self, idx);
            break;
        case 's': /* A short */
            return _GET_SCALAR(short, self, idx);
            break;
        case 'l': /* A long, l is treated as a 32-bit quantity on 64-bit programs */
            return _GET_SCALAR(long, self, idx);
            break;
        case 'q': /* A long long */
            return _GET_SCALAR(long long, self, idx);
            break;
        case 'C': /* An unsigned char */
            return _GET_SCALAR(unsigned char, self, idx);
            break;
        case 'I': /* An unsigned int */
            return _GET_SCALAR(unsigned int, self, idx);
            break;
        case 'S': /* An unsigned short */
            return _GET_SCALAR(unsigned short, self, idx);
            break;
        case 'L': /* An unsigned long */
            return _GET_SCALAR(unsigned long, self, idx);
            break;
        case 'Q': /* An unsigned long long */
            return _GET_SCALAR(unsigned long long, self, idx);
            break;
        case 'f': /* A float */
            return _GET_SCALAR(float, self, idx);
            break;
        case 'd': /* A double */
            return _GET_SCALAR(double, self, idx);
            break;
        case 'B': /* A C++ bool or a C99 _Bool */
            return _GET_SCALAR(bool, self, idx);
            break;
        case '@': /* An object (whether statically typed or typed id) */
            {
            __unsafe_unretained id theArgument;
            [self getArgument:&theArgument atIndex:idx];
            return theArgument;
            }
            break;
        default:
            {
            NSParameterAssert(NULL);
            }
        }
    return(NULL);
    }

- (void)setArgumentValueObject:(id)inObject atIndex:(NSInteger)idx
    {
    NSMethodSignature *theMethodSignature = self.methodSignature;
    const char *theArgumentType = [theMethodSignature getArgumentTypeAtIndex:idx];
    switch (theArgumentType[0])
        {
        case 'c': /* A char */
            {
            char theArgument = [inObject charValue];
            [self setArgument:&theArgument atIndex:idx];
            }
            break;
        case 'i': /* An int */
            {
            int theArgument = [inObject intValue];
            [self setArgument:&theArgument atIndex:idx];
            }
            break;
        case 's': /* A short */
            {
            short theArgument = [inObject shortValue];
            [self setArgument:&theArgument atIndex:idx];
            }
            break;
        case 'l': /* A long, l is treated as a 32-bit quantity on 64-bit programs */
            {
            long theArgument = [inObject longValue];
            [self setArgument:&theArgument atIndex:idx];
            }
            break;
        case 'q': /* A long long */
            {
            long long theArgument = [inObject longLongValue];
            [self setArgument:&theArgument atIndex:idx];
            }
            break;
        case 'C': /* An unsigned char */
            {
            unsigned char theArgument = [inObject unsignedCharValue];
            [self setArgument:&theArgument atIndex:idx];
            }
            break;
        case 'I': /* An unsigned int */
            {
            unsigned int theArgument = [inObject unsignedIntValue];
            [self setArgument:&theArgument atIndex:idx];
            }
            break;
        case 'S': /* An unsigned short */
            {
            unsigned short theArgument = [inObject unsignedShortValue];
            [self setArgument:&theArgument atIndex:idx];
            }
            break;
        case 'L': /* An unsigned long */
            {
            unsigned long theArgument = [inObject unsignedLongValue];
            [self setArgument:&theArgument atIndex:idx];
            }
            break;
        case 'Q': /* An unsigned long long */
            {
            unsigned long long theArgument = [inObject unsignedLongLongValue];
            [self setArgument:&theArgument atIndex:idx];
            }
            break;
        case 'f': /* A float */
            {
            float theArgument = [inObject floatValue];
            [self setArgument:&theArgument atIndex:idx];
            }
            break;
        case 'd': /* A double */
            {
            double theArgument = [inObject doubleValue];
            [self setArgument:&theArgument atIndex:idx];
            }
            break;
        case 'B': /* A C++ bool or a C99 _Bool */
            {
            bool theArgument = [inObject boolValue];
            [self setArgument:&theArgument atIndex:idx];
            }
            break;
        case '@': /* An object (whether statically typed or typed id) */
            {
            id theArgument = inObject;
            [self setArgument:&theArgument atIndex:idx];
            }
            break;
        default:
            {
            NSParameterAssert(NULL);
            }
        }
    }

@end
