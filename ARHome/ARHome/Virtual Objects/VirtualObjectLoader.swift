/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A type which loads and tracks virtual objects.
*/

import Foundation
import ARKit

/**
 Loads multiple `VirtualObject`s on a background queue to be able to display the
 objects quickly once they are needed.
*/
class VirtualObjectLoader {
	private(set) var loadedObjects = [VirtualObject]()
    
    private(set) var isLoading = false
	
	// MARK: - Loading object

    /**
     Loads a `VirtualObject` on a background queue. `loadedHandler` is invoked
     on a background queue once `object` has been loaded.
    */
    func loadVirtualObject(_ object: VirtualObject, loadedHandler: @escaping (VirtualObject) -> Void) {
//        isLoading = true
//        loadedObjects.append(object)
//
//        // Load the content asynchronously.
//        DispatchQueue.global(qos: .userInitiated).async {
//            object.reset()
//            object.load()
//
//            self.isLoading = false
//            loadedHandler(object)
//        }
        
        // 方案二
//        isLoading = true
//        let obj = VirtualObject.init(url: URL.init(string: "http://192.168.1.103/2017/cup/cup.scn")!)
//        loadedObjects.append(obj!)
//        // Load the content asynchronously.
//        DispatchQueue.global(qos: .userInitiated).async {
//            obj?.reset()
//            obj?.load()
//            self.isLoading = false
//            loadedHandler(obj!)
//        }
        
        // 方案三
        isLoading = true
        NetworkingHelper.download(url: "http://192.168.1.103/2017/cup.zip", parameters: nil) { (fileUrl, nil) in
            let filePath = fileUrl! as! String
            let object = VirtualObject.init(url: URL.init(string: "file://" + filePath)!)
            let obj = object! as VirtualObject
            debugPrint("本地模型: \(obj)")
            self.loadedObjects.append(obj)
            // Load the content asynchronously.
            DispatchQueue.global(qos: .userInitiated).async {
                obj.reset()
                obj.load()
                self.isLoading = false
                loadedHandler(obj)
            }
        }
	}
    
    // MARK: - Removing Objects
    
    func removeAllVirtualObjects() {
        // Reverse the indicies so we don't trample over indicies as objects are removed.
        for index in loadedObjects.indices.reversed() {
            removeVirtualObject(at: index)
        }
    }
    
    func removeVirtualObject(at index: Int) {
        guard loadedObjects.indices.contains(index) else { return }
        
        loadedObjects[index].removeFromParentNode()
        loadedObjects.remove(at: index)
    }
}
