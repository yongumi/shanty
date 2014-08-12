//
//  STYPeer.m
//  Shanty
//
//  Created by Jonathan Wight on 11/4/13.
//  Copyright (c) 2013 schwa.io. All rights reserved.
//

#import "STYPeer.h"

#import "STYMessage.h"
#import "STYDataScanner+Message.h"
#import "STYMessageHandler.h"
#import "STYAddress.h"
#import "STYConstants.h"
#import "STYSocket.h"
#import "STYLogger.h"

@interface STYPeer () <STYSocketDelegate>
@property (readwrite, nonatomic) STYMessengerMode mode;
@property (readwrite, nonatomic) STYPeerState state;
@property (readwrite, nonatomic) STYSocket *socket;
@property (readwrite, nonatomic) STYMessageHandler *systemHandler;
@property (readwrite, nonatomic) STYAddress *peerAddress;
@property (readwrite, nonatomic) NSInteger nextOutgoingMessageID;
@property (readwrite, nonatomic) NSInteger lastIncomingMessageID;
@property (readwrite, nonatomic) NSData *data;
@property (readwrite, nonatomic) NSMutableDictionary *handlersForReplies; // TODO rename blocksForReplies
@end

#pragma mark -

@implementation STYPeer

- (instancetype)init
    {
    if ((self = [super init]) != NULL)
        {
        _nextOutgoingMessageID = 0;
        _lastIncomingMessageID = -1;
        _handlersForReplies = [NSMutableDictionary dictionary];
        _UUID = [NSUUID UUID];
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
        _systemHandler = [[STYMessageHandler alloc] init];

        __weak typeof(self) weak_self = self;

        // TODO: Technically we only need this if the peer is a server.
        [_systemHandler addCommand:kSTYHelloCommand block:^(STYPeer *inPeer, STYMessage *inMessage, NSError **outError) {
            __strong typeof(self) strong_self = weak_self;
            NSDictionary *theControlData = @{
                kSTYCommandKey: kSTYHelloReplyCommand,
                kSTYInReplyToKey: inMessage.controlData[kSTYMessageIDKey],
                };

            STYMessage *theResponse = [[STYMessage alloc] initWithControlData:theControlData metadata:NULL data:NULL];
            [inPeer sendMessage:theResponse completion:NULL];

            strong_self.state = kSTYPeerStateReady;

            return(YES);
            }];
        }
    return self;
    }

- (void)dealloc
    {
    [self close:NULL];
    }

- (NSString *)description
    {
    return([NSString stringWithFormat:@"%@ (mode:%d, state:%d, %@, %@)", [super description], (int)self.mode, (int)self.state, self.socket, self.name]);
    }

- (void)open:(STYCompletionBlock)inCompletion
    {
    NSParameterAssert(self.socket != NULL);
    NSParameterAssert(self.state == kSTYPeerStateUndefined);

    self.state = kSTYPeerStateOpening;

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

        [strong_self _didOpen:inCompletion];
        }];
    }

- (void)close:(STYCompletionBlock)inCompletion
    {
    if (self.state == kSTYPeerStateClosed)
        {
        STYLogWarning_(@"%@: Trying to close an already closed Peer", self);
        #warning TODO - call inCompletion with error?
        return;
        }
    if ([self.delegate respondsToSelector:@selector(peerDidClose:)])
        {
        [self.delegate peerDidClose:self];
        }

    self.state = kSTYPeerStateClosed;

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
            if (inCompletion)
                {
                NSError *theError = [NSError errorWithDomain:kSTYErrorDomain code:kSTYErrorCode_Unknown userInfo:NULL];
                inCompletion(theError);
                }
            return;
            }

        if (error == NULL)
            {
            if (strong_self.tap)
                {
                strong_self.tap(strong_self, theMessage, NULL);
                }
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
    NSParameterAssert(self.state == kSTYPeerStateOpening);
    self.state = kSTYPeerStateHandshaking;

    if (self.mode == kSTYMessengerModeClient)
        {
        STYMessage *theMessage = [[STYMessage alloc] initWithControlData:@{ kSTYCommandKey: kSTYHelloCommand } metadata:NULL data:NULL];

        STYMessageBlock theReplyHandler = ^(STYPeer *inPeer, STYMessage *inMessage, NSError **outError) {
            self.state = kSTYPeerStateReady;
            return YES;
            };

        [self sendMessage:theMessage replyHandler:theReplyHandler completion:inCompletion];
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
    STYDataScanner *theDataScanner = [[STYDataScanner alloc] initWithData:self.data];
    theDataScanner.dataEndianness = DataScannerDataEndianness_Network;

    __weak typeof(self) weak_self = self;
    dispatch_io_read(self.socket.channel, 0, SIZE_MAX, self.socket.queue, ^(bool done, dispatch_data_t data, int error) {
        __strong typeof(weak_self) strong_self = weak_self;
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
            STYLogError_(@"%@: dispatch_io_read: %d", self, error);
            return;
            }

        if (dispatch_data_get_size(data) > 0)
            {
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
                [strong_self _handleMessage:theMessage error:NULL];
                }
            }

        if (done)
            {
            strong_self.data = [theDataScanner remainingData];

            if (error == 0 && dispatch_data_get_size(data) == 0)
                {
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
        if (inCompletion)
            {
            inCompletion(NULL);
            }
        });
    }

- (BOOL)_handleMessage:(STYMessage *)inMessage error:(NSError *__autoreleasing *)outError
    {
    BOOL theHandledFlag = NO;

    NSInteger incoming_message_id = [inMessage.controlData[kSTYMessageIDKey] integerValue];
    if (self.lastIncomingMessageID != -1 && incoming_message_id != self.lastIncomingMessageID + 1)
        {
        STYLogError_(@"%@: Message id mismatch.", self);
        return(NO);
        }

    self.lastIncomingMessageID = incoming_message_id;

    STYMessageBlock theBlock = self.handlersForReplies[inMessage.controlData[kSTYInReplyToKey]];
    if (theBlock)
        {
        theHandledFlag = theBlock(self, inMessage, outError);
        if (inMessage.moreComing == NO)
            {
            [self.handlersForReplies removeObjectForKey:inMessage.controlData[kSTYInReplyToKey]];
            }
        }

    if (theHandledFlag == NO)
        {
        NSMutableArray *theHandlers = [NSMutableArray arrayWithObjects:self.systemHandler, NULL];

        if (self.messageHandler == NULL)
            {
            STYLogWarning_(@"%@: No handlers", self);
            }
        else
            {
            [theHandlers addObject:self.messageHandler];
            }


        for (STYMessageHandler *theHandler in theHandlers)
            {
            NSArray *theBlocks = [theHandler blocksForMessage:inMessage];
            for (theBlock in theBlocks)
                {
                theHandledFlag = theBlock(self, inMessage, outError);
                if (theHandledFlag == YES)
                    {
                    break;
                    }
                }

            if (theHandledFlag == YES)
                {
                break;
                }
            }
        }

    if (theHandledFlag == NO)
        {
        STYLogWarning_(@"%@: No handler for message: %@", self, inMessage.controlData);
        }

    if ([inMessage.controlData[kSTYCloseKey] boolValue] == YES)
        {
        // TODO handle close
        [self close:NULL];
        }

    return(theHandledFlag);
    }

#pragma mark -

- (void)socketHasDataAvailable:(STYSocket *)inSocket
    {
    [self _read:NULL];
    }

- (void)socketDidClose:(STYSocket *)inSocket;
    {
    }

@end
