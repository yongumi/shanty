//
//  STYLogger.m
//  shanty
//
//  Created by Jonathan Wight on 5/21/14.
//  Copyright (c) 2014 schwa.io. All rights reserved.
//

#import "STYLogger.h"

static bool gSTYLoggingEnabled = false;

bool STYLoggingEnabled()                { return gSTYLoggingEnabled;    }
void STYSetLoggingEnabled(bool enabled) { gSTYLoggingEnabled = enabled; }


static NSString *QueueName(void);
//static NSString *QueueID(void);

extern void STYLog(STYLogLevel level, NSDictionary *location, NSString *format, ...)
    {
    if (!gSTYLoggingEnabled)
        {
        return;
        }
        
    va_list ap;
    va_start(ap, format);
    NSString *theString = [[NSString alloc] initWithFormat:format arguments:ap];
    va_end(ap);

    CFAbsoluteTime current_time = CFAbsoluteTimeGetCurrent();

    static CFAbsoluteTime start_time = 0;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        start_time = current_time;
    });

    //+ NSLog(@"%@", theString);
    NSString *theQueueName = QueueName();

    theString = [NSString stringWithFormat:@"%5.2f | %-21.21s | %-20.20s#%-4.4d | %@", current_time - start_time, [theQueueName UTF8String], [location[@"function"] UTF8String], [location[@"line"] intValue], theString];    
    fprintf(stderr, "%s\n", [theString UTF8String]);
    }

static NSString *QueueName(void)
    {
    NSString *theQueueName = [NSString stringWithFormat:@"%s", dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL)];
//    NSString *theQueueName = [NSString stringWithFormat:@"%s:%@", dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL), QueueID()];
    return theQueueName;
    }
    
//static NSString *QueueID(void)
//    {
//    NSString *theQueueID = NULL;
//
//    dispatch_queue_t theCurrentQueue = dispatch_get_current_queue();
//    id theKey = @((int)theCurrentQueue);
//    
//    static OSSpinLock theLock = OS_SPINLOCK_INIT;
//    OSSpinLockLock(&theLock);
//
//    static NSMutableDictionary *sQueueIDs = NULL;
//    if (sQueueIDs == NULL)
//        {
//        sQueueIDs = [NSMutableDictionary dictionary];
//        }
//
//    theQueueID = sQueueIDs[theKey];
//    if (theQueueID == NULL)
//        {
//        theQueueID = [@([sQueueIDs count] + 1) stringValue];
//        sQueueIDs[theKey] = theQueueID;
//        }
//    
//    
//    OSSpinLockUnlock(&theLock);
//    
//    return theQueueID;
//    }
