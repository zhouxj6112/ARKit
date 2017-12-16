/*
See LICENSE folder for this sample’s licensing information.

Abstract:
UI Actions for the main view controller.
*/

import UIKit
import SceneKit

extension ViewController: UIGestureRecognizerDelegate {
    
    enum SegueIdentifier: String {
        case showObjects
    }
    
    // MARK: - Interface Actions
    
    /// Displays the `VirtualObjectSelectionViewController` from the `addObjectButton` or in response to a tap gesture in the `sceneView`.
    @IBAction func showVirtualObjectSelectionViewController() {
        // Ensure adding objects is an available action and we are not loading another object (to avoid concurrent modifications of the scene).
        guard !addObjectButton.isHidden && !virtualObjectLoader.isLoading else { return }
        
        statusViewController.cancelScheduledMessage(for: .contentPlacement)
        performSegue(withIdentifier: SegueIdentifier.showObjects.rawValue, sender: addObjectButton)
    }
    
    /// Determines if the tap gesture for presenting the `VirtualObjectSelectionViewController` should be used.
    func gestureRecognizerShouldBegin(_: UIGestureRecognizer) -> Bool {
        return virtualObjectLoader.loadedObjects.isEmpty
    }
    
    func gestureRecognizer(_: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith _: UIGestureRecognizer) -> Bool {
        return true
    }
    
    /// - Tag: restartExperience
    func restartExperience() {
//        guard isRestartAvailable, !virtualObjectLoader.isLoading else { return }
//        isRestartAvailable = false
//
//        statusViewController.cancelAllScheduledMessages()
//
//        virtualObjectLoader.removeAllVirtualObjects()
//        addObjectButton.setImage(#imageLiteral(resourceName: "add"), for: [])
//        addObjectButton.setImage(#imageLiteral(resourceName: "addPressed"), for: [.highlighted])
//
//        resetTracking()
//
//        // Disable restart for a while in order to give the session time to restart.
//        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
//            self.isRestartAvailable = true
//        }
        
        isRestartAvailable = false
        statusViewController.cancelAllScheduledMessages()
        dismissViewController();
    }
}

extension ViewController: UIPopoverPresentationControllerDelegate {
    
    // MARK: - UIPopoverPresentationControllerDelegate

    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // All menus should be popovers (even on iPhone).
        if let popoverController = segue.destination.popoverPresentationController, let button = sender as? UIButton {
            popoverController.delegate = self
            popoverController.sourceView = button
            popoverController.sourceRect = button.bounds
        }
        
        guard let identifier = segue.identifier,
              let segueIdentifer = SegueIdentifier(rawValue: identifier),
              segueIdentifer == .showObjects else { return }
        
        let objectsViewController = segue.destination as! VirtualObjectSelectionViewController
        objectsViewController.virtualObjects = VirtualObject.availableObjects
        objectsViewController.modelList = self.modelList // 额外附加
        objectsViewController.delegate = self
        
        // Set all rows of currently placed objects to selected.
        for one in objectsViewController.modelList {
            var dic = one as! Dictionary<String, Any>
            let fileUrl = dic["fileUrl"] as! String
            var bFind = false
            for object in virtualObjectLoader.loadedObjects {
                let modelFileUrl = object.zipFileUrl
                if modelFileUrl.elementsEqual(fileUrl) {
                    bFind = true
                    break;
                }
            }
            if bFind {
                dic["isIn"] = true
            } else {
                dic["isIn"] = false
            }
        }
    }
    
}
