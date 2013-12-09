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

@interface STYMessagingPeer ()
@property (readonly, nonatomic, strong) __attribute__((NSObject)) CFSocketRef socket;
@property (readonly, nonatomic) dispatch_queue_t queue;
@property (readonly, nonatomic) dispatch_io_t channel;
@property (readonly, nonatomic) dispatch_source_t readSource;
@property (readwrite, nonatomic) NSInteger nextOutgoingMessageID;
@property (readwrite, nonatomic) NSInteger lastIncomingMessageID;
@property (readwrite, nonatomic) NSData *data;
@property (readwrite, nonatomic) NSMutableDictionary *handlersForReplies;
@property (readwrite, nonatomic) NSMutableDictionary *handlersForCommands;
@end

#pragma mark -

@implementation STYMessagingPeer

- (instancetype)initWithSocket:(CFSocketRef)inSocket
    {
    if ((self = [super init]) != NULL)
        {
        _socket = inSocket;
        _queue = dispatch_get_main_queue();
        _channel = dispatch_io_create(DISPATCH_IO_STREAM, CFSocketGetNative(self.socket), dispatch_get_main_queue(), ^(int error) {
            NSLog(@"CLEANUP");
            });
        dispatch_io_set_low_water(_channel, 1);

        _nextOutgoingMessageID = 0;
        _lastIncomingMessageID = -1;
        _handlersForReplies = [NSMutableDictionary dictionary];
        _handlersForCommands = [NSMutableDictionary dictionary];

        _readSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_READ, CFSocketGetNative(_socket), 0, _queue);
        dispatch_source_set_cancel_handler(_readSource, ^{
            NSLog(@"CANCELED ************************");
            });
        dispatch_source_set_event_handler(_readSource, ^{
//            NSLog(@"READ");
            [self read];
            });

        dispatch_resume(_readSource);

        __weak typeof(self) weak_self = self;
        [self addCommand:@"hello" handler:^(STYMessagingPeer *inPeer, STYMessage *inMessage, NSError **outError) {

            __strong typeof(weak_self) strong_self = weak_self;

            NSDictionary *theControlData = @{
                @"cmd": @"hello.reply",
                @"in-reply-to": inMessage.controlData[@"msgid"],
                };

            STYMessage *theResponse = [[STYMessage alloc] initWithControlData:theControlData metadata:NULL data:NULL];
            [strong_self sendMessage:theResponse replyBlock:NULL];

            NSLog(@"%@", inMessage);
            return(YES);
            }];
        [self addCommand:@"hello.reply" handler:^(STYMessagingPeer *inPeer, STYMessage *inMessage, NSError **outError) {
            NSLog(@"%@", inMessage);
            return(YES);
            }];

        }
    return self;
    }

- (instancetype)initWithSocket:(CFSocketRef)inSocket messageHandlers:(NSDictionary *)inMessageHandlers;
    {
    if ((self = [self initWithSocket:inSocket]) != NULL)
        {
        [self.handlersForCommands addEntriesFromDictionary:inMessageHandlers];
        }
    return self;
    }



- (void)sendMessage:(STYMessage *)inMessage replyBlock:(STYMessageBlock)inBlock
    {
    NSMutableDictionary *theControlData = [inMessage.controlData mutableCopy];
    theControlData[@"msgid"] = @(self.nextOutgoingMessageID);
    self.nextOutgoingMessageID += 1;

    STYMessage *theMessage = [[STYMessage alloc] initWithControlData:theControlData metadata:inMessage.metadata data:inMessage.data];

    if (inBlock != NULL)
        {
        self.handlersForReplies[theControlData[@"msgid"]] = inBlock;
        }

    __block NSData *theBuffer = [theMessage buffer:NULL];
    dispatch_data_t theData = dispatch_data_create([theBuffer bytes], [theBuffer length], self.queue, ^{
        theBuffer = NULL;
        });

    dispatch_io_write(self.channel, 0, theData, self.queue, ^(bool done, dispatch_data_t data, int error) {
//      NSLog(@"%d %@ %d", done, data, error);
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

- (void)close
    {
    dispatch_io_close(self.channel, 0);
    dispatch_source_cancel(self.readSource);
    }

- (BOOL)_handleMessage:(STYMessage *)inMessage error:(NSError *__autoreleasing *)outError
    {
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
        BOOL theResult = theHandler(self, inMessage, outError);
        [self.handlersForReplies removeObjectForKey:inMessage.controlData[@"in-reply-to"]];
        return(theResult);
        }

    theHandler = self.handlersForCommands[inMessage.controlData[@"cmd"]];
    if (theHandler)
        {
        BOOL theResult = theHandler(self, inMessage, outError);
        return(theResult);
        }

    return(NO);
    }

- (void)addCommand:(NSString *)inCommand handler:(STYMessageBlock)inBlock;
    {
    [self.handlersForCommands setObject:inBlock forKey:inCommand];
    }

@end
