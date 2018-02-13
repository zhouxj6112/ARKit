/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Methods on the main view controller for handling virtual object loading and movement
*/

import UIKit
import SceneKit
import AudioToolbox

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
        
        virtualObjectInteraction.selectedObject = virtualObject
        // 控制位置
        virtualObject.setPosition(focusSquarePosition, relativeTo: cameraTransform, smoothMovement: false)
//        // 对齐底部中心点
//        virtualObject.alignBottomCenter();
//        // 控制方向
//        virtualObject.setDirection();
        
        updateQueue.async {
            self.sceneView.scene.rootNode.addChildNode(virtualObject)
            debugPrint("添加之后的模型:\(virtualObject)");
 
//            // 给模型加个底座阴影效果平面
//            let minV = virtualObject.boundingBox.min
//            let maxV = virtualObject.boundingBox.max
//            let planeGeometry = SCNPlane(width: CGFloat(maxV.x-minV.x), height: CGFloat(maxV.y-minV.y))
//            let material = SCNMaterial()
//            let img = UIImage(named: "fabric")
//            material.diffuse.contents = img
//            material.lightingModel = .physicallyBased
//            planeGeometry.materials = [material]
//            let planeNode = SCNNode(geometry: planeGeometry)
////            planeNode.position = SCNVector3Make(virtualObject.position.x, 10, virtualObject.position.z)
////            planeNode.simdWorldPosition = float3(virtualObject.simdWorldPosition.x, virtualObject.simdWorldPosition.y, virtualObject.simdWorldPosition.z)
//            planeNode.simdPosition = float3(virtualObject.simdPosition.x, virtualObject.simdPosition.y, virtualObject.simdPosition.z)
////            planeNode.transform = SCNMatrix4MakeRotation(Float(-.pi / 2.0), 1.0, 0.0, 0.0)
//            self.sceneView.scene.rootNode.addChildNode(planeNode)
        }
    }
    
    // MARK: - VirtualObjectSelectionViewControllerDelegate
    
    func virtualObjectSelectionViewController(_: VirtualObjectSelectionViewController, didSelectObjectUrl object: URL) {
        // 加载模型
        let objectFileUrl = object
        virtualObjectLoader.loadVirtualObject(objectFileUrl, loadedHandler: { [unowned self] loadedObject, shadowObject in
            DispatchQueue.main.async {
                self.hideObjectLoadingUI()
                if (loadedObject != nil) {
                    self.placeVirtualObject(loadedObject!)
                    // 调用手机振动
                    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
                } else {
                    self.statusViewController.showMessage("加载模型失败,请联系程序猿", autoHide: true)
                }
                // 放置阴影模型在底部
                if shadowObject != nil {
                    self.placeVirtualObject(shadowObject!)
                }
            }
        })

        displayObjectLoadingUI()
    }
    
    func virtualObjectSelectionViewController(_: VirtualObjectSelectionViewController, didDeselectObjectUrl object: URL) {
//        guard let objectIndex = virtualObjectLoader.loadedObjects.index(of: object) else {
//            fatalError("Programmer error: Failed to lookup virtual object in scene.")
//        }
//        virtualObjectLoader.removeVirtualObject(at: objectIndex)
        let fileUrl = object.absoluteString.removingPercentEncoding
        var index = 0
        for obj in virtualObjectLoader.loadedObjects {
            if (obj.zipFileUrl.elementsEqual(fileUrl!)) {
                virtualObjectLoader.removeVirtualObject(at: index)
//                break
                // 不能break, 还要删除阴影模型
            }
            index += 1
        }
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
}
