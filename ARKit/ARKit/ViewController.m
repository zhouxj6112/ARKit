//
//  ViewController.m
//  ARKit
//
//  Created by MrZhou on 2017/9/24.
//  Copyright © 2017年 MrZhou. All rights reserved.
//

#import "ViewController.h"

@interface ViewController () <ARSCNViewDelegate>

@property (nonatomic, strong) IBOutlet ARSCNView *sceneView;

@end

    
@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Set the view's delegate
    self.sceneView.delegate = self;
    
    // Show statistics such as fps and timing information
    self.sceneView.showsStatistics = YES;
    self.sceneView.allowsCameraControl = YES;
    
    self.sceneView.debugOptions = ARSCNDebugOptionShowWorldOrigin | ARSCNDebugOptionShowFeaturePoints | SCNDebugOptionShowPhysicsShapes;
    
    self.sceneView.antialiasingMode = SCNAntialiasingModeMultisampling4X;
    
    // Create a new scene
    //SCNScene *scene = [SCNScene sceneNamed:@"art.scnassets/ship.scn"];
    //SCNScene *scene = [SCNScene sceneNamed:@"art.scnassets/Pony_cartoon.obj"];
    SCNScene* scene = [SCNScene new];
    
    // Set the scene to the view
    self.sceneView.scene = scene;
    
    // Single tap will insert a new piece of geometry into the scene
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(insertCubeFrom:)];
    tapGestureRecognizer.numberOfTapsRequired = 1;
    [self.sceneView addGestureRecognizer:tapGestureRecognizer];
    
    // Press and hold will open a config menu for the selected geometry
    UILongPressGestureRecognizer *materialGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(geometryConfigFrom:)];
    materialGestureRecognizer.minimumPressDuration = 0.5;
    [self.sceneView addGestureRecognizer:materialGestureRecognizer];
    
    // Press and hold with two fingers causes an explosion
    UILongPressGestureRecognizer *explodeGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(explodeFrom:)];
    explodeGestureRecognizer.minimumPressDuration = 1;
    explodeGestureRecognizer.numberOfTouchesRequired = 2;
    [self.sceneView addGestureRecognizer:explodeGestureRecognizer];
    
    // Stop the screen from dimming while we are using the app
    [UIApplication.sharedApplication setIdleTimerDisabled:YES];
    
    NSURL* documentsDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
    documentsDirectoryURL = [documentsDirectoryURL URLByAppendingPathComponent:@"art.scnassets/ship.scn"];
    SCNSceneSource* sceneSource = [SCNSceneSource sceneSourceWithURL:documentsDirectoryURL options:nil];
    SCNNode* boxNode =  [sceneSource entryWithIdentifier:@"16" withClass:[SCNNode class]];
    boxNode.scale = SCNVector3Make(0.1, 0.1, 0.1);
    [self.sceneView.scene.rootNode addChildNode:boxNode];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Create a session configuration
    ARWorldTrackingConfiguration *configuration = [ARWorldTrackingConfiguration new];
    configuration.lightEstimationEnabled = YES;
    configuration.planeDetection = ARPlaneDetectionHorizontal;

    // Run the view's session
    [self.sceneView.session runWithConfiguration:configuration options:ARSessionRunOptionResetTracking];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    // Pause the view's session
    [self.sceneView.session pause];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - ARSCNViewDelegate

// Override to create and configure nodes for anchors added to the view's session.
- (SCNNode *)renderer:(id<SCNSceneRenderer>)renderer nodeForAnchor:(ARAnchor *)anchor {
    NSLog(@"nodeForAnchor:%@", anchor);
    // Add geometry to the node...
    SCNBox* box = [SCNBox boxWithWidth:0.1 height:0.3 length:0.1 chamferRadius:0];
    SCNNode* boxNode = [SCNNode nodeWithGeometry:box];
    boxNode.position = SCNVector3Make(0, 0, -0.5);
    [self.sceneView.scene.rootNode addChildNode:boxNode];
    
//    SCNScene* scene = [SCNScene sceneNamed:@"art.scnassets/ship.scn"]; //@"art.scnassets/16.obj"];
//    SCNNode* boxNode = scene.rootNode;
//    //boxNode.scale = SCNVector3Make(0.01, 0.01, 0.01);
//    [self.sceneView.scene.rootNode addChildNode:boxNode];
 
    return boxNode;
}

- (void)renderer:(id <SCNSceneRenderer>)renderer updateAtTime:(NSTimeInterval)time {
    NSLog(@"updateAtTime:%f", time);
}

- (void)renderer:(id <SCNSceneRenderer>)renderer didAddNode:(SCNNode *)node forAnchor:(ARAnchor *)anchor {
    NSLog(@"didAddNode:%@", node);
    if (![anchor isKindOfClass:[ARPlaneAnchor class]]) {
        return;
    }
}

- (void)session:(ARSession *)session didFailWithError:(NSError *)error {
    // Present an error message to the user
    NSLog(@"didFailWithError: %@", error);
}

- (void)sessionWasInterrupted:(ARSession *)session {
    // Inform the user that the session has been interrupted, for example, by presenting an overlay
    
}

- (void)sessionInterruptionEnded:(ARSession *)session {
    // Reset tracking and/or remove existing anchors if consistent tracking is required
    
}

- (void)insertCubeFrom: (UITapGestureRecognizer *)recognizer {
    // Take the screen space tap coordinates and pass them to the hitTest method on the ARSCNView instance
    CGPoint tapPoint = [recognizer locationInView:self.sceneView];
    NSArray<ARHitTestResult *> *result = [self.sceneView hitTest:tapPoint types:ARHitTestResultTypeExistingPlaneUsingExtent];
    
    // If the intersection ray passes through any plane geometry they will be returned, with the planes
    // ordered by distance from the camera
    if (result.count == 0) {
        return;
    }
    
    // If there are multiple hits, just pick the closest plane
    ARHitTestResult * hitResult = [result firstObject];
    
    [self insertCube:hitResult];
}

- (void)insertCube:(ARHitTestResult *)hitResult {
    // We insert the geometry slightly above the point the user tapped, so that it drops onto the plane
    // using the physics engine
//    float insertionYOffset = 0.5;
//    SCNVector3 position = SCNVector3Make(hitResult.worldTransform.columns[3].x,
//                                         hitResult.worldTransform.columns[3].y + insertionYOffset,
//                                         hitResult.worldTransform.columns[3].z
//                                         );
//
//    Cube *cube = [[Cube alloc] initAtPosition:position withMaterial:[Cube currentMaterial]];
//    //[self.cubes addObject:cube];
//    [self.sceneView.scene.rootNode addChildNode:cube];
}

- (void)session:(ARSession *)session cameraDidChangeTrackingState:(ARCamera *)camera {
    ARTrackingState trackingState = camera.trackingState;
    switch(trackingState) {
        case ARTrackingStateNotAvailable:
            NSLog(@"Camera tracking is not available on this device");
            break;
        case ARTrackingStateLimited:
        {
            ARTrackingState reason = camera.trackingState;
            if (reason == ARTrackingStateReasonExcessiveMotion) {
                NSLog(@"Limited tracking: slow down the movement of the device");
            } else if (reason == ARTrackingStateReasonInsufficientFeatures) {
                NSLog(@"Limited tracking: too few feature points, view areas with more textures");
            } else if (reason == ARTrackingStateReasonNone) {
                NSLog(@"Tracking limited none");
            }
        }
            break;
        case ARTrackingStateNormal:
            NSLog(@"Tracking is back to normal");
            break;
    }
}

@end
