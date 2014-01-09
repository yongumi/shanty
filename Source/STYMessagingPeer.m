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

- (void)openWithMode:(STYMessengerMode)inMode socket:(STYSocket *)inSocket completion:(STYCompletionBlock)inCompletion
    {
    self.mode = inMode;
    self.socket = inSocket;

    [self.socket start:^{
        // TODO use completion block
        [self _read:NULL];

        if (inCompletion)
            {
            inCompletion(NULL);
            }
        }];
    }

- (void)close:(STYCompletionBlock)inCompletion
    {
    [self.socket stop];
    }

- (void)sendMessage:(STYMessage *)inMessage completion:(STYCompletionBlock)inCompletion
    {
    NSParameterAssert(inMessage != NULL);

    // TODO - copying the message is weird. Be much nicer to mutate it.
    STYMessage *theMessage = [self _messageWithUpdatedMessageID:inMessage];
    NSData *theBuffer = [theMessage buffer:NULL];
    [self _sendData:theBuffer completion:inCompletion];
    }

- (void)sendMessage:(STYMessage *)inMessage replyHandler:(STYMessageBlock)inReplyHandler completion:(STYCompletionBlock)inCompletion
    {
    NSParameterAssert(inMessage != NULL);

    // TODO - copying the message is weird. Be much nicer to mutate it.
    STYMessage *theMessage = [self _messageWithUpdatedMessageID:inMessage];
    if (inReplyHandler != NULL)
        {
        self.handlersForReplies[theMessage.controlData[kSTYMessageIDKey]] = inReplyHandler;
        }

    [self sendMessage:theMessage completion:inCompletion];
    }

- (STYMessage *)_messageWithUpdatedMessageID:(STYMessage *)inMessage
    {
    STYMessage *theMessage = inMessage;

    NSMutableDictionary *theControlData = [theMessage.controlData mutableCopy];
    if (theControlData[kSTYMessageIDKey] == NULL)
        {
        theControlData[kSTYMessageIDKey] = @(self.nextOutgoingMessageID);
        self.nextOutgoingMessageID += 1;
        theMessage = [[STYMessage alloc] initWithControlData:theControlData metadata:theMessage.metadata data:theMessage.data];
        }
    return(theMessage);
    }

#pragma mark -

- (void)_read:(STYCompletionBlock)inCompletion
    {
    STYDataScanner *theDataScanner = [[STYDataScanner alloc] initWithData:self.data];
    theDataScanner.dataEndianness = DataScannerDataEndianness_Network;

    dispatch_io_read(self.socket.channel, 0, SIZE_MAX, self.socket.queue, ^(bool done, dispatch_data_t data, int error) {

        if (error)
            {
            /// TODO handle error (via completion block)
            NSLog(@"Error: %d", error);
            return;
            }

        if (dispatch_data_get_size(data) > 0)
            {
            [theDataScanner feedData:(NSData *)data];

            STYMessage *theMessage = NULL;
            // TODO handle error (via completion block)
            while ([theDataScanner scanMessage:&theMessage error:NULL] == YES)
                {
                // TODO handle error (via completion block)
                [self _handleMessage:theMessage error:NULL];
                }
            }

        if (done)
            {
            self.data = [theDataScanner remainingData];

            if (error == 0 && dispatch_data_get_size(data) == 0)
                {
                [self close:NULL];
                }
            }
        });
    }

- (void)_sendData:(NSData *)inData completion:(STYCompletionBlock)inCompletion
    {
    dispatch_data_t theData = dispatch_data_create([inData bytes], [inData length], self.socket.queue, DISPATCH_DATA_DESTRUCTOR_DEFAULT);

    dispatch_io_write(self.socket.channel, 0, theData, self.socket.queue, ^(bool done, dispatch_data_t data, int error) {
        // TODO use completion block
        NSLog(@"dispatch_io_write: %d %zu %d", done, dispatch_data_get_size(data), error);
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

    if ([inMessage.controlData[kSTYCloseKey] boolValue] == YES)
        {
        NSLog(@"Manual close");

        // TODO handle close
        [self close:NULL];
        }

    return(theResult);
    }

@end
