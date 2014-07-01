//
//  STYLogger.h
//  shanty
//
//  Created by Jonathan Wight on 5/21/14.
//  Copyright (c) 2014 schwa.io. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    LogLevel_Debug,
    LogLevel_Warning,
    LogLevel_Error,
} STYLogLevel;

#define LOCATION_ @{@"file": @(__FILE__), @"function": @(__PRETTY_FUNCTION__), @"line": @(__LINE__)}

#if 1
#define STYLogDebug_(...) STYLog(LogLevel_Debug, LOCATION_, __VA_ARGS__)
#define STYLogWarning_(...) STYLog(LogLevel_Warning, LOCATION_, __VA_ARGS__)
#define STYLogError_(...) STYLog(LogLevel_Error, LOCATION_, __VA_ARGS__)
#else
#define STYLogDebug_(...)
#define STYLogWarning_(...)
#define STYLogError_(...)
#endif
    
extern bool STYLoggingEnabled();
extern void STYSetLoggingEnabled(bool enabled);
extern void STYLog(STYLogLevel level, NSDictionary *location, NSString *format, ...);
