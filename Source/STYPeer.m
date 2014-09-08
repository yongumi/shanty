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

@interface STYPeer () <STYTransportDelegate>
@property (readwrite, nonatomic) STYMessengerMode mode;
@property (readwrite, atomic) STYPeerState state;
@property (readwrite, nonatomic) STYTransport *transport;
@property (readwrite, nonatomic) STYMessageHandler *systemHandler;
@property (readwrite, nonatomic) STYAddress *peerAddress;
@property (readwrite, nonatomic) NSMutableDictionary *blocksForReplies;
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
        _systemHandler = [self _makeSystemHandler];
        }
    return self;
    }

- (void)dealloc
    {
    [self close:NULL];
    }

//- (NSString *)description
//    {
//    return([NSString stringWithFormat:@"%@ (mode:%d, state:%d, %@, %@)", [super description], (int)self.mode, (int)self.state, self.socket, self.name]);
//    }

- (STYPeerState)state
    {
    @synchronized(self)
        {
        return _state;
        }
    }

- (void)setState:(STYPeerState)state
    {
    @synchronized(self)
        {
        STYLogDebug_(@"STATE CHANGE: %d -> %d", _state, state);

        if (_state == state)
            {
            return;
            }
            
        if ([self.delegate respondsToSelector:@selector(peerWillChangeState:oldState:newState:)] == YES)
            {
            [self.delegate peerWillChangeState:self oldState:_state newState:state];
            }
            
        _state = state;

        if ([self.delegate respondsToSelector:@selector(peerDidChangeState:oldState:newState:)] == YES)
            {
            [self.delegate peerDidChangeState:self oldState:_state newState:state];
            }
        }
    }

#pragma mark -

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

        if (strong_self.transport.socket.connected == YES)
            {
            strong_self.peerAddress = strong_self.transport.socket.peerAddress;
            }

        NSParameterAssert(strong_self.state == kSTYPeerStateOpening);
        strong_self.state = kSTYPeerStateHandshaking;

        if (strong_self.mode == kSTYMessengerModeClient)
            {
            [strong_self _performHandShake:inCompletion];
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
        #warning TODO - call inCompletion with error?
        return;
        }
    if ([self.delegate respondsToSelector:@selector(peerDidClose:)])
        {
        [self.delegate peerDidClose:self];
        }

    NSParameterAssert(self.state == kSTYPeerStateReady);
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

- (STYMessageHandler *)_makeSystemHandler
    {
    STYMessageHandler *theHandler = [[STYMessageHandler alloc] init];

    __weak typeof(self) weak_self = self;

    // TODO: Technically we only need this if the peer is a server.
    [theHandler addCommand:kSTYHelloCommand block:^(STYPeer *inPeer, STYMessage *inMessage, NSError **outError) {
        __strong typeof(self) strong_self = weak_self;
        if (strong_self == NULL)
            {
            STYLogWarning_(@"Self has been deallocated before block called.");
            return NO;
            }
        
        NSDictionary *theControlData = @{
            kSTYCommandKey: kSTYHelloReplyCommand,
            kSTYInReplyToKey: inMessage.controlData[kSTYMessageIDKey],
            };

        NSDictionary *theMetadata = [self makeHelloMetadata:@{ @"requiresChallenge": @(YES) }];

        STYMessage *theResponse = [[STYMessage alloc] initWithControlData:theControlData metadata:theMetadata data:NULL];
        [inPeer sendMessage:theResponse completion:NULL];

        NSCParameterAssert(strong_self.state == kSTYPeerStateHandshaking);
        strong_self.state = kSTYPeerStateReady;

        return(YES);
        }];
        
    return theHandler;
    }

- (void)_performHandShake:(STYCompletionBlock)inCompletion
    {
    NSParameterAssert(self.mode == kSTYMessengerModeClient);
    
    STYMessage *theMessage = [[STYMessage alloc] initWithControlData:@{ kSTYCommandKey: kSTYHelloCommand } metadata:[self makeHelloMetadata:NULL] data:NULL];

    // TODO retaining self
    __weak typeof(self) weak_self = self;
    STYMessageBlock theReplyHandler = ^(STYPeer *inPeer, STYMessage *inMessage, NSError **outError) {
        __strong typeof(self) strong_self = weak_self;
        if (strong_self == NULL)
            {
            STYLogWarning_(@"Self has been deallocated before block called.");
            return NO;
            }
            
//        if ([inMessage.metadata[@"requiresChallenge"] boolValue] == YES)
//            {
//            NSParameterAssert(strong_self.state == kSTYPeerStateHandshaking);
//            strong_self.state = kSTYPeerStateChallengeResponse;
//            
//            [self _performChallengeRepsonse];
//            }
        
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

- (void)_performChallengeRepsonse
    {
    }

- (void)transport:(STYTransport *)inTransport didReceiveMessage:(STYMessage *)inMessage;
    {
    [self _handleMessage:inMessage error:NULL];
    
    }

@end
