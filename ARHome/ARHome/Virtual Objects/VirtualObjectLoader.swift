/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A type which loads and tracks virtual objects.
*/

import Foundation
import ARKit
import SwiftyJSON

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
    func loadVirtualObject(_ object: VirtualObject, loadedHandler: @escaping (VirtualObject?) -> Void) {
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
//        let obj = VirtualObject.init(url: URL.init(string: "http://10.199.196.241/1003/tree/tree.scn")!) //  必须scn文件格式
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
        let urlString = object.referenceURL.absoluteString // zip文件下载url
        NetworkingHelper.download(url: urlString, parameters: nil) { (fileUrl:JSON?, error:NSError?) in
            if error != nil {
                self.isLoading = false
                loadedHandler(nil)
                return;
            }
            let respData = fileUrl!["data"]
            let filePath = respData["file"]
            let localFilePath = "file://" + filePath.stringValue // 注意中文问题
            let enFilePath = localFilePath.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
            let url = URL.init(string: enFilePath!)
            let object = VirtualObject.init(url: url!)
            let obj = object! as VirtualObject
            debugPrint("本地模型: \(obj)")
            self.loadedObjects.append(obj)
            obj.zipFileUrl = urlString
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
