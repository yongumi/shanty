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
@property (readwrite, nonatomic) STYTransport *transport;
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
        #warning TODO - call inCompletion with error?
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

#pragma mark -

- (BOOL)_handleMessage:(STYMessage *)inMessage error:(NSError *__autoreleasing *)outError
    {
    BOOL theHandledFlag = NO;

    STYMessageBlock theBlock = self.blocksForReplies[inMessage.controlData[kSTYInReplyToKey]];
    if (theBlock)
        {
        theHandledFlag = theBlock(self, inMessage, outError);
        if (inMessage.moreComing == NO)
            {
            [self.blocksForReplies removeObjectForKey:inMessage.controlData[kSTYInReplyToKey]];
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
            
            [self _clientPerformChallengeRepsonse:(STYCompletionBlock)inCompletion];
            
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

- (void)_clientPerformChallengeRepsonse:(STYCompletionBlock)inCompletion {

    #if TARGET_OS_IPHONE == 0
    dispatch_async(dispatch_get_main_queue(), ^{
        NSAlert *theAlert = [NSAlert alertWithMessageText:@"Enter secret" defaultButton:@"OK" alternateButton:@"Cancel" otherButton:nil informativeTextWithFormat:@"Informative text"];
        
        NSTextField *theTextField = [[NSTextField alloc] initWithFrame:(CGRect){ .size = { 80, 20 } }];
        theAlert.accessoryView = theTextField;
        if ([theAlert runModal] == 1) {
            NSString *theSecret = theTextField.stringValue;
            STYMessage *theMessage = [[STYMessage alloc] initWithControlData:@{ kSTYCommandKey: @"_secret" } metadata:@{ @"secret": theSecret } data:NULL];
            [self sendMessage:theMessage replyHandler:^BOOL(STYPeer *inPeer, STYMessage *inMessage, NSError *__autoreleasing *outError) {
                //                NSLog(@"%@", inMessage);
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
        } else {
            if (inCompletion) {
                inCompletion([NSError errorWithDomain:@"TODO_DOMAIN" code:-1 userInfo:NULL]);
            }
            [self close:nil];
        }
    });
    #else
    NSParameterAssert(NO);
    #endif
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
