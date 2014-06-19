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
#import "STYLogger.h"

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
    // STYLogDebug_(@"STYMessagingPeer init");
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

- (void)dealloc
    {
    // STYLogDebug_(@"STYMessagingPeer dealloc");
    [self close:NULL];
    }

- (NSString *)description
    {
    return([NSString stringWithFormat:@"%@ (%d, %@, %@)", [super description], (int)self.mode, self.socket, self.name]);
    }

- (void)open:(STYCompletionBlock)inCompletion
    {
    NSParameterAssert(self.socket != NULL);
    NSParameterAssert(self.open == NO);

    STYLogDebug_(@"Opening socket…");
    __weak typeof(self) weak_self = self;
    [self.socket open:^(NSError *error) {
        __strong typeof(weak_self) strong_self = weak_self;
        if (strong_self == NULL)
            {
            if (inCompletion)
                {
                NSError *theError = [NSError errorWithDomain:kSTYErrorDomain code:kSTYErrorCode_Unknown userInfo:NULL];
                inCompletion(theError);
                }
            return;
            }

        if (error)
            {
            if (inCompletion)
                {
                inCompletion(error);
                }
            return;
            }

        if (strong_self.socket.connected == YES)
            {
            strong_self.peerAddress = strong_self.socket.peerAddress;
            }

        strong_self.open = YES;

        [strong_self _didOpen:inCompletion];
        }];
    }

- (void)close:(STYCompletionBlock)inCompletion
    {
    if (self.open == NO)
        {
        STYLogDebug_(@"Trying to close an already closed Peer");
        #warning TODO - call inCompletion with error?
        return;
        }
    if ([self.delegate respondsToSelector:@selector(peerDidClose:)])
        {
        [self.delegate peerDidClose:self];
        }
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

    __weak typeof(self) weak_self = self;
    [self _sendData:theBuffer completion:^(NSError *error) {
        __strong typeof(weak_self) strong_self = weak_self;
        if (strong_self == NULL)
            {
            // STYLogDebug_(@"strong_self is NULL");
            if (inCompletion)
                {
                NSError *theError = [NSError errorWithDomain:kSTYErrorDomain code:kSTYErrorCode_Unknown userInfo:NULL];
                inCompletion(theError);
                }
            return;
            }

        if (error == NULL)
            {
                STYLogDebug_(@"no error: %@", strong_self.tap);
            if (strong_self.tap)
                {
                strong_self.tap(strong_self, inMessage, NULL);
                }
            }
        else
            {
            // STYLogDebug_(@"error: %@", error);
            }

        if (inCompletion)
            {
            inCompletion(error);
            }
        }];
    }

#pragma mark -

- (void)_didOpen:(STYCompletionBlock)inCompletion
    {
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
    }

- (void)_read:(STYCompletionBlock)inCompletion
    {
    // STYLogDebug_(@"STYMessagingPeer _read: %@", self);
    STYDataScanner *theDataScanner = [[STYDataScanner alloc] initWithData:self.data];
    theDataScanner.dataEndianness = DataScannerDataEndianness_Network;
    void* originalPointer = (__bridge void*)self;
    void* originalSocket = (__bridge void*)self.socket;

    __weak typeof(self) weak_self = self;
    // STYLogDebug_(@"STYMessagingPeer OUTER STRONG SELF: %p (%p)", self, originalPointer);
    // STYLogDebug_(@"STYMessagingPeer OUTER WEAK SELF: %p (%p)", weak_self, originalPointer);
    dispatch_io_read(self.socket.channel, 0, SIZE_MAX, self.socket.queue, ^(bool done, dispatch_data_t data, int error)
        {
        __strong typeof(weak_self) strong_self = weak_self;
        // STYLogDebug_(@"STYMessagingPeer INNER WEAK SELF: %p (%p)", weak_self, originalPointer);
        // STYLogDebug_(@"STYMessagingPeer INNER STRONG SELF: %p (%p)", strong_self, originalPointer);
        // STYLogDebug_(@"[STYMessagingPeer _read] original socket: %p", originalSocket);
        if (strong_self == NULL)
            {
            if (inCompletion != NULL)
                {
                NSError *theError = [NSError errorWithDomain:kSTYErrorDomain code:kSTYErrorCode_Unknown userInfo:NULL];
                inCompletion(theError);
                }
            return;
            }

        if (error != 0)
            {
            /// TODO handle error (via completion block)
            // STYLogDebug_(@"[STYMessagingPeer _read].readBlock: Error: %d", error);
            return;
            }

        if (dispatch_data_get_size(data) > 0)
            {
            // STYLogDebug_(@"[STYMessagingPeer _read].feedData");
            [theDataScanner feedData:(NSData *)data];

            STYMessage *theMessage = NULL;
            // TODO handle error (via completion block)
            while ([theDataScanner scanMessage:&theMessage error:NULL] == YES)
                {
                if (strong_self.tap)
                    {
                    strong_self.tap(strong_self, theMessage, NULL);
                    }

                // TODO handle error (via completion block)
                // STYLogDebug_(@"[STYMessagingPeer _read]._handleMessage");
                [strong_self _handleMessage:theMessage error:NULL];
                }
            }

        if (done)
            {
            // STYLogDebug_(@"Error: [STYMessagingPeer _read].done");
            strong_self.data = [theDataScanner remainingData];

            if (error == 0 && dispatch_data_get_size(data) == 0 && strong_self.open == YES)
                {
                // STYLogDebug_(@"Error: [STYMessagingPeer _read].done.close");
                [strong_self close:NULL];
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
        // STYLogDebug_(@"[STYMessagingPeer _sendData] write complete: %@, inCompletion: %@", error, inCompletion);
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
        // STYLogDebug_(@"[STYMessagingPeer _handleMessage] Error: message id mismatch.");
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
        STYLogDebug_(@"No handler for message: %@", inMessage.controlData);
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
    // STYLogDebug_(@"socketDidClose:");
    }


@end
