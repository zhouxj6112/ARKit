/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Methods on the main view controller for handling virtual object loading and movement
*/

import UIKit
import SceneKit
import AudioToolbox
import CoreData
import SwiftyJSON

extension ViewController: VirtualObjectSelectionViewControllerDelegate {
    /**
     Adds the specified virtual object to the scene, placed using
     the focus square's estimate of the world-space position
     currently corresponding to the center of the screen.
     
     - Tag: PlaceVirtualObject
     */
    func placeVirtualObject(_ virtualObject: VirtualObject) {
        guard let cameraTransform = session.currentFrame?.camera.transform,
            let focusSquarePosition = focusSquare.lastPosition else {
            statusViewController.showMessage("CANNOT PLACE OBJECT\nTry moving left or right.")
            return
        }
        
        // 控制位置
        virtualObject.setPosition(focusSquarePosition, relativeTo: cameraTransform, smoothMovement: false)
//        // 对齐底部中心点
//        virtualObject.alignBottomCenter();
//        // 控制方向
//        virtualObject.setDirection();
        
        updateQueue.async {
            self.sceneView.scene.rootNode.addChildNode(virtualObject)
            debugPrint("添加之后的模型:\(virtualObject)");
        }
    }
    
    // MARK: - VirtualObjectSelectionViewControllerDelegate
    
    func virtualObjectSelectionViewController(_: UIViewController, didSelectObjectUrl object: URL, didSelectObjectID: String) {
        // 加载模型
        let objectFileUrl = object
        virtualObjectLoader.loadVirtualObject(objectFileUrl, loadedHandler: { [unowned self] loadedObject, shadowObject in
            DispatchQueue.main.async {
                self.hideObjectLoadingUI()
                //
                if (loadedObject != nil) {
                    loadedObject?.signID = didSelectObjectID;
                    
                    self.placeVirtualObject(loadedObject!)
                    // 放置阴影模型在底部
                    if shadowObject != nil {
                        self.placeVirtualObject(shadowObject!) // 跟主模型的中心重合
                    }
                    
                    // 加载放置在底部选中圆圈模型(本地)
                    self.placeVirtualObject(self.virtualObjectLoader.selectionModel)
                    
                    // 展示选中抖动效果
                    self.virtualObjectLoader.resetSelectionObject(loadedObject);
                    self.showDeleteButton()
                    
                    // 保存到浏览历史里面
                    var localShadowUrl:String = ""
                    if (shadowObject != nil && (shadowObject?.isMember(of: SCNReferenceNode.self)) == true) {
                        localShadowUrl = (shadowObject?.referenceURL.absoluteString)!
                    }
                    self.saveToHistory(didSelectObjectID, remoteFileUrl: (loadedObject?.zipFileUrl)!, localObjectUrl: (loadedObject?.referenceURL.absoluteString)!, localShadowUrl: localShadowUrl)
                    
                } else {
                    self.statusViewController.showMessage("加载模型失败,请联系程序猿", autoHide: true)
                }
            }
        })
        displayObjectLoadingUI()
    }
    
    func virtualObjectSelectionViewController(_: UIViewController, didDeselectObjectUrl object: URL, didDeselectObjectID: String) {
        
    }

    // MARK: Object Loading UI

    func displayObjectLoadingUI() {
        // Show progress indicator.
        spinner.startAnimating()
        
        addObjectButton.setImage(#imageLiteral(resourceName: "buttonring"), for: [])

        addObjectButton.isEnabled = false
        isRestartAvailable = false
    }

    func hideObjectLoadingUI() {
        // Hide progress indicator.
        spinner.stopAnimating()

        addObjectButton.setImage(#imageLiteral(resourceName: "add"), for: [])
        addObjectButton.setImage(#imageLiteral(resourceName: "addPressed"), for: [.highlighted])

        addObjectButton.isEnabled = true
        isRestartAvailable = true
    }
    
    func saveToHistory(_ modelID:String, remoteFileUrl:String, localObjectUrl:String, localShadowUrl:String) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedObectContext = appDelegate.persistentContainer.viewContext
        //
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "BrowserEntity")
        fetchRequest.predicate = NSPredicate.init(format: "modelId == %@", modelID)
        do {
            let fetchedResults = try managedObectContext.fetch(fetchRequest) as? [NSManagedObject]
            if let results:[NSManagedObject] = fetchedResults {
                debugPrint("\(results)")
                if results.count > 0 {
                    let managedObject = results[0]
                    // 更新时间
                    managedObject.setValue(NSDate.init(), forKey: "updateTime")
                    do {
                        try managedObectContext.save()
                    } catch  {
                        fatalError("无法保存")
                    }
                    return;
                }
            }
        } catch  {
            fatalError("获取失败")
        }
        
        NetworkingHelper.get(url: all_modelinfo_url, parameters: ["modelIds":modelID]) { (data:JSON?, error:NSError?) in
            if error == nil {
                let items = data?.rawValue as! NSArray
                if items.count == 1 {
                    let item = items[0] as! Dictionary<String, Any>
                    //
                    let entity = NSEntityDescription.entity(forEntityName: "BrowserEntity", in: managedObectContext)
                    let object = NSManagedObject(entity: entity!, insertInto: managedObectContext)
                    object.setValue(modelID, forKey: "modelId")
                    object.setValue(item["modelName"], forKey: "modelName")
                    object.setValue(remoteFileUrl, forKey: "zipFileUrl")
                    object.setValue(item["compressImage"], forKey: "snapshot")
                    object.setValue(localObjectUrl, forKey: "localUrl")
                    object.setValue(localShadowUrl, forKey: "localShadowUrl")
                    object.setValue(NSDate.init(), forKey: "updateTime")
                    do {
                        try managedObectContext.save()
                    } catch  {
                        fatalError("无法保存")
                    }
                }
            }
        }
    }
    
    func showDeleteButton() {
        addObjectButton.setImage(#imageLiteral(resourceName:"remove"), for:[])
        addObjectButton.setImage(#imageLiteral(resourceName:"remove"), for: [.highlighted])
    }
    
}
