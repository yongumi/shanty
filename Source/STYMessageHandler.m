//
//  STYMessageHandler.m
//  Shanty Examples
//
//  Created by Jonathan Wight on 12/10/13.
//  Copyright (c) 2013 schwa.io. All rights reserved.
//

#import "STYMessageHandler.h"

#import "STYMessage.h"
#import "STYConstants.h"

@interface STYMessageHandler ()
@property (readwrite, nonatomic) NSMutableArray *blocks;
@end

#pragma mark -

@implementation STYMessageHandler

- (instancetype)init
    {
    if ((self = [super init]) != NULL)
        {
        _blocks = [NSMutableArray array];
        }
    return self;
    }

- (void)addCommand:(NSString *)inCommand block:(STYMessageBlock)inBlock;
    {
    [self.blocks insertObject:@[ inCommand ?: [NSNull null], inBlock ] atIndex:0];
    }

- (STYMessageBlock)blockForMessage:(STYMessage *)inMessage error:(NSError *__autoreleasing *)outError
    {
    NSArray *theBlocks = [self _blocksForMessage:inMessage];
    if (theBlocks.count > 1)
        {
        if (outError)
            {
            *outError = [NSError errorWithDomain:kSTYErrorDomain code:-1 userInfo:NULL];
            }
        return NULL;
        }

    if (theBlocks.count == 0)
        {
        if (outError)
            {
            *outError = NULL;
            }
        return NULL;
        }

    return theBlocks[0];
    }

- (NSArray *)_blocksForMessage:(STYMessage *)inMessage;
    {
    NSMutableArray *theBlocks = [NSMutableArray array];
    for (NSArray *theRecord in self.blocks)
        {
        id theCommand = theRecord[0];
        STYMessageBlock theBlock = theRecord[1];
        if (theCommand == [NSNull null] || [inMessage.controlData[kSTYCommandKey] isEqualToString:theCommand])
            {
            [theBlocks addObject:theBlock];
            }
        }
    return(theBlocks);
    }

@end
