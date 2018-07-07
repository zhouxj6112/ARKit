//
//  ViewController.swift
//  ARHome
//
//  Created by MrZhou on 2017/11/15.
//  Copyright © 2017年 vipme. All rights reserved.
//

import ARKit
import SceneKit
import UIKit

class ViewController: UIViewController {
    
    // MARK: IBOutlets
    
    @IBOutlet var sceneView: VirtualObjectARView!
    
    @IBOutlet weak var addObjectButton: UIButton!
    
    @IBOutlet weak var blurView: UIVisualEffectView!
    
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    // MARK: - UI Elements
    
    var focusSquare = FocusSquare()
    var planes = [UUID:Plane]()    // 字典，存储场景中当前渲染的所有平面 (有可能检测到多个平面)
    
    /// The view controller that displays the status and "restart experience" UI.
    lazy var statusViewController: StatusViewController = {
        return childViewControllers.lazy.flatMap({ $0 as? StatusViewController }).first!
    }()
    
    // 底部弹出的选择模型viewcontroller
    public var popNav:UINavigationController?
    
    // MARK: - ARKit Configuration Properties
    
    /// A type which manages gesture manipulation of virtual content in the scene.
    lazy var virtualObjectInteraction = { () -> VirtualObjectInteraction in
        let interaction = VirtualObjectInteraction(sceneView: self.sceneView)
        interaction.viewController = self
        interaction.objectManager = virtualObjectLoader
        return interaction
    }()
    
    /// Coordinates the loading and unloading of reference nodes for virtual objects.
    let virtualObjectLoader = VirtualObjectLoader()
    
    /// Marks if the AR experience is available for restart.
    var isRestartAvailable = true
    
    /// A serial queue used to coordinate adding or removing nodes from the scene.
    let updateQueue = DispatchQueue(label: "com.example.apple-samplecode.arkitexample.serialSceneKitQueue")
    
    var screenCenter: CGPoint {
        let bounds = sceneView.bounds
        return CGPoint(x: bounds.midX, y: bounds.midY)
    }
    
    /// Convenience accessor for the session owned by ARSCNView.
    var session: ARSession {
        return sceneView.session
    }
    
    // MARK: - View Controller Life Cycle
    override func loadView() {
        super.loadView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        sceneView.session.delegate = self
//#if DEBUG
//        sceneView.showsStatistics = true
//        sceneView.allowsCameraControl = false
//        sceneView.antialiasingMode = .multisampling4X
////        sceneView.debugOptions = SCNDebugOptions.showBoundingBoxes
//        sceneView.debugOptions = [ARSCNDebugOptions.showWorldOrigin, ARSCNDebugOptions.showFeaturePoints]
//#endif
        
        // Set up scene content.
        setupCamera()
        sceneView.scene.rootNode.addChildNode(focusSquare)
        
        /*
         The `sceneView.automaticallyUpdatesLighting` option creates an
         ambient light source and modulates its intensity. This sample app
         instead modulates a global lighting environment map for use with
         physically based materials, so disable automatic lighting.
         */
        sceneView.automaticallyUpdatesLighting = false
        if let environmentMap = UIImage(named: "Models.scnassets/sharedImages/environment_blur.exr") {
            sceneView.scene.lightingEnvironment.contents = environmentMap
        }
        
        // Hook up status view controller callback(s).
        statusViewController.restartExperienceHandler = { [unowned self] in
            self.restartExperience()
        }
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(showVirtualObjectSelectionViewController))
        // Set the delegate to ensure this gesture is only used when there are no virtual objects in the scene.
        tapGesture.delegate = self
        sceneView.addGestureRecognizer(tapGesture)
        
        // 监听通知
        NotificationCenter.default.addObserver(self, selector: #selector(self.resetAR), name: NSNotification.Name(rawValue: "kNotificationResetAR"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.recoverLasted), name: NSNotification.Name(rawValue: "kNotificationRecoverLasted"), object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Prevent the screen from being dimmed to avoid interuppting the AR experience.
        UIApplication.shared.isIdleTimerDisabled = true
        
        // Start the `ARSession`.
        resetTracking()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        //
        session.pause()
        debugPrint("AR进入暂停状态")
    }
    
    // MARK: - Scene content setup
    
    func setupCamera() {
        guard let camera = sceneView.pointOfView?.camera else {
            fatalError("Expected a valid `pointOfView` from the scene.")
        }
        
        /*
         Enable HDR camera settings for the most realistic appearance
         with environmental lighting and physically based materials.
         */
        camera.wantsHDR = true
        camera.exposureOffset = -1
        camera.minimumExposure = -1
        camera.maximumExposure = 3
    }
    
    // MARK: - Session management
    
    /// Creates a new AR configuration to run on the `session`.
    @objc func resetTracking() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        
        statusViewController.scheduleMessage("FIND A SURFACE TO PLACE AN OBJECT", inSeconds: 7.5, messageType: .planeEstimation)
    }
    // 关闭窗口
    func dismissViewController() {
        dismiss(animated: true, completion: {
            debugPrint("关闭AR视图ViewController完成")
        })
    }
    // 弹出设置界面
    func toSettingViewController() {
        let vc = SettingViewController();
        vc.preferredContentSize = CGSize.init(width: self.view.frame.size.width, height: self.view.frame.size.height-180)
        vc.modalPresentationStyle = .popover
        let popover = vc.popoverPresentationController
        popover?.sourceView = self.statusViewController.view
        popover?.sourceRect = CGRect.init(x: 10, y: 10, width: 120, height: 300)
        popover?.permittedArrowDirections = .any
        popover?.delegate = self
        present(vc, animated: true) {
            //
        }
    }
    @objc func resetAR(sender:Notification) {
        statusViewController.showMessage("重置成功", autoHide: true)
        //
        virtualObjectLoader.removeAllVirtualObjects();
        self.resetTracking();
    }
    @objc func recoverLasted(sender:Notification) {
        let oper = sender.userInfo!["oper"] as! String;
        if oper == "save" {
            self.saveCurrentARForHistory();
        } else {
            let index = sender.userInfo!["index"] as? NSNumber;
            self.recoverARFromHistory(index)
        }
    }
    
    // MARK: - Focus Square
    
    func updateFocusSquare() {
        let isObjectVisible = virtualObjectLoader.loadedObjects.contains { object in
            return sceneView.isNode(object, insideFrustumOf: sceneView.pointOfView!)
        }
        
        if isObjectVisible {
            focusSquare.hide()
        } else {
            focusSquare.unhide()
            statusViewController.scheduleMessage("TRY MOVING LEFT OR RIGHT", inSeconds: 5.0, messageType: .focusSquare)
        }
        
        // We should always have a valid world position unless the sceen is just being initialized.
        guard let (worldPosition, planeAnchor, _) = sceneView.worldPosition(fromScreenPosition: screenCenter, objectPosition: focusSquare.lastPosition) else {
            updateQueue.async {
                self.focusSquare.state = .initializing
                self.sceneView.pointOfView?.addChildNode(self.focusSquare)
            }
            addObjectButton.isHidden = true
            return
        }
        
        updateQueue.async {
            self.sceneView.scene.rootNode.addChildNode(self.focusSquare)
            let camera = self.session.currentFrame?.camera
            
            if let planeAnchor = planeAnchor {
                self.focusSquare.state = .planeDetected(anchorPosition: worldPosition, planeAnchor: planeAnchor, camera: camera)
            } else {
                self.focusSquare.state = .featuresDetected(anchorPosition: worldPosition, camera: camera)
            }
        }
        addObjectButton.isHidden = false
        statusViewController.cancelScheduledMessage(for: .focusSquare)
    }
    
    // MARK: - Error handling
    
    func displayErrorMessage(title: String, message: String) {
        // Blur the background.
        blurView.isHidden = false
        
        // Present an alert informing about the error that has occurred.
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let restartAction = UIAlertAction(title: "Restart Session", style: .default) { _ in
            alertController.dismiss(animated: true, completion: nil)
//            self.blurView.isHidden = true
//            self.resetTracking()
        }
        alertController.addAction(restartAction)
        present(alertController, animated: true, completion: nil)
    }
    
    public var modelList:NSArray = []
    
    func resetModelList(array:NSArray) -> Void {
        modelList = array
    }
    
    func saveCurrentARForHistory() {
        let alertController = UIAlertController.init(title: "", message: "请输入标题", preferredStyle: .alert)
        let okAction = UIAlertAction.init(title: "确定", style: .default) { (alertAction:UIAlertAction) in
            // 开始保存
            let inputTitle = alertController.textFields![0].text;
            
            let array = NSMutableArray.init(capacity: 1);
            for obj in self.virtualObjectLoader.loadedObjects {
                if obj.isShadowObj {
                    continue;
                }
                let dic = NSMutableDictionary.init(capacity: 10);
                dic.setValue(obj.zipFileUrl, forKey: "zipFileUrl");
                dic.setValue(obj.signID, forKey: "signID");
                dic.setValue(obj.signName, forKey: "signName");
                // 标记位置
                do {
                    // 取底部阴影模型的坐标
                    let shadowObj = obj.shadowObject;
                    if shadowObj != nil {
                        let posString = String.init(format: "%f|%f|%f", (shadowObj?.simdPosition.x)!, (shadowObj?.simdPosition.y)!, (shadowObj?.simdPosition.z)!);
                        dic.setValue(posString, forKey: "simdPosition");
                    } else {
                        let posString = String.init(format: "%f|%f|%f", (obj.simdPosition.x), (obj.simdPosition.y), (obj.simdPosition.z));
                        dic.setValue(posString, forKey: "simdPosition");
                    }
                }
                //
                let scaleString = String.init(format: "%f|%f|%f", obj.scale.x, obj.scale.y, obj.scale.z)
                dic.setValue(scaleString, forKey: "scale");
                //
                let rotationString = String.init(format: "%f|%f|%f|%f", (obj.simdRotation.x), (obj.simdRotation.y), (obj.simdRotation.z), obj.simdRotation.w);
                dic.setValue(rotationString, forKey: "simdRotation");
                //
                let oriString = String.init(format: "%f", obj.simdWorldOrientation.angle);
                dic.setValue(oriString, forKey: "simdWorldOrientation");
                //
                dic.setValue(NSNumber.init(value: array.count), forKey: "index"); // 标记位置
                array.add(dic);
            }
            if array.count == 0 {
                self.displayErrorMessage(title: "温馨提示", message: "当前场景为空，不需要保存");
                return;
            }
            let filePath = NSHomeDirectory() + "/Documents/" + "his.txt"
            // 读取历史文件
            var arraySrc = NSMutableArray.init(contentsOfFile: filePath);
            if arraySrc == nil {
                arraySrc = NSMutableArray.init();
            }
            let newDic = NSMutableDictionary.init(capacity: 1);
            newDic.setValue((arraySrc?.count)!+1, forKey: "index");
            newDic.setValue(inputTitle, forKey: "title")
            newDic.setValue(array, forKey: "array");
            newDic.setValue(NSDate.init(), forKey: "createTime");
            arraySrc?.add(newDic);
            //
            let bRet = arraySrc?.write(toFile: filePath, atomically: true);
            if !bRet! {
                debugPrint("追加保存失败");
            } else {
                debugPrint("追加保存成功");
            }
        }
        alertController.addAction(okAction)
        alertController.addTextField { (textField:UITextField) in
            textField.placeholder = "标题"
        }
        self.present(alertController, animated: true, completion: nil)
    }
    
    func recoverARFromHistory(_ atIndex:NSNumber?)  {
        if atIndex == nil {
            let vc = ChooseHistoryViewController();
            vc.preferredContentSize = CGSize.init(width: self.view.frame.size.width, height: self.view.frame.size.height-180)
            vc.modalPresentationStyle = .popover
            let popover = vc.popoverPresentationController
            popover?.sourceView = self.statusViewController.view
            popover?.sourceRect = CGRect.init(x: 10, y: 10, width: 120, height: 300)
            popover?.permittedArrowDirections = .any
            popover?.delegate = self
            present(vc, animated: true) {
                //
            }
            return;
        }
        
        let filePath = NSHomeDirectory() + "/Documents/" + "his.txt"
        if FileManager.default.fileExists(atPath: filePath) {
            let array = NSArray.init(contentsOfFile: filePath);
            debugPrint("文件：\(String(describing: array))");
            let index = (array?.count)! - 1 - (atIndex?.intValue)!; // 要倒序
            let objDic = array?.object(at: index) as! NSDictionary; // 倒序的
            let objList:NSArray = objDic["array"] as! NSArray;
            for obj in objList {
                let dic = obj as! NSDictionary;
                //
                let zipFileUrl = dic["zipFileUrl"] as! String;
                if zipFileUrl.count == 0 {
                    continue;
                }
                let zipFileUrlEnc = zipFileUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
                let objectFileUrl = URL.init(string: zipFileUrlEnc!);
                let didSelectObjectID = dic["signID"] as! String;
                let posString = dic["simdPosition"] as! String;
                let posArr = posString.split(separator: "|");
                let simdPosition = float3(Float(posArr[0])!, Float(posArr[1])!, Float(posArr[2])!);
                let simdWorldOrientation = dic["simdWorldOrientation"] as! String;
                virtualObjectLoader.loadVirtualObject(objectFileUrl!, loadedHandler: { [unowned self] loadedObject, shadowObject in
                    DispatchQueue.main.async {
                        self.hideObjectLoadingUI()
                        //
                        if (loadedObject != nil) {
                            loadedObject?.signID = didSelectObjectID;
                            self.placeVirtualObject(loadedObject!)
                            loadedObject?.simdPosition = simdPosition;
                            let ori = simd_quatf(ix: 0, iy: 0, iz: 0, r: Float(simdWorldOrientation)!);
                            loadedObject?.simdWorldOrientation = ori;
                            
                            // 放置阴影模型在底部
                            if shadowObject != nil {
                                self.placeVirtualObject(shadowObject!) // 跟主模型的中心重合
                                shadowObject?.simdPosition = simdPosition;
                            }
                        }
                    }
                });
            }
        }
    }
    
    deinit {
        virtualObjectLoader.release();
        debugPrint("ViewController释放");
    }
    
}
