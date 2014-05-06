//
//  NSInvocation+JSONRPCExtensions.h
//  Shanty
//
//  Created by Jonathan Wight on 5/5/14.
//  Copyright (c) 2014 schwa.io. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSInvocation (JSONRPCExtensions)

- (id)getReturnValueObject:(NSError **)outError;
- (void)setReturnValueObject:(id)inObject;

- (id)getArgumentValueObjectAtIndex:(NSInteger)idx;
- (void)setArgumentValueObject:(id)inObject atIndex:(NSInteger)idx;

@end
