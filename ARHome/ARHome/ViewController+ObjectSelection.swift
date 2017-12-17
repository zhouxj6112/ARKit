/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Methods on the main view controller for handling virtual object loading and movement
*/

import UIKit
import SceneKit

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
        // 缩放比例
        virtualObject.setScale();
        // 控制方向
        virtualObject.setDirection();
        
        updateQueue.async {
            self.sceneView.scene.rootNode.addChildNode(virtualObject)
            debugPrint("添加之后的模型:\(virtualObject)");
        }
    }
    
    // MARK: - VirtualObjectSelectionViewControllerDelegate
    
    func virtualObjectSelectionViewController(_: VirtualObjectSelectionViewController, didSelectObject object: VirtualObject) {
        virtualObjectLoader.loadVirtualObject(object, loadedHandler: { [unowned self] loadedObject in
            if loadedObject == nil {
                return
            }
            DispatchQueue.main.async {
                self.hideObjectLoadingUI()
                self.placeVirtualObject(loadedObject!)
            }
        })

        displayObjectLoadingUI()
    }
    
    func virtualObjectSelectionViewController(_: VirtualObjectSelectionViewController, didDeselectObject object: VirtualObject) {
//        guard let objectIndex = virtualObjectLoader.loadedObjects.index(of: object) else {
//            fatalError("Programmer error: Failed to lookup virtual object in scene.")
//        }
//        virtualObjectLoader.removeVirtualObject(at: objectIndex)
        let fileUrl = object.referenceURL.absoluteString.removingPercentEncoding
        var index = 0
        for obj in virtualObjectLoader.loadedObjects {
            if (obj.zipFileUrl.elementsEqual(fileUrl!)) {
                virtualObjectLoader.removeVirtualObject(at: index)
                break
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
