/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Coordinates movement and gesture interactions with virtual objects.
*/

import UIKit
import ARKit

/// - Tag: VirtualObjectInteraction
class VirtualObjectInteraction: NSObject, UIGestureRecognizerDelegate {
    
    /// Developer setting to translate assuming the detected plane extends infinitely.
    let translateAssumingInfinitePlane = true
    
    /// The scene view to hit test against when moving virtual content.
    let sceneView: VirtualObjectARView
    
    /**
     The object that has been most recently intereacted with.
     The `selectedObject` can be moved at any time with the tap gesture.
     */
    public var selectedObject: VirtualObject?
    private var preSelectedObject: VirtualObject?
    //
    public var viewController: ViewController?
    
    /// The object that is tracked for use by the pan and rotation gestures.
    private var trackedObject: VirtualObject? {
        didSet {
            guard trackedObject != nil else { return }
            selectedObject = trackedObject
        }
    }
    
    /// The tracked screen position used to update the `trackedObject`'s position in `updateObjectToCurrentTrackingPosition()`.
    private var currentTrackingPosition: CGPoint?

    init(sceneView: VirtualObjectARView) {
        self.sceneView = sceneView
        super.init()
        
        let panGesture = ThresholdPanGesture(target: self, action: #selector(didPan(_:)))
        panGesture.delegate = self
        
        let rotationGesture = UIRotationGestureRecognizer(target: self, action: #selector(didRotate(_:)))
        rotationGesture.delegate = self
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTap(_:)))
        tapGesture.delegate = self
        
        // Add gestures to the `sceneView`.
        sceneView.addGestureRecognizer(panGesture)
        sceneView.addGestureRecognizer(rotationGesture)
        sceneView.addGestureRecognizer(tapGesture)
    }
    
    // MARK: - Gesture Actions
    @objc
    func didPan(_ gesture: ThresholdPanGesture) {
        switch gesture.state {
        case .began:
            // Check for interaction with a new object.
            if let object = objectInteracting(with: gesture, in: sceneView) {
                if object == selectedObject { // 只有被选中的模型才能进行移动 (先要点击选中,再滑动)
                    trackedObject = object
                    object.stopShakeInSelection(isRecoveryPos: false)
                }
            }
            
        case .changed where gesture.isThresholdExceeded:
            guard let object = trackedObject else { return }
            let translation = gesture.translation(in: sceneView)
            
            let currentPosition = currentTrackingPosition ?? CGPoint(sceneView.projectPoint(object.position))
            
            // The `currentTrackingPosition` is used to update the `selectedObject` in `updateObjectToCurrentTrackingPosition()`.
            currentTrackingPosition = CGPoint(x: currentPosition.x + translation.x, y: currentPosition.y + translation.y)

            gesture.setTranslation(.zero, in: sceneView)
            
        case .changed:
            // Ignore changes to the pan gesture until the threshold for displacment has been exceeded.
            break
            
        default:
            // Clear the current position tracking.
            currentTrackingPosition = nil
            if (trackedObject != nil) {
                trackedObject?.startShakeInSelection()
            }
            trackedObject = nil
        }
    }

    /**
     If a drag gesture is in progress, update the tracked object's position by
     converting the 2D touch location on screen (`currentTrackingPosition`) to
     3D world space.
     This method is called per frame (via `SCNSceneRendererDelegate` callbacks),
     allowing drag gestures to move virtual objects regardless of whether one
     drags a finger across the screen or moves the device through space.
     - Tag: updateObjectToCurrentTrackingPosition
     */
    @objc
    func updateObjectToCurrentTrackingPosition() {
        guard let object = trackedObject, let position = currentTrackingPosition else { return }
        
        translate(object, basedOn: position, infinitePlane: translateAssumingInfinitePlane)
        
        // 查找主模型对应的阴影模型,跟随主模型一起移动
        if object.shadowObject != nil {
            let shadowObj = object.shadowObject
            shadowObj?.simdPosition = float3(object.simdPosition.x, (shadowObj?.simdPosition.y)!, object.simdPosition.z)
        }
        // 底部选中的阴影模型,也跟随一起移动
        self.viewController?.virtualObjectLoader.selectionModel.simdPosition = float3(object.simdPosition.x, (self.viewController?.virtualObjectLoader.selectionModel.simdPosition.y)!, object.simdPosition.z)
    }

    /// - Tag: didRotate 旋转模型 (多指操作)
    @objc
    func didRotate(_ gesture: UIRotationGestureRecognizer) {
        guard gesture.state == .changed else { return }
        
        /*
         - Note:
          For looking down on the object (99% of all use cases), we need to subtract the angle.
          To make rotation also work correctly when looking from below the object one would have to
          flip the sign of the angle depending on whether the object is above or below the camera...
         */
        if trackedObject?.isShadowObj == false {
            trackedObject?.eulerAngles.y -= Float(gesture.rotation)
            let shadowObj = trackedObject?.shadowObject
            if shadowObj != nil {
                shadowObj?.eulerAngles.y = (trackedObject?.eulerAngles.y)!
            }
            self.viewController?.virtualObjectLoader.selectionModel.eulerAngles.y = (trackedObject?.eulerAngles.y)!
        }
        
        gesture.rotation = 0
    }
    
    @objc
    func didTap(_ gesture: UITapGestureRecognizer) {
        let touchLocation = gesture.location(in: sceneView)
        
        if let tappedObject = sceneView.virtualObject(at: touchLocation) {
            // Select a new object.
            if tappedObject == selectedObject {
                selectedObject?.stopShakeInSelection(isRecoveryPos: true)
                self.viewController?.virtualObjectLoader.removeSelectionObject()
                // 已经选中的要置为非选中
                selectedObject = nil
                // 调用手机振动
                AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
            } else {
                // 选中一个模型 (其它模型就要为非选中状态)
                if tappedObject.isShadowObj == true || tappedObject.zipFileUrl.count == 0 { // 排除阴影模型和选中圆圈模型
                    return;
                }
                if selectedObject != nil { // 将前一个选中的恢复
                    selectedObject?.stopShakeInSelection(isRecoveryPos: true)
                    self.viewController?.virtualObjectLoader.removeSelectionObject()
                    // 已经选中的要置为非选中
                    selectedObject = nil
                    // 调用手机振动
                    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
                }
                selectedObject = tappedObject
                
                // 选中状态
                self.viewController?.virtualObjectLoader.resetSelectionObject(selectedObject)
            }
        }
    }
    
    ///
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // Allow objects to be translated and rotated at the same time.
        return true
    }

    /// A helper method to return the first object that is found under the provided `gesture`s touch locations.
    /// - Tag: TouchTesting
    private func objectInteracting(with gesture: UIGestureRecognizer, in view: ARSCNView) -> VirtualObject? {
        for index in 0..<gesture.numberOfTouches {
            let touchLocation = gesture.location(ofTouch: index, in: view)
            
            // Look for an object directly under the `touchLocation`.
            if let object = sceneView.virtualObject(at: touchLocation) {
                return object
            }
        }
        
        // As a last resort look for an object under the center of the touches.
        return sceneView.virtualObject(at: gesture.center(in: view))
    }
    
    // MARK: - Update object position

    /// - Tag: DragVirtualObject
    private func translate(_ object: VirtualObject, basedOn screenPos: CGPoint, infinitePlane: Bool) {
        guard let cameraTransform = sceneView.session.currentFrame?.camera.transform,
            let (position, _, isOnPlane) = sceneView.worldPosition(fromScreenPosition: screenPos,
                                                                   objectPosition: object.simdPosition,
                                                                   infinitePlane: infinitePlane) else { return }
        /*
         Plane hit test results are generally smooth. If we did *not* hit a plane,
         smooth the movement to prevent large jumps.
         */
        object.setPosition(position, relativeTo: cameraTransform, smoothMovement: !isOnPlane)
    }
}

/// Extends `UIGestureRecognizer` to provide the center point resulting from multiple touches.
extension UIGestureRecognizer {
    
    func center(in view: UIView) -> CGPoint {
        let first = CGRect(origin: location(ofTouch: 0, in: view), size: .zero)

        let touchBounds = (1..<numberOfTouches).reduce(first) { touchBounds, index in
            return touchBounds.union(CGRect(origin: location(ofTouch: index, in: view), size: .zero))
        }

        return CGPoint(x: touchBounds.midX, y: touchBounds.midY)
    }
}
