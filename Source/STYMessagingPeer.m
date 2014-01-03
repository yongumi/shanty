//
//  STYMessagingPeer.m
//  Shanty
//
//  Created by Jonathan Wight on 11/4/13.
//  Copyright (c) 2013 schwa.io. All rights reserved.
//

#import "STYMessagingPeer.h"

#import "STYMessage.h"
#import "STYDataScanner+Message.h"
#import "STYMessageHandler.h"
#import "STYAddress.h"
#import "STYConstants.h"
#import "STYSocket.h"

@interface STYMessagingPeer ()
@property (readwrite, nonatomic) STYMessengerMode mode;
@property (readwrite, nonatomic) STYSocket *socket;
@property (readwrite, nonatomic) NSInteger nextOutgoingMessageID;
@property (readwrite, nonatomic) NSInteger lastIncomingMessageID;
@property (readwrite, nonatomic) NSData *data;
@property (readwrite, nonatomic) NSMutableDictionary *handlersForReplies; // TODO rename blocksForReplies
@end

#pragma mark -

@implementation STYMessagingPeer

- (instancetype)initWithMessageHandler:(STYMessageHandler *)inMessageHandler;
    {
    if ((self = [super init]) != NULL)
        {
        _messageHandler = inMessageHandler;
        _nextOutgoingMessageID = 0;
        _lastIncomingMessageID = -1;
        _handlersForReplies = [NSMutableDictionary dictionary];
        }
    return self;
    }

- (void)openWithMode:(STYMessengerMode)inMode socket:(STYSocket *)inSocket;
    {
    self.mode = inMode;
    self.socket = inSocket;

    [self.socket start:^{
        [self _read];
        }];
    }

- (void)close
    {
    [self.socket stop];
    }

- (void)sendMessage:(STYMessage *)inMessage replyBlock:(STYMessageBlock)inBlock
    {
    NSParameterAssert(inMessage != NULL);

    NSMutableDictionary *theControlData = [inMessage.controlData mutableCopy];
    theControlData[kSTYMessageIDKey] = @(self.nextOutgoingMessageID);
    self.nextOutgoingMessageID += 1;

    STYMessage *theMessage = [[STYMessage alloc] initWithControlData:theControlData metadata:inMessage.metadata data:inMessage.data];

    if (inBlock != NULL)
        {
        self.handlersForReplies[theControlData[kSTYMessageIDKey]] = inBlock;
        }

    NSData *theBuffer = [theMessage buffer:NULL];
    [self _sendData:theBuffer];
    }

#pragma mark -

- (void)_read
    {
    STYDataScanner *theDataScanner = [[STYDataScanner alloc] initWithData:self.data];
    theDataScanner.dataEndianness = DataScannerDataEndianness_Network;

    dispatch_io_read(self.socket.channel, 0, SIZE_MAX, self.socket.queue, ^(bool done, dispatch_data_t data, int error) {

//      NSLog(@"%d %@ %d", done, data, error);

        if (error)
            {
            NSLog(@"Error: %d", error);
            return;
            }

        if (dispatch_data_get_size(data) > 0)
            {
            [theDataScanner feedData:(NSData *)data];

            STYMessage *theMessage = NULL;
            while ([theDataScanner scanMessage:&theMessage error:NULL] == YES)
                {
                [self _handleMessage:theMessage error:NULL];
                }
            }

        if (done)
            {
            self.data = [theDataScanner remainingData];

            if (error == 0 && dispatch_data_get_size(data) == 0)
                {
                [self close];
                }
            }
        });
    }

- (void)_sendData:(NSData *)inData
    {
    dispatch_data_t theData = dispatch_data_create([inData bytes], [inData length], self.socket.queue, DISPATCH_DATA_DESTRUCTOR_DEFAULT);

    dispatch_io_write(self.socket.channel, 0, theData, self.socket.queue, ^(bool done, dispatch_data_t data, int error) {
       // NSLog(@"ERROR? DONE: %d DATASIZE: %d ERROR: %d", done, data ? dispatch_data_get_size(data) : 0, error);
        });
    }

- (BOOL)_handleMessage:(STYMessage *)inMessage error:(NSError *__autoreleasing *)outError
    {
    BOOL theResult = NO;

    NSInteger incoming_message_id = [inMessage.controlData[kSTYMessageIDKey] integerValue];
    if (self.lastIncomingMessageID != -1 && incoming_message_id != self.lastIncomingMessageID + 1)
        {
        NSLog(@"Error: message id mismatch.");
        return(NO);
        }

    self.lastIncomingMessageID = incoming_message_id;

    STYMessageBlock theHandler = self.handlersForReplies[inMessage.controlData[kSTYInReplyToKey]];
    if (theHandler)
        {
        theResult = theHandler(self, inMessage, outError);
        [self.handlersForReplies removeObjectForKey:inMessage.controlData[kSTYInReplyToKey]];
        }

    theHandler = [self.messageHandler handlerForMessage:inMessage];
    if (theHandler)
        {
        theResult = theHandler(self, inMessage, outError);
        }


    if ([inMessage.controlData[@"close"] boolValue] == YES)
        {
        NSLog(@"Manual close");
        [self close];
        }

    return(theResult);
    }

@end
