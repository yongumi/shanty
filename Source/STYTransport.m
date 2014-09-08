//
//  STYTransport.m
//  shanty
//
//  Created by Jonathan Wight on 8/25/14.
//  Copyright (c) 2014 schwa.io. All rights reserved.
//

#import "STYTransport.h"

#import "STYSocket.h"
#import "STYMessage.h"
#import "STYConstants.h"
#import "STYLogger.h"
#import "STYDataScanner+Message.h"

@interface STYTransport () <STYSocketDelegate>
@property (readwrite, atomic) STYTransportState state;
@property (readwrite, nonatomic) STYSocket *socket;
//@property (readwrite, nonatomic) STYMessageHandler *systemHandler;
@property (readwrite, atomic) NSInteger nextOutgoingMessageID;
@property (readwrite, atomic) NSInteger lastIncomingMessageID;
@property (readwrite, nonatomic) NSData *data;
//@property (readwrite, nonatomic) NSMutableDictionary *blocksForReplies;
@end

#pragma mark -

@implementation STYTransport

@synthesize state = _state;

- (instancetype)init
    {
    if ((self = [super init]) != NULL)
        {
        _nextOutgoingMessageID = 0;
        _lastIncomingMessageID = -1;
        }
    return self;
    }

- (instancetype)initWithPeer:(STYPeer *)inPeer socket:(STYSocket *)inSocket
    {
    if ((self = [self init]) != NULL)
        {
        NSParameterAssert(inSocket != NULL);

        _peer = inPeer;
        _socket = inSocket;
        _socket.delegate = self;
        }
    return self;
    }

- (void)dealloc
    {
    [self close:NULL];
    }

#pragma mark -

- (void)open:(STYCompletionBlock)inCompletion
    {
    NSParameterAssert(self.socket != NULL);

    NSParameterAssert(self.state == kSTYTransportStateUndefined);
    self.state = kSTYTransportStateOpening;

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

        NSParameterAssert(strong_self.state == kSTYTransportStateOpening);
        strong_self.state = kSTYTransportStateReady;

        if (inCompletion)
            {
            inCompletion(NULL);
            }
        }];
    }

- (void)close:(STYCompletionBlock)inCompletion
    {
    if (self.state == kSTYTransportStateClosed)
        {
        STYLogWarning_(@"%@: Trying to close an already closed Peer", self);
        #warning TODO - call inCompletion with error?
        return;
        }

    NSParameterAssert(self.state == kSTYTransportStateReady);
    self.state = kSTYTransportStateClosed;

    if ([self.delegate respondsToSelector:@selector(transportWillClose:)])
        {
        [self.delegate transportWillClose:self];
        }

    [self.socket close:inCompletion];
    }

- (STYMessage *)messageForSending:(STYMessage *)inMessage
    {
    // TODO - copying the message is weird. Be much nicer to mutate it.
    STYMutableMessage *theMessage = [inMessage mutableCopy];
    theMessage.messageID = self.nextOutgoingMessageID++;
    return theMessage;
    }

- (void)sendMessage:(STYMessage *)inMessage completion:(STYCompletionBlock)inCompletion
    {
    NSParameterAssert(inMessage != NULL);

    [self sendMessage:inMessage replyHandler:NULL completion:inCompletion];
    }

- (void)sendMessage:(STYMessage *)inMessage replyHandler:(STYMessageBlock)inReplyHandler completion:(STYCompletionBlock)inCompletion
    {
    NSParameterAssert(inMessage != NULL);

    NSData *theBuffer = [inMessage buffer:NULL];

    __weak typeof(self) weak_self = self;

    dispatch_data_t theData = dispatch_data_create([theBuffer bytes], [theBuffer length], self.socket.queue, DISPATCH_DATA_DESTRUCTOR_DEFAULT);
    [self.socket write:theData completion:^(NSError *error) {
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
                strong_self.tap(strong_self.peer, inMessage, NULL);
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

    __weak typeof(self) weak_self = self;
    [self.socket read:^(bool done, dispatch_data_t data, int error) {
    
//        NSLog(@"%d %d %d", done, dispatch_data_get_size(data), error);
    
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

        if (error == ECANCELED)
            {
            return;
            }
        else if (error != 0)
            {
            /// TODO handle error (via completion block)
            
            NSError *thePOSIXError = [NSError errorWithDomain:NSPOSIXErrorDomain code:error userInfo:NULL];
            
            STYLogError_(@"%@: dispatch_io_read: %@", self, thePOSIXError);
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
                    strong_self.tap(strong_self.peer, theMessage, NULL);
                    }

                if ([self.delegate respondsToSelector:@selector(transport:didReceiveMessage:)])
                    {
                    [self.delegate transport:self didReceiveMessage:theMessage];
                    }
                }
            }

        if (done)
            {
            strong_self.data = [theDataScanner remainingData];

            if (error == 0 && dispatch_data_get_size(data) == 0 && self.state != kSTYTransportStateClosed)
                {
                [strong_self close:NULL];
                }
            }
        }];
    }

#pragma mark -

- (void)socketHasDataAvailable:(STYSocket *)inSocket
    {
    [self _read:NULL];
    }

- (void)socketDidClose:(STYSocket *)inSocket;
    {
//    STYLogDebug_(@"socketDidClose called but we're not doing much with it!");
    }

@end
