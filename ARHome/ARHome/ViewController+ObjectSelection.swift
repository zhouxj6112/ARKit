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
    
    func virtualObjectSelectionViewController(_: VirtualObjectSelectionViewController, didSelectObjectUrl object: URL) {
        // 加载模型
        let objectFileUrl = object
        virtualObjectLoader.loadVirtualObject(objectFileUrl, loadedHandler: { [unowned self] loadedObject, shadowObject in
            DispatchQueue.main.async {
                self.hideObjectLoadingUI()
                if (loadedObject != nil) {
                    self.placeVirtualObject(loadedObject!)
                    // 放置阴影模型在底部
                    if shadowObject != nil {
                        self.placeVirtualObject(shadowObject!) // 跟主模型的中心重合
                    }
                    /// 展示选中效果
                    self.virtualObjectInteraction.resetSelectedObject(object: loadedObject)
                } else {
                    self.statusViewController.showMessage("加载模型失败,请联系程序猿", autoHide: true)
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
            }
            index += 1
        }
        // 还要删除阴影模型
        index = 0
        for obj in virtualObjectLoader.loadedObjects {
            if (obj.zipFileUrl.elementsEqual(fileUrl!)) {
                virtualObjectLoader.removeVirtualObject(at: index)
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
