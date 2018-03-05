/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A `SCNReferenceNode` subclass for virtual objects placed into the AR scene.
*/

import Foundation
import SceneKit
import ARKit

class VirtualObject: SCNReferenceNode {
    
    /// The model name derived from the `referenceURL`.
    var modelName: String {
        var type = ".scn"
        if (referenceURL.lastPathComponent.hasSuffix("obj")) {
            type = ".obj"
        } else if (referenceURL.lastPathComponent.hasSuffix("dae")) {
            type = ".dae"
        }
        return referenceURL.lastPathComponent.replacingOccurrences(of: type, with: "")
    }
    
    /// 模型的标识
    public var signID:String = ""
    public var signName:String = ""
    
    /// 下载的zip文件路径url
    public var zipFileUrl: String = ""
    /// 是否是阴影模型 (是的话,不能单独操作的,必须跟随主模型)
    public var isShadowObj: Bool = false
    public var shadowObject: VirtualObject?
    
    /// Use average of recent virtual object distances to avoid rapid changes in object scale.
    private var recentVirtualObjectDistances = [Float]()
    
    /// Resets the objects poisition smoothing.
    func reset() {
        recentVirtualObjectDistances.removeAll()
    }
	
    /**
     Set the object's position based on the provided position relative to the `cameraTransform`.
     If `smoothMovement` is true, the new position will be averaged with previous position to
     avoid large jumps.
     
     - Tag: VirtualObjectSetPosition
     */
    func setPosition(_ newPosition: float3, relativeTo cameraTransform: matrix_float4x4, smoothMovement: Bool) {
        let cameraWorldPosition = cameraTransform.translation
        var positionOffsetFromCamera = newPosition - cameraWorldPosition
        
        // Limit the distance of the object from the camera to a maximum of 10 meters.
        if (simd_length(positionOffsetFromCamera) > 10) {
            positionOffsetFromCamera = simd_normalize(positionOffsetFromCamera)
            positionOffsetFromCamera *= 10
        }
        
        /*
         Compute the average distance of the object from the camera over the last ten
         updates. Notice that the distance is applied to the vector from
         the camera to the content, so it affects only the percieved distance to the
         object. Averaging does _not_ make the content "lag".
         */
        if smoothMovement {
            let hitTestResultDistance = simd_length(positionOffsetFromCamera)
            
            // Add the latest position and keep up to 10 recent distances to smooth with.
            recentVirtualObjectDistances.append(hitTestResultDistance)
            recentVirtualObjectDistances = Array(recentVirtualObjectDistances.suffix(10))
            
            let averageDistance = recentVirtualObjectDistances.average!
            let averagedDistancePosition = simd_normalize(positionOffsetFromCamera) * averageDistance
            simdPosition = cameraWorldPosition + averagedDistancePosition
        } else {
            //
            simdPosition = cameraWorldPosition + positionOffsetFromCamera
        }
    }
    
    func alignBottomCenter() {
        let minV = self.boundingBox.min
        let maxV = self.boundingBox.max
        print("模型包围盒: minV:\(minV) maxV:\(maxV)")
        let maxDis = sqrt((maxV.x - minV.x) * (maxV.x - minV.x) + (maxV.y - minV.y) * (maxV.y - minV.y) + (maxV.z - minV.z) * (maxV.z - minV.z)) / 2
        print("模型尺寸: \(maxDis)")
        //
        let fScale = FocusSquare.size * 1.5 / maxDis
        print("缩放比例: \(fScale),保证跟捉捕框大小")
        simdScale = float3(fScale, fScale, fScale)
        //
//        let fScale: Float = 0.001 // 模型尺寸在500-1000之间,所以缩放比例固定1/1000
//        print("缩放比例: \(fScale),保证跟捉捕框大小")
//        simdScale = float3(fScale, fScale, fScale)
        
        // 缩放后,移动模型位置,使其底面贴近底面,并且中心点在包围盒底部中心位置
        print("原始位置:\(position)")
        if (minV.y > 0 || minV.x+maxV.x != 0 || minV.z+maxV.z != 0) {
            let moveX = abs((maxV.x+minV.x)/2) * fScale
            let moveY = minV.y * fScale // 这个非常关键
            let moveZ = abs((maxV.z+minV.z)/2) * fScale
            debugPrint("moveX:\(moveX), moveY:\(moveY), moveZ:\(moveZ)")
            position = SCNVector3(position.x - moveX, position.y - moveY, position.z + moveZ)
            print("模型位置不在底部中心点上,移动位置:\(position)")
        }
    }
    
    func setDirection() {

    }
    

    private var beforShakePosition: SCNVector3?
    
    public func shakeInSelection() {
        debugPrint("simdPos:\(self.simdPosition); pos:\(self.position)")
        let pos = self.position
        self.beforShakePosition = pos; // 先记录动画前的位置,等动画完成后要恢复原位
        let topPos = SCNVector3.init(pos.x, pos.y+0.05, pos.z)
        let botPos = SCNVector3.init(pos.x, pos.y-0.05, pos.z)
        self.repeatShake(topPos, botPos: botPos)
    }
    private func repeatShake(_ topPos:SCNVector3, botPos:SCNVector3) {
        var toPos = topPos
        if abs(self.simdPosition.y - topPos.y) <= 0.05 {
            toPos = botPos
        }
        toPos.x = self.position.x
        toPos.z = self.position.z
        let action = SCNAction.move(to: toPos, duration: 1.0)
        self.runAction(action, forKey:"shake", completionHandler: {
            self.repeatShake(topPos, botPos: botPos)
        })
    }
    
    /// 停止抖动,并且位置要复位
    public func stopShakeInSelection() {
        //
        self.removeAction(forKey: "shake")
        debugPrint("simdPos:\(self.simdPosition); pos:\(self.position)")
        self.position = self.beforShakePosition!;
    }
    
    /// - Tag: AdjustOntoPlaneAnchor
    func adjustOntoPlaneAnchor(_ anchor: ARPlaneAnchor, using node: SCNNode) {
        // Get the object's position in the plane's coordinate system.
        let planePosition = node.convertPosition(position, from: parent)
        
        // Check that the object is not already on the plane.
        guard planePosition.y != 0 else { return }
        
        // Add 10% tolerance to the corners of the plane.
        let tolerance: Float = 0.1
        
        let minX: Float = anchor.center.x - anchor.extent.x / 2 - anchor.extent.x * tolerance
        let maxX: Float = anchor.center.x + anchor.extent.x / 2 + anchor.extent.x * tolerance
        let minZ: Float = anchor.center.z - anchor.extent.z / 2 - anchor.extent.z * tolerance
        let maxZ: Float = anchor.center.z + anchor.extent.z / 2 + anchor.extent.z * tolerance
        
//        print("检测到平面大小 [X]:\(maxX-minX) [Z]:\(maxZ-minZ)")
        guard (minX...maxX).contains(planePosition.x) && (minZ...maxZ).contains(planePosition.z) else {
            return
        }
        
        // Move onto the plane if it is near it (within 5 centimeters).
        let verticalAllowance: Float = 0.05
        let epsilon: Float = 0.001 // Do not update if the difference is less than 1 mm.
        let distanceToPlane = abs(planePosition.y)
        
        if distanceToPlane > epsilon && distanceToPlane < verticalAllowance {
            SCNTransaction.begin()
            SCNTransaction.animationDuration = CFTimeInterval(distanceToPlane * 500) // Move 2 mm per second.
            SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
            position.y = anchor.transform.columns.3.y
            SCNTransaction.commit()
        }
    }
}

extension VirtualObject {
    // MARK: Static Properties and Methods
    
    /// Loads all the model objects within `Models.scnassets`.
    static let availableObjects: [VirtualObject] = {
        let modelsURL = Bundle.main.url(forResource: "Models.scnassets", withExtension: nil)!

        let fileEnumerator = FileManager().enumerator(at: modelsURL, includingPropertiesForKeys: [])!

        return fileEnumerator.flatMap { element in
            let url = element as! URL

            guard url.pathExtension=="scn"||url.pathExtension=="obj"||url.pathExtension=="dae" else {
                return nil
            }

            return VirtualObject(url: url)
        }
    }()
    
    /// Returns a `VirtualObject` if one exists as an ancestor to the provided node.
    static func existingObjectContainingNode(_ node: SCNNode) -> VirtualObject? {
        if let virtualObjectRoot = node as? VirtualObject {
            return virtualObjectRoot
        }
        
        guard let parent = node.parent else { return nil }
        
        // Recurse up to check if the parent is a `VirtualObject`.
        return existingObjectContainingNode(parent)
    }
}

extension Collection where Iterator.Element == Float, IndexDistance == Int {
    /// Return the mean of a list of Floats. Used with `recentVirtualObjectDistances`.
    var average: Float? {
        guard !isEmpty else {
            return nil
        }

        let sum = reduce(Float(0)) { current, next -> Float in
            return current + next
        }

        return sum / Float(count)
    }
}
