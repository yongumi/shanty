//
//  NSNetService+ShantyUserInfo.m
//  Shanty
//
//  Created by Jonathan Wight on 11/5/13.
//  Copyright (c) 2013 schwa.io. All rights reserved.
//

#import "NSNetService+ShantyUserInfo.h"

#import <objc/runtime.h>

@implementation NSNetService (ShantyUserInfo)

static void *kUserInfoKey;

- (id)dit_userInfo
    {
    id theUserInfo = objc_getAssociatedObject(self, &kUserInfoKey);
    return(theUserInfo);
    }

- (void)setDit_userInfo:(id)dit_userInfo
    {
    objc_setAssociatedObject(self, &kUserInfoKey, dit_userInfo, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

@end
