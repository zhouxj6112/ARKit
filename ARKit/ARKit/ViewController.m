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
    self.sceneView.allowsCameraControl = NO;
    
    self.sceneView.debugOptions = ARSCNDebugOptionShowWorldOrigin | ARSCNDebugOptionShowFeaturePoints | SCNDebugOptionShowPhysicsShapes;
    
    self.sceneView.antialiasingMode = SCNAntialiasingModeMultisampling4X;
    
    // Create a new scene
    //SCNScene *scene = [SCNScene sceneNamed:@"art.scnassets/ship.scn"];
    //SCNScene *scene = [SCNScene sceneNamed:@"art.scnassets/Pony_cartoon.obj"];
    SCNScene* scene = [SCNScene scene];
    
    // Set the scene to the view
    self.sceneView.scene = scene;
    
//    // Single tap will insert a new piece of geometry into the scene
//    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(insertCubeFrom:)];
//    tapGestureRecognizer.numberOfTapsRequired = 1;
//    [self.sceneView addGestureRecognizer:tapGestureRecognizer];
//
//    // Press and hold will open a config menu for the selected geometry
//    UILongPressGestureRecognizer *materialGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(geometryConfigFrom:)];
//    materialGestureRecognizer.minimumPressDuration = 0.5;
//    [self.sceneView addGestureRecognizer:materialGestureRecognizer];
//
//    // Press and hold with two fingers causes an explosion
//    UILongPressGestureRecognizer *explodeGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(explodeFrom:)];
//    explodeGestureRecognizer.minimumPressDuration = 1;
//    explodeGestureRecognizer.numberOfTouchesRequired = 2;
//    [self.sceneView addGestureRecognizer:explodeGestureRecognizer];
    
    // Stop the screen from dimming while we are using the app
    [UIApplication.sharedApplication setIdleTimerDisabled:YES];
    
    UIButton* button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(self.view.frame.size.width-40, 20, 40, 40);
    button.backgroundColor = [UIColor grayColor];
    [button setTitle:@"+" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(chooseModel:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
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

#pragma mark - SCNSceneRendererDelegate

- (void)renderer:(id <SCNSceneRenderer>)renderer updateAtTime:(NSTimeInterval)time {
//    NSLog(@"updateAtTime:%f", time);
}

- (void)renderer:(id <SCNSceneRenderer>)renderer willRenderScene:(SCNScene *)scene atTime:(NSTimeInterval)time {
    
}

- (void)renderer:(id <SCNSceneRenderer>)renderer didRenderScene:(SCNScene *)scene atTime:(NSTimeInterval)time {
    
}

#pragma mark - ARSCNViewDelegate

///**
// 自定义节点的锚点
// */
//- (nullable SCNNode *)renderer:(id <SCNSceneRenderer>)renderer nodeForAnchor:(ARAnchor *)anchor {
//    NSLog(@"nodeForAnchor:%@", anchor);
//    // Add geometry to the node...
////    SCNBox* box = [SCNBox boxWithWidth:0.1 height:0.3 length:0.1 chamferRadius:0];
////    SCNNode* boxNode = [SCNNode nodeWithGeometry:box];
////    boxNode.position = SCNVector3Make(0, 0, 0);
////    [self.sceneView.scene.rootNode addChildNode:boxNode];
//
//    ARPlaneAnchor* pAnchor = (ARPlaneAnchor *)anchor;
//
//    SCNScene *aScene = [SCNScene sceneNamed:@"art.scnassets/16.obj"];
////    SCNNode *aNode = [aScene.rootNode childNodeWithName:@"3ddd_ru_Material__28" recursively:YES];
//    SCNNode *aNode = aScene.rootNode.childNodes[0];
//    aNode.position = SCNVector3Make(0, 0, 0);
//    aNode.scale = SCNVector3Make(0.0001, 0.0001, 0.0001);
//    aNode.transform = SCNMatrix4MakeRotation( 0, 0, 0, 0);
//    aNode.rotation = SCNVector4Make(0, 1, 0, M_PI); //方向，(旋转是轴角旋转。 三个第一分量是轴，第四分量是旋转（弧度）)
//    aNode.worldOrientation = self.sceneView.scene.rootNode.worldOrientation;
//    aNode.worldPosition = SCNVector3Make(pAnchor.center.x, pAnchor.center.y, pAnchor.center.z);
//    [self.sceneView.scene.rootNode addChildNode:aNode];
//
//    return aNode;
//}

/**
 当添加节点是会调用，我们可以通过这个代理方法得知我们添加一个虚拟物体到AR场景下的锚点（AR现实世界中的坐标）
 */
- (void)renderer:(id <SCNSceneRenderer>)renderer didAddNode:(SCNNode *)node forAnchor:(ARAnchor *)anchor
{
    NSLog(@"didAddNode:%@", node);
    if (![anchor isKindOfClass:[ARPlaneAnchor class]]) {
        return;
    } // 系统默认给我们添加捕捉到的平面到3D场景
    
    ARPlaneAnchor* pAnchor = (ARPlaneAnchor *)anchor;
    SCNPlane* plane = [SCNPlane planeWithWidth:pAnchor.extent.x height:pAnchor.extent.z];
    SCNNode* planeNode = [SCNNode nodeWithGeometry:plane];
    planeNode.simdPosition = SCNVector3ToFloat3(SCNVector3Make(pAnchor.center.x, 0, pAnchor.center.z));
    planeNode.eulerAngles = SCNVector3Make(-M_PI_2, 0, 0);
    [node addChildNode:planeNode];
}

/**
 将要刷新节点
 */
- (void)renderer:(id <SCNSceneRenderer>)renderer willUpdateNode:(SCNNode *)node forAnchor:(ARAnchor *)anchor {
    NSLog(@"willUpdateNode:%@", node);
    if (![anchor isKindOfClass:[ARPlaneAnchor class]]) {
        return;
    } // 系统默认给我们添加捕捉到的平面到3D场景

    ARPlaneAnchor* pAnchor = (ARPlaneAnchor *)anchor;
    SCNNode* planeNode = (SCNNode *)(node.childNodes.firstObject);
    planeNode.simdPosition = SCNVector3ToFloat3(SCNVector3Make(pAnchor.center.x, 0, pAnchor.center.z));
    SCNPlane* plane = (SCNPlane *)planeNode.geometry;
    plane.width = pAnchor.extent.x;
    plane.height = pAnchor.extent.z;
}

/**
 已经刷新节点
 */
- (void)renderer:(id <SCNSceneRenderer>)renderer didUpdateNode:(SCNNode *)node forAnchor:(ARAnchor *)anchor {
//    NSLog(@"didUpdateNode:%@", node);
}

/**
 移除节点
 */
- (void)renderer:(id <SCNSceneRenderer>)renderer didRemoveNode:(SCNNode *)node forAnchor:(ARAnchor *)anchor {
    NSLog(@"didRemoveNode:%@", node);
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

#pragma mark - ARSessionObserver

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

- (void)session:(ARSession *)session cameraDidChangeTrackingState:(ARCamera *)camera {
    ARTrackingState trackingState = camera.trackingState;
    switch(trackingState) {
        case ARTrackingStateNotAvailable:
            NSLog(@"Camera tracking is not available on this device");
            break;
        case ARTrackingStateLimited:
        {
            ARTrackingStateReason reason = camera.trackingStateReason;
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

#pragma mark - IBAction

- (void)chooseModel:(id)sender {
    UITableView* tableView = (UITableView *)[self.view viewWithTag:100];
    if (tableView == nil) {
        tableView = [[UITableView alloc] initWithFrame:CGRectMake(self.view.frame.size.width-120, 80, 120, self.view.frame.size.height-120) style:UITableViewStylePlain];
        tableView.dataSource = self;
        tableView.delegate = self;
        tableView.tag = 100;
        [self.view addSubview:tableView];
    } else {
        [tableView removeFromSuperview];
    }
}

- (void)didChooseModel {
    UITableView* tableView = (UITableView *)[self.view viewWithTag:100];
    [tableView removeFromSuperview];
}

#pragma mark UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 10;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString* iden = @"cell";
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:iden];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:iden];
    }
    cell.textLabel.text = @"桌子";
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self didChooseModel];
}

@end
