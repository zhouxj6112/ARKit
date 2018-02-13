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
    
    /// 已经加载过的模型数组
	private(set) var loadedObjects = [VirtualObject]()
    
    private(set) var isLoading = false
	
    private(set) var isRelease = false
    
	// MARK: - Loading object

    /**
     Loads a `VirtualObject` on a background queue. `loadedHandler` is invoked
     on a background queue once `object` has been loaded.
    */
    func loadVirtualObject(_ objectFileUrl: URL, loadedHandler: @escaping (VirtualObject?, VirtualObject?) -> Void) {
        
        // 方案一
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
        
        // 方案二
        isLoading = true
        let urlString = objectFileUrl.absoluteString // zip文件下载url(已经处理过中文的了)
        NetworkingHelper.download(url: urlString, parameters: nil) { (fileUrl:JSON?, error:NSError?) in
            if self.isRelease {
                return;
            }
            if error != nil {
                self.isLoading = false
                loadedHandler(nil, nil)
                return;
            }
            let respData = fileUrl!["data"]
            let filePath = respData["file"]
            let localFilePath = filePath.stringValue // 注意路径中包含中文的问题
            let enFilePath = localFilePath.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
            let en = enFilePath?.replacingOccurrences(of: "%25", with: "%") // 很是奇怪，为什么会多了25
            let url = URL.init(string: en!)
            let object = VirtualObject.init(url: url!)
            let obj = object! as VirtualObject
            debugPrint("本地模型: \(obj)")
            self.loadedObjects.append(obj)
            let zipFileUrl = urlString.removingPercentEncoding  // 将中文编码转换回去,存储原始数据
            obj.zipFileUrl = zipFileUrl!
            // 加载阴影模型
            var shadowObj = VirtualObject()
            let shadowPath = respData["shadow"]
            if shadowPath.count > 0 {
                let localFilePath = shadowPath.stringValue // 注意路径中包含中文的问题
                let enFilePath = localFilePath.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
                let en = enFilePath?.replacingOccurrences(of: "%25", with: "%") // 很是奇怪，为什么会多了25
                let url = URL.init(string: en!)
                let object = VirtualObject.init(url: url!)
                let obj = object! as VirtualObject
                debugPrint("阴影模型: \(obj)")
                self.loadedObjects.append(obj)
                obj.zipFileUrl = zipFileUrl! // 保持跟主模型文件一致
                shadowObj = obj
            }
            // Load the content asynchronously.
            DispatchQueue.global(qos: .userInitiated).async {
                obj.reset()
                obj.load()
                self.isLoading = false
                loadedHandler(obj, shadowObj)
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
    
    func release() {
        isRelease = true
    }
    
    // 析构函数
    deinit {
        debugPrint("VirtualObjectLoader释放")
    }
    
}
