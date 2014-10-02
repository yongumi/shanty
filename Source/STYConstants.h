//
//  STYConstants.h
//  Shanty
//
//  Created by Jonathan Wight on 1/2/14.
//  Copyright (c) 2014 schwa.io. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *const kSTYCommandKey; // = @"cmd";
extern NSString *const kSTYMessageIDKey; // = @"msgid";
extern NSString *const kSTYInReplyToKey; // = @"in-reply-to";
extern NSString *const kSTYCloseKey; // = @"close";
extern NSString *const kSTYMoreComing; // = @"more-coming";
extern NSString *const kSTYSecretKey; // = @"secret";
extern NSString *const kSTYRequiresChallengeResponseKey; // = @"requiresChallengeResponse";

extern NSString *const kSTYHelloCommand; // = @"hello";
extern NSString *const kSTYHelloReplyCommand; // = @"hello.reply";
extern NSString *const kSTYSecretCommand; // = @"_secret";
extern NSString *const kSTYSecretReplyCommand;  //= @"_secret.reply";

extern NSString *const kSTYErrorDomain; // = @"io.schwa.shanty";

typedef NS_ENUM(NSInteger, ESTYErrorCode) {
	kSTYErrorCode_Unknown = -1,
	kSTYErrorCode_AlreadyClosed = 100,
	};
