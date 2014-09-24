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
#import "STYLogger.h"
#import "STYTransport.h"
#import "STYSocket.h"

#if TARGET_OS_IPHONE == 0
#import <Cocoa/Cocoa.h>
#endif

@interface STYPeer () <STYTransportDelegate>
@property (readwrite, nonatomic) STYMessengerMode mode;
@property (readwrite, nonatomic) STYTransport *transport;
@property (readwrite, nonatomic) NSMutableDictionary *blocksForReplies;
@property (readwrite, atomic) STYPeerState state; // TODO: Should be readonly but needed by subclasses.
@property (readwrite, nonatomic) STYMessageHandler *systemHandler; // TODO: Should be readonly but needed by subclasses.
@property (readwrite, nonatomic) STYMessageHandler *messageHandler;
@end

#pragma mark -

@implementation STYPeer

@synthesize state = _state;

- (instancetype)init
    {
    if ((self = [super init]) != NULL)
        {
        _blocksForReplies = [NSMutableDictionary dictionary];
        _UUID = [NSUUID UUID];

        _systemHandler = [[STYMessageHandler alloc] init];
        [self prepareSystemHandler];
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

        _transport = [[STYTransport alloc] initWithPeer:self socket:inSocket];
        _transport.delegate = self;
        _name = [inName copy];
        }
    return self;
    }

- (void)dealloc
    {
    [self close:NULL];
    }

#pragma mark -

- (STYPeerState)state
    {
    // TODO atomic
    return _state;
    }

- (void)setState:(STYPeerState)state
    {
    // TODO atomic
    if (_state != state)
        {
        [self willChangeToState:state fromState:_state];
        _state = state;
        [self didChangeToState:state fromState:_state];
        }
    }


#pragma mark -

- (void)prepareSystemHandler
    {
    }

- (void)open:(STYCompletionBlock)inCompletion
    {
    NSParameterAssert(self.state == kSTYPeerStateUndefined);
    self.state = kSTYPeerStateOpening;

    __weak typeof(self) weak_self = self;
    [self.transport open:^(NSError *error) {
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

        NSParameterAssert(strong_self.state == kSTYPeerStateOpening);
        strong_self.state = kSTYPeerStateHandshaking;

        if (strong_self.mode == kSTYMessengerModeClient)
            {
            [strong_self _clientPerformHandShake:inCompletion];
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
    if (self.state == kSTYPeerStateClosed)
        {
        STYLogWarning_(@"%@: Trying to close an already closed Peer", self);
        if (inCompletion != NULL)
            {
            NSError *theError = [NSError errorWithDomain:kSTYErrorDomain code:kSTYErrorCode_AlreadyClosed userInfo:NULL];
            inCompletion(theError);
            }
        return;
        }
    if ([self.delegate respondsToSelector:@selector(peerDidClose:)])
        {
        [self.delegate peerDidClose:self];
        }

    self.state = kSTYPeerStateClosed;
    [self.transport close:inCompletion];
    }

- (void)sendMessage:(STYMessage *)inMessage completion:(STYCompletionBlock)inCompletion
    {
    NSParameterAssert(inMessage != NULL);

    [self sendMessage:inMessage replyHandler:NULL completion:inCompletion];
    }

- (void)sendMessage:(STYMessage *)inMessage replyHandler:(STYMessageBlock)inReplyHandler completion:(STYCompletionBlock)inCompletion
    {
    NSParameterAssert(inMessage != NULL);

    STYMessage *theMessage = [self.transport messageForSending:inMessage];

    if (inReplyHandler != NULL)
        {
        self.blocksForReplies[theMessage.controlData[kSTYMessageIDKey]] = inReplyHandler;
        }

    [self.transport sendMessage:theMessage replyHandler:inReplyHandler completion:inCompletion];
    }

- (void)willChangeToState:(STYPeerState)inState fromState:(STYPeerState)inOldState
    {
    }

- (void)didChangeToState:(STYPeerState)inState fromState:(STYPeerState)inOldState
    {
    }

#pragma mark -

- (BOOL)_handleMessage:(STYMessage *)inMessage error:(NSError *__autoreleasing *)outError
    {
    BOOL theErrorFlag = NO;
    BOOL theHandledFlag = NO;

    STYMessageBlock theBlock = self.blocksForReplies[inMessage.controlData[kSTYInReplyToKey]];
    if (theBlock != NULL)
        {
        NSError *theError = NULL;
        theErrorFlag = theBlock(self, inMessage, outError);
        if (theErrorFlag == YES)
            {
            if (outError != NULL)
                {
                *outError = theError;
                }
            }

        if (inMessage.moreComing == NO)
            {
            [self.blocksForReplies removeObjectForKey:inMessage.controlData[kSTYInReplyToKey]];
            }

        theHandledFlag = YES;
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
            NSError *theError = NULL;
            theBlock = [theHandler blockForMessage:inMessage error:&theError];
            if (theBlock != NULL)
                {
                theErrorFlag = theBlock(self, inMessage, &theError);
                if (theErrorFlag == YES)
                    {
                    if (outError != NULL)
                        {
                        *outError = theError;
                        }
                    }

                theHandledFlag = YES;
                break;
                }
            }
        }


    if (theHandledFlag == NO)
        {
        STYLogWarning_(@"%@: No handler for message: %@", self, inMessage.controlData);

        STYMessage *theReply = [inMessage replyWithControlData:@{ kSTYCommandKey: @"error" } metadata:NULL data:NULL];
        [self sendMessage:theReply completion:NULL];
        }

    if ([inMessage.controlData[kSTYCloseKey] boolValue] == YES)
        {
        // TODO handle close
        [self close:NULL];
        }

    return theErrorFlag;
    }

#pragma mark -

// TODO: Should move onto message handler.
- (NSDictionary *)makeHelloMetadata:(NSDictionary *)inExtras
    {
    NSMutableDictionary *theMetadata = [NSMutableDictionary dictionary];
    
    if (self.name.length > 0)
        {
        theMetadata[@"name"] = self.name;
        }
        
    theMetadata[@"address"] = [self.transport.socket.address toString];
    theMetadata[@"peerAddress"] = [self.transport.socket.peerAddress toString];
    
    if (inExtras != NULL)
        {
        [theMetadata addEntriesFromDictionary:inExtras];
        }
    
    return theMetadata;
    }

#pragma mark -

- (void)_clientPerformHandShake:(STYCompletionBlock)inCompletion
    {
    NSParameterAssert(self.mode == kSTYMessengerModeClient);
    
    STYMessage *theMessage = [[STYMessage alloc] initWithControlData:@{ kSTYCommandKey: kSTYHelloCommand } metadata:[self makeHelloMetadata:NULL] data:NULL];

    __weak typeof(self) weak_self = self;
    STYMessageBlock theReplyHandler = ^(STYPeer *inPeer, STYMessage *inMessage, NSError **outError) {
        __strong typeof(self) strong_self = weak_self;
        if (strong_self == NULL)
            {
            STYLogWarning_(@"Self has been deallocated before block called.");
            return NO;
            }
            
        if ([inMessage.metadata[@"requiresChallenge"] boolValue] == YES)
            {
            NSParameterAssert(strong_self.state == kSTYPeerStateHandshaking);
            strong_self.state = kSTYPeerStateChallengeResponse;
            
            [self _clientPerformChallengeResponse:(STYCompletionBlock)inCompletion];
            
            return YES;
            }
        
        if (inCompletion != NULL)
            {
            inCompletion(NULL);
            }
            
        NSParameterAssert(strong_self.state == kSTYPeerStateHandshaking);
        strong_self.state = kSTYPeerStateReady;
        return YES;
        };

    [self sendMessage:theMessage replyHandler:theReplyHandler completion:NULL];
    }

- (void)_clientPerformChallengeResponse:(STYCompletionBlock)inCompletion
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        NSString *theSecret = NULL;
        if ([self.delegate respondsToSelector:@selector(peerRequestSecret:)]) {
            theSecret = [self.delegate peerRequestSecret:self];
        }
        else {
#if TARGET_OS_IPHONE == 0
            NSAlert *theAlert = [[NSAlert alloc] init];
            theAlert.messageText = @"Enter secret";
            [theAlert addButtonWithTitle:@"OK"];
            [theAlert addButtonWithTitle:@"Cancel"];
            
            NSTextField *theTextField = [[NSTextField alloc] initWithFrame:(CGRect){ .size = { 290, 20 } }];
            theAlert.accessoryView = theTextField;
            
            NSInteger theButton = [theAlert runModal];
            
            if (theButton == NSAlertFirstButtonReturn) {
                theSecret = theTextField.stringValue;
            }
#endif
        }
        
        if (theSecret != NULL) {
            __weak typeof(self) weak_self = self;
            STYMessage *theMessage = [[STYMessage alloc] initWithControlData:@{ kSTYCommandKey: @"_secret" } metadata:@{ @"secret": theSecret } data:NULL];
            [self sendMessage:theMessage replyHandler:^BOOL(STYPeer *inPeer, STYMessage *inMessage, NSError *__autoreleasing *outError) {
                __weak typeof(weak_self) strong_self = weak_self;
                //                NSLog(@"%@", inMessage);
                NSCParameterAssert(strong_self.state == kSTYPeerStateChallengeResponse);
                strong_self.state = kSTYPeerStateReady;
                if (inCompletion) {
                    inCompletion(NULL);
                }
                return true;
            } completion:^(NSError *error) {
                if (error != NULL) {
                    if (inCompletion) {
                        inCompletion(NULL);
                    }
                }
            }];
        }
        else {
            if (inCompletion) {
                inCompletion([NSError errorWithDomain:kSTYErrorDomain code:kSTYErrorCode_Unknown userInfo:NULL]);
            }
            [self close:nil];
        }
    });
}

#pragma mark -

- (void)transport:(STYTransport *)inTransport didReceiveMessage:(STYMessage *)inMessage;
    {
    [self _handleMessage:inMessage error:NULL];
    }

- (void)transportWillClose:(STYTransport *)inTransport
    {
    if ([self.delegate respondsToSelector:@selector(peerDidClose:)])
        {
        [self.delegate peerDidClose:self];
        }

    self.state = kSTYPeerStateClosed;

    }

@end
