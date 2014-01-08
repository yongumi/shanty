//
//  STYLogging.h
//  TwitterNT
//
//  Created by Jonathan Wight on 11/26/13.
//  Copyright (c) 2013 toxicsoftware. All rights reserved.
//

#import <Foundation/Foundation.h>
@interface STYLogging : NSObject

+ (instancetype)sharedInstance;

- (void)log:(NSString *)inMessage;

@end
