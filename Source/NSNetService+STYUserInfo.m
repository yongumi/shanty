//
//  NSNetService+STYUserInfo.m
//  Shanty
//
//  Created by Jonathan Wight on 11/5/13.
//  Copyright (c) 2013 schwa.io. All rights reserved.
//

#import "NSNetService+STYUserInfo.h"

#import <objc/runtime.h>

@implementation NSNetService (STYUserInfo)

static void *kUserInfoKey;

- (id)sty_userInfo
    {
    id theUserInfo = objc_getAssociatedObject(self, &kUserInfoKey);
    return(theUserInfo);
    }

- (void)setSty_userInfo:(id)sty_userInfo
    {
    objc_setAssociatedObject(self, &kUserInfoKey, sty_userInfo, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

@end
