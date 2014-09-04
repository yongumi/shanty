//
//  STYChallengeResponseHelper.h
//  shanty
//
//  Created by Jonathan Wight on 8/29/14.
//  Copyright (c) 2014 schwa.io. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface STYChallengeResponseHelper : NSObject

@property (readwrite, nonatomic) NSUInteger minimumKeyLength;
@property (readwrite, nonatomic) NSUInteger saltLength;
@property (readwrite, nonatomic, copy) NSData *salt;
@property (readwrite, nonatomic) NSUInteger numberOfRounds;


@end
