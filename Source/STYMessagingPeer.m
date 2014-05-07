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

@interface STYMessagingPeer () <STYSocketDelegate>
@property (readwrite, nonatomic) STYMessengerMode mode;
@property (readwrite, nonatomic) STYSocket *socket;
@property (readwrite, nonatomic) STYAddress *peerAddress;
@property (readwrite, nonatomic) NSInteger nextOutgoingMessageID;
@property (readwrite, nonatomic) NSInteger lastIncomingMessageID;
@property (readwrite, nonatomic) NSData *data;
@property (readwrite, nonatomic) NSMutableDictionary *handlersForReplies; // TODO rename blocksForReplies
@property (readwrite, nonatomic) BOOL open;
@end

#pragma mark -

@implementation STYMessagingPeer

- (instancetype)init
    {
    if ((self = [super init]) != NULL)
        {
        _nextOutgoingMessageID = 0;
        _lastIncomingMessageID = -1;
        _handlersForReplies = [NSMutableDictionary dictionary];
        _messageHandler = [[STYMessageHandler alloc] init];
        }
    return self;
    }

- (instancetype)initWithMode:(STYMessengerMode)inMode socket:(STYSocket *)inSocket name:(NSString *)inName
    {
    if ((self = [self init]) != NULL)
        {
        NSParameterAssert(inMode != kSTYMessengerModeUndefined);
        NSParameterAssert(inSocket != NULL);

        _mode = inMode;
        _socket = inSocket;
        _socket.delegate = self;
        _name = [inName copy];
        }
    return self;
    }

- (NSString *)description
    {
    return([NSString stringWithFormat:@"%@ (%d, %@, %@)", [super description], (int)self.mode, self.socket, self.name]);
    }

- (void)open:(STYCompletionBlock)inCompletion
    {
    NSParameterAssert(self.socket != NULL);
    NSParameterAssert(self.open == NO);

    [self.socket open:^(NSError *error) {

        if (error)
            {
            if (inCompletion)
                {
                inCompletion(error);
                }
            return;
            }

        if (self.socket.connected)
            {
            self.peerAddress = self.socket.peerAddress;
            }

        self.open = YES;

        if (self.mode == kSTYMessengerModeClient)
            {
            STYMessage *theMessage = [[STYMessage alloc] initWithCommand:kSTYHelloCommand metadata:NULL data:NULL];
            [self sendMessage:theMessage completion:inCompletion];
            }
        else
            {
            if (inCompletion)
                {
                inCompletion(NULL);
                }
            }
        }];
    }

- (void)close:(STYCompletionBlock)inCompletion
    {
    self.open = NO;
    [self.socket close:inCompletion];
    }

- (void)sendMessage:(STYMessage *)inMessage completion:(STYCompletionBlock)inCompletion
    {
    NSParameterAssert(inMessage != NULL);

    [self sendMessage:inMessage replyHandler:NULL completion:inCompletion];
    }

- (void)sendMessage:(STYMessage *)inMessage replyHandler:(STYMessageBlock)inReplyHandler completion:(STYCompletionBlock)inCompletion
    {
    NSParameterAssert(inMessage != NULL);

    // TODO - copying the message is weird. Be much nicer to mutate it.
    STYMutableMessage *theMessage = [inMessage mutableCopy];
    theMessage.messageID = self.nextOutgoingMessageID++;

    if (inReplyHandler != NULL)
        {
        self.handlersForReplies[theMessage.controlData[kSTYMessageIDKey]] = inReplyHandler;
        }

    NSData *theBuffer = [theMessage buffer:NULL];
    [self _sendData:theBuffer completion:^(NSError *error) {
        if (error == NULL)
            {
            if (self.tap)
                {
                self.tap(self, inMessage, NULL);
                }
            }

        if (inCompletion)
            {
            inCompletion(error);
            }
        }];
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
                if (self.tap)
                    {
                    self.tap(self, theMessage, NULL);
                    }

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
    NSParameterAssert(inData);
    NSParameterAssert(self.socket.queue);
    NSParameterAssert(self.socket.channel);

    dispatch_data_t theData = dispatch_data_create([inData bytes], [inData length], self.socket.queue, DISPATCH_DATA_DESTRUCTOR_DEFAULT);

    dispatch_io_write(self.socket.channel, 0, theData, self.socket.queue, ^(bool done, dispatch_data_t data, int error) {
        // TODO use error in completion block
//        NSLog(@"dispatch_io_write: %d %zu %d", done, data == NULL ? 0 : dispatch_data_get_size(data), error);
        if (inCompletion)
            {
            inCompletion(NULL);
            }
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

        if (inMessage.moreComing == NO)
            {
            [self.handlersForReplies removeObjectForKey:inMessage.controlData[kSTYInReplyToKey]];
            }

        if (theResult == YES)
            {
            return(theResult);;
            }
        }

    NSArray *theHandlers = [self.messageHandler handlersForMessage:inMessage];
    if (theHandlers.count == 0)
        {
        NSLog(@"No handler for message: %@", inMessage.controlData);
        return(NO);
        }

    for (theHandler in theHandlers)
        {
        theResult = theHandler(self, inMessage, outError);
        if (theResult == YES)
            {
            break;
            }
        }

    if ([inMessage.controlData[kSTYCloseKey] boolValue] == YES)
        {
        NSLog(@"Manual close");

        // TODO handle close
        [self close:NULL];
        }

    return(theResult);
    }

#pragma mark -

- (void)socketHasDataAvailable:(STYSocket *)inSocket
    {
    [self _read:NULL];
    }

- (void)socketDidClose:(STYSocket *)inSocket;
    {
    NSLog(@"socketDidClose:");
    }


@end
