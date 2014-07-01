//
//  STYLogger.h
//  shanty
//
//  Created by Jonathan Wight on 5/21/14.
//  Copyright (c) 2014 schwa.io. All rights reserved.
//

#import <Foundation/Foundation.h>

#define LOCATION_ @{@"file": @(__FILE__), @"function": @(__PRETTY_FUNCTION__), @"line": @(__LINE__)}

#if 1
#define STYLogDebug_(...) STYLogDebug(LOCATION_, __VA_ARGS__)
#else
#define STYLogDebug_(...)
#endif
    
extern bool STYLoggingEnabled();
extern void STYSetLoggingEnabled(bool enabled);
extern void STYLogDebug(NSDictionary *location, NSString *format, ...);
