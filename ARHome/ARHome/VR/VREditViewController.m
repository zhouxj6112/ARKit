//
//  VREditViewController.m
//  ARHome
//
//  Created by MrZhou on 2018/5/6.
//  Copyright © 2018年 vipme. All rights reserved.
//

#import "VREditViewController.h"
#import <SceneKit/SceneKit.h>
#import <AFNetworking/AFNetworking.h>

@interface VREditViewController ()

@end

@implementation VREditViewController

- (void)loadView {
    [super loadView];
    
    SCNView* scnView = [[SCNView alloc] initWithFrame:self.view.frame options:@{}];
    self.view = scnView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // create a new scene
    SCNScene *scene = [SCNScene sceneNamed:@"Models.scnassets/chair/chair.scn"];
    
    // create and add a camera to the scene
    SCNNode *cameraNode = [SCNNode node];
    cameraNode.camera = [SCNCamera camera];
    cameraNode.position = SCNVector3Make(0, 0, 10);
    [scene.rootNode addChildNode:cameraNode];
    
    // create and add a light to the scene
    SCNNode *lightNode = [SCNNode node];
    lightNode.light = [SCNLight light];
    lightNode.light.type = SCNLightTypeOmni;
    lightNode.position = SCNVector3Make(0, 10, 10);
    [scene.rootNode addChildNode:lightNode];
    
    // create and add an ambient light to the scene
    SCNNode *ambientLightNode = [SCNNode node];
    ambientLightNode.light = [SCNLight light];
    ambientLightNode.light.type = SCNLightTypeAmbient;
    ambientLightNode.light.color = [UIColor darkGrayColor];
    [scene.rootNode addChildNode:ambientLightNode];
    
    // retrieve the ship node
////    SCNNode *ship = [scene.rootNode childNodeWithName:@"ship" recursively:YES];
//    SCNNode *ship = [scene.rootNode childNodes][0];
////    ship.scale = SCNVector3Make(0.1, 0.1, 0.1);
//    // animate the 3d object
//    [ship runAction:[SCNAction repeatActionForever:[SCNAction rotateByX:0 y:2 z:0 duration:1]]];
 
    //
    scene.lightingEnvironment.contents = [UIImage imageNamed:@"Models.scnassets/sharedImages/environment_blur.exr"];
    
    // retrieve the SCNView
    SCNView *scnView = (SCNView *)self.view;
    // allows the user to manipulate the camera
    scnView.allowsCameraControl = YES;
    // show statistics such as fps and timing information
    scnView.showsStatistics = YES;
    // configure the view
    scnView.backgroundColor = [UIColor blackColor];
    // set the scene to the view
    scnView.scene = scene;
    
    // add a tap gesture recognizer
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    NSMutableArray *gestureRecognizers = [NSMutableArray array];
    [gestureRecognizers addObject:tapGesture];
    [gestureRecognizers addObjectsFromArray:scnView.gestureRecognizers];
    scnView.gestureRecognizers = gestureRecognizers;
    
    SCNNode* ship = [scene.rootNode childNodes][0];
    for (int i=0; i<25; i++) {
        SCNNode* otherShip = [ship clone];
        otherShip.position = SCNVector3Make(-2+i/5, -3+i%5, 0);
        [scene.rootNode addChildNode:otherShip];
    }
}

- (NSString *)md5:(NSString *)stringSrc
{
    const char *cStr = [stringSrc UTF8String];
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5( cStr, (CC_LONG)strlen(cStr), digest );
    
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [output appendFormat:@"%02x", digest[i]];
    }
    return output;
}

- (void)featchModel:(NSString *)urlString {
    NSString* fileName = [self md5:urlString];
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* documentsDirectory = [paths objectAtIndex:0];
    NSString* filePath = [NSString stringWithFormat:@"%@/%@", documentsDirectory, fileName];
    //
    NSFileManager* fileManager = [NSFileManager defaultManager];
    BOOL isDirectory = YES;
    if ([fileManager fileExistsAtPath:filePath isDirectory:&isDirectory]) {
        // 文件夹下查找模型文件
        return;
    }
    AFHTTPSessionManager* manager = [AFHTTPSessionManager manager];
    NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    [manager downloadTaskWithRequest:request progress:^(NSProgress* progress) {
        
    } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        return [NSURL fileURLWithPath:filePath];
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        //
    }];
}

- (void) handleTap:(UIGestureRecognizer*)gestureRecognize
{
    // retrieve the SCNView
    SCNView *scnView = (SCNView *)self.view;
    
    // check what nodes are tapped
    CGPoint p = [gestureRecognize locationInView:scnView];
    NSArray *hitResults = [scnView hitTest:p options:nil];
    
    // check that we clicked on at least one object
    if([hitResults count] > 0){
        // retrieved the first clicked object
        SCNHitTestResult *result = [hitResults objectAtIndex:0];
        
        // get its material
        SCNMaterial *material = result.node.geometry.firstMaterial;
        
        // highlight it
        [SCNTransaction begin];
        [SCNTransaction setAnimationDuration:0.5];
        
        // on completion - unhighlight
        [SCNTransaction setCompletionBlock:^{
            [SCNTransaction begin];
            [SCNTransaction setAnimationDuration:0.5];
            
            material.emission.contents = [UIColor blackColor];
            
            [SCNTransaction commit];
        }];
        
        material.emission.contents = [UIColor redColor];
        
        [SCNTransaction commit];
    }
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return UIInterfaceOrientationMaskAllButUpsideDown;
    } else {
        return UIInterfaceOrientationMaskAll;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

@end
