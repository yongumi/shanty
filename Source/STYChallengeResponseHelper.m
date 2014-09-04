//
//  STYChallengeResponseHelper.m
//  shanty
//
//  Created by Jonathan Wight on 8/29/14.
//  Copyright (c) 2014 schwa.io. All rights reserved.
//

#import "STYChallengeResponseHelper.h"

#import <CommonCrypto/CommonKeyDerivation.h>
#import <CommonCrypto/CommonHMAC.h>
#import <CommonCrypto/CommonRandom.h>

@implementation STYChallengeResponseHelper

+ (NSString *)randomSecret
    {
    return [NSString stringWithFormat:@"%d%d%d%d", arc4random_uniform(10), arc4random_uniform(10), arc4random_uniform(10), arc4random_uniform(10)];
    }

- (id)init
    {
    if ((self = [super init]) != NULL)
        {
        _minimumKeyLength = 4;
        _saltLength = 256;
        }
    return self;
    }
 
- (NSData *)salt
    {
    if (_salt == NULL)
        {
        NSMutableData *theSalt = [NSMutableData dataWithLength:self.saltLength];
        if (CCRandomGenerateBytes(theSalt.mutableBytes, self.saltLength) != kCCSuccess)
            {
            // SHIT
            NSLog(@"CCRandomGenerateBytes failed");
            }
        _salt = theSalt;
        }
    return _salt;
    }

- (NSUInteger)numberOfRounds
    {
    if (_numberOfRounds == 0)
        {
        _numberOfRounds = CCCalibratePBKDF(kCCPBKDF2, self.minimumKeyLength, self.saltLength, kCCPRFHmacAlgSHA512, CC_SHA512_DIGEST_LENGTH, 1000)
        }
    return _numberOfRounds;
    }

- (NSData *)derivedKeyForKey:(NSString *)inKey
    {
    NSMutableData *theDerivedKey = [NSMutableData dataWithLength:CC_SHA512_DIGEST_LENGTH];
   
    if (CCKeyDerivationPBKDF(kCCPBKDF2, inKey.UTF8String, strlen(inKey.UTF8String), salt, 256, kCCPRFHmacAlgSHA512, numberOfRounds, theDerivedKey.mutableBytes, CC_SHA512_DIGEST_LENGTH) != 0)
        {
        return NULL;
        }


//    CCHmac(kCCHmacAlgSHA512, <#const void *key#>, <#size_t keyLength#>, <#const void *data#>, <#size_t dataLength#>, <#void *macOut#>)

    return theDerivedKey;
    }

 


@end
