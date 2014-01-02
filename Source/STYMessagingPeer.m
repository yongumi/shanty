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

@interface STYMessagingPeer ()
@property (readwrite, nonatomic, strong) __attribute__((NSObject)) CFSocketRef socket;
@property (readwrite, nonatomic) dispatch_queue_t queue;
@property (readwrite, nonatomic) dispatch_io_t channel;
@property (readwrite, nonatomic) dispatch_source_t readSource;
@property (readwrite, nonatomic) NSInteger nextOutgoingMessageID;
@property (readwrite, nonatomic) NSInteger lastIncomingMessageID;
@property (readwrite, nonatomic) NSData *data;
@property (readwrite, nonatomic) NSMutableDictionary *handlersForReplies; // TODO rename blocksForReplies
@end

#pragma mark -

@implementation STYMessagingPeer

- (instancetype)initWithSocket:(CFSocketRef)inSocket
    {
    if ((self = [super init]) != NULL)
        {
        _socket = inSocket;
//        _queue = dispatch_get_main_queue();
        _queue = dispatch_queue_create("test", DISPATCH_QUEUE_SERIAL);

        _channel = dispatch_io_create(DISPATCH_IO_STREAM, CFSocketGetNative(self.socket), dispatch_get_main_queue(), ^(int error) {
            NSLog(@"TODO: Clean up");
            });
        dispatch_io_set_low_water(_channel, 1);

        _nextOutgoingMessageID = 0;
        _lastIncomingMessageID = -1;
        _handlersForReplies = [NSMutableDictionary dictionary];

        _readSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_READ, CFSocketGetNative(_socket), 0, _queue);
        dispatch_source_set_cancel_handler(_readSource, ^{
            NSLog(@"Read source canceled. Other side closed?");
            CFSocketInvalidate(self.socket);

            if ([self.delegate respondsToSelector:@selector(messagingPeerRemoteDidDisconnect:)])
                {
                [self.delegate messagingPeerRemoteDidDisconnect:self];
                }

            });
        dispatch_source_set_event_handler(_readSource, ^{
//            NSLog(@"READ");
            [self read];
            });

        dispatch_resume(_readSource);
        }
    return self;
    }

- (instancetype)initWithSocket:(CFSocketRef)inSocket messageHandler:(STYMessageHandler *)inMessageHandler
    {
    if ((self = [self initWithSocket:inSocket]) != NULL)
        {
        _messageHandler = inMessageHandler;
        }
    return self;
    }

- (STYAddress *)address
    {
    NSData *theAddressData = (__bridge_transfer NSData *)CFSocketCopyAddress(self.socket);
    STYAddress *theAddress = [[STYAddress alloc] initWithData:theAddressData];
    return(theAddress);
    }

- (STYAddress *)peerAddress
    {
    NSData *theAddressData = (__bridge_transfer NSData *)CFSocketCopyPeerAddress(self.socket);
    STYAddress *theAddress = [[STYAddress alloc] initWithData:theAddressData];
    return(theAddress);
    }

- (void)close
    {
    if (self.channel != NULL)
        {
        dispatch_io_close(self.channel, 0);
        self.channel = NULL;
        }
    if (self.readSource != NULL)
        {
        dispatch_source_cancel(self.readSource);
        self.readSource = NULL;
        }
    }

- (void)sendMessage:(STYMessage *)inMessage replyBlock:(STYMessageBlock)inBlock
    {
    NSParameterAssert(inMessage != NULL);
    NSParameterAssert(self.channel != NULL);
    NSParameterAssert(self.queue != NULL);

    NSMutableDictionary *theControlData = [inMessage.controlData mutableCopy];
    theControlData[@"msgid"] = @(self.nextOutgoingMessageID);
    self.nextOutgoingMessageID += 1;

    STYMessage *theMessage = [[STYMessage alloc] initWithControlData:theControlData metadata:inMessage.metadata data:inMessage.data];

    if (inBlock != NULL)
        {
        self.handlersForReplies[theControlData[@"msgid"]] = inBlock;
        }

    __block NSData *theBuffer = [theMessage buffer:NULL];
    dispatch_data_t theData = dispatch_data_create([theBuffer bytes], [theBuffer length], self.queue, DISPATCH_DATA_DESTRUCTOR_DEFAULT);

    dispatch_io_write(self.channel, 0, theData, self.queue, ^(bool done, dispatch_data_t data, int error) {
       // NSLog(@"ERROR? DONE: %d DATASIZE: %d ERROR: %d", done, data ? dispatch_data_get_size(data) : 0, error);
        });
    }

- (void)read
    {
    STYDataScanner *theDataScanner = [[STYDataScanner alloc] initWithData:self.data];
    theDataScanner.dataEndianness = DataScannerDataEndianness_Network;

    dispatch_io_read(self.channel, 0, SIZE_MAX, self.queue, ^(bool done, dispatch_data_t data, int error) {

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


- (BOOL)_handleMessage:(STYMessage *)inMessage error:(NSError *__autoreleasing *)outError
    {
    BOOL theResult = NO;

    NSInteger incoming_message_id = [inMessage.controlData[@"msgid"] integerValue];
    if (self.lastIncomingMessageID != -1 && incoming_message_id != self.lastIncomingMessageID + 1)
        {
        NSLog(@"Error: message id mismatch.");
        return(NO);
        }

    self.lastIncomingMessageID = incoming_message_id;

    STYMessageBlock theHandler = self.handlersForReplies[inMessage.controlData[@"in-reply-to"]];
    if (theHandler)
        {
        theResult = theHandler(self, inMessage, outError);
        [self.handlersForReplies removeObjectForKey:inMessage.controlData[@"in-reply-to"]];
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
