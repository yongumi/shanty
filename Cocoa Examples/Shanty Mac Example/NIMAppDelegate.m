//
//  NIMAppDelegate.m
//  Shanty Mac Example
//
//  Created by Jonathan Wight on 11/6/13.
//  Copyright (c) 2013 schwa.io. All rights reserved.
//

#import "NIMAppDelegate.h"

#import <SceneKit/SceneKit.h>
#import <GLKit/GLKit.h>

#import <Shanty/Shanty.h>

@interface NIMAppDelegate () <NSNetServiceBrowserDelegate, NSNetServiceDelegate>
@property (readwrite, nonatomic) NSNetServiceBrowser *serviceBrowser;
@property (readwrite, nonatomic) NSNetService *service;
@property (readwrite, nonatomic) STYMessageHandler *messageHandler;
@property (readwrite, nonatomic) STYMessagingPeer *peer;
@property (readwrite, nonatomic) NSDictionary *lastMetadata;
@property (readwrite, nonatomic) IBOutlet SCNView *sceneView;
@property (readwrite, nonatomic) SCNScene *scene;
@property (readwrite, nonatomic) SCNNode *cameraNode;
@property (readwrite, nonatomic) SCNNode *modelNode;
@end

#pragma mark -

@implementation NIMAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
    {
    self.sceneView.autoenablesDefaultLighting = YES;
    self.sceneView.showsStatistics = YES;
    self.sceneView.allowsCameraControl = NO;

    self.scene = self.sceneView.scene;

    self.cameraNode = [SCNNode node];
    self.cameraNode.name = @"Camera Node";
    self.cameraNode.camera = [SCNCamera camera];
    self.cameraNode.position = (SCNVector3){ 0, 0, 5 };
    [self.scene.rootNode addChildNode:self.cameraNode];

    self.modelNode = self.scene.rootNode.childNodes[0];

    self.messageHandler = [[STYMessageHandler alloc] init];

    __weak typeof(self) weak_self = self;
    [self.messageHandler addCommand:@"gyro_update" handler:^(STYMessagingPeer *inPeer, STYMessage *inMessage, NSError **outError) {
        __strong typeof(weak_self) strong_self = weak_self;
        if (strong_self)
            {
            strong_self.lastMetadata = inMessage.metadata;

            GLKQuaternion theQuarternion = {
                .x = [inMessage.metadata[@"x"] doubleValue],
                .y = [inMessage.metadata[@"y"] doubleValue],
                .z = [inMessage.metadata[@"z"] doubleValue],
                .w = [inMessage.metadata[@"w"] doubleValue],
                };

            GLKMatrix4 theMatrix = GLKMatrix4MakeWithQuaternion(theQuarternion);


            strong_self.modelNode.transform = CATransform3DWithGLKMatrix4(theMatrix);
            }

        return(YES);
        }];

    self.serviceBrowser = [[NSNetServiceBrowser alloc] init];
    self.serviceBrowser.delegate = self;
    [self.serviceBrowser searchForServicesOfType:@"_schwatest._tcp." inDomain:@""];

//    self.client = [[STYClient alloc] initWithHostname:<#(NSString *)#> port:<#(unsigned short)#>
    }

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindService:(NSNetService *)aNetService moreComing:(BOOL)moreComing
    {
    if (self.service)
        {
        return;
        }

    NSLog(@"%@ %d", aNetService, moreComing);

    self.service.delegate = NULL;
    [self.service stop];
    self.service = NULL;

    self.service = aNetService;
    self.service.delegate = self;
    [self.service resolveWithTimeout:60.0];
    }

- (void)netServiceDidResolveAddress:(NSNetService *)sender
    {
    NSLog(@"RESOLVE: %@ %ld", sender.hostName, (long)sender.port);

    self.service.delegate = NULL;
    [self.service stop];
    self.service = NULL;


    STYAddress *theAddress = [[STYAddress alloc] initWithNetService:sender];
    STYSocket *theSocket = [[STYSocket alloc] init];
    __weak typeof(self) weak_self = self;
    [theSocket connect:theAddress completion:^(NSError *error) {
        __strong typeof(weak_self) strong_self = weak_self;
        strong_self.peer = [[STYMessagingPeer alloc] initWithMessageHandler:strong_self.messageHandler];
        [strong_self.peer openWithMode:kSTYMessengerModeClient socket:theSocket completion:NULL];
        }];


    }

inline static CATransform3D CATransform3DWithGLKMatrix4(GLKMatrix4 matrix)
    {
    CATransform3D theTransform = {
        matrix.m00, matrix.m01, matrix.m02, matrix.m03,
        matrix.m10, matrix.m11, matrix.m12, matrix.m13,
        matrix.m20, matrix.m21, matrix.m22, matrix.m23,
        matrix.m30, matrix.m31, matrix.m32, matrix.m33,
        };
    return(theTransform);
    }

@end
