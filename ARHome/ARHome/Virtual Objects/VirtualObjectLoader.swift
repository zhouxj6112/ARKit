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
    
    // 整体缩放比例 (所有模型统一缩放)
    private(set) var globalScale:Float = 1.000000
    
    /// 模型选中后底部选中标示
    public lazy var selectionModel:VirtualObject = {
        let modelURL = Bundle.main.url(forResource: "Models.scnassets/selection/selection.scn", withExtension: nil)!
        let obj = VirtualObject(url: modelURL)!
        DispatchQueue.global(qos: .userInitiated).async {
            obj.reset()
            obj.load()
        }
        if !loadedObjects.contains(obj) {
            loadedObjects.insert(obj, at: 0)
        }
        return obj
    }()
    
	// MARK: - Loading object

    /**
     Loads a `VirtualObject` on a background queue. `loadedHandler` is invoked
     on a background queue once `object` has been loaded.
    */
    func loadVirtualObject(_ objectFileUrl: URL, loadedHandler: @escaping (VirtualObject?, VirtualObject?) -> Void) {
        if (objectFileUrl.isFileURL) {
            isLoading = true;
            let obj = VirtualObject.init(url: objectFileUrl)
            // Load the content asynchronously.
            DispatchQueue.global(qos: .userInitiated).async {
                obj?.reset()
                obj?.load()
                obj?.isShadowObj = false
                self.isLoading = false
                ///
                loadedHandler(obj, nil)
            }
            return;
        }
        // 加载网络模型
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
//            obj.simdScale = float3(self.globalScale, self.globalScale, self.globalScale);
            debugPrint("本地模型: \(obj)")
            self.loadedObjects.append(obj)
            let zipFileUrl = urlString.removingPercentEncoding  // 将中文编码转换回去,存储原始数据
            obj.zipFileUrl = zipFileUrl!
            // 加载阴影模型
            var shadowObj = VirtualObject()
            let shadowPath = respData["shadow"]
            let sLocalFilePath = shadowPath.stringValue // 注意路径中包含中文的问题
            if sLocalFilePath.count > 0 {
                let enFilePath = sLocalFilePath.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
                let en = enFilePath?.replacingOccurrences(of: "%25", with: "%") // 很是奇怪，为什么会多了25
                let sUrl = URL.init(string: en!)
                let sObject = VirtualObject.init(url: sUrl!)
                let sObj = sObject! as VirtualObject
//                sObj.simdScale = float3(self.globalScale, self.globalScale, self.globalScale);
                debugPrint("阴影模型: \(sObj)")
                self.loadedObjects.append(sObj)
                sObj.zipFileUrl = zipFileUrl! // 保持跟主模型文件一致
                shadowObj = sObj
                //
                obj.shadowObject = shadowObj
            } else {
                obj.shadowObject = nil
            }
            // Load the content asynchronously.
            DispatchQueue.global(qos: .userInitiated).async {
                obj.reset()
                obj.load()
                obj.isShadowObj = false
                self.isLoading = false
                //
                shadowObj.reset()
                shadowObj.load()
                shadowObj.isShadowObj = true
                ///
                loadedHandler(obj, shadowObj)
            }
        }
	}
    
    // MARK: - Removing Objects
    
    func removeAllVirtualObjects() {
        // Reverse the indicies so we don't trample over indicies as objects are removed.
        for index in loadedObjects.indices.reversed() {
            if index == 0 { // selectionModel不能删除了
                let obj = loadedObjects[index]
                obj.isHidden = true
                continue;
            }
            removeVirtualObject(at: index)
        }
    }
    
    func removeVirtualObject(at index: Int) {
        guard loadedObjects.indices.contains(index) else { return }
        
        loadedObjects[index].removeFromParentNode()
        loadedObjects.remove(at: index)
    }
    
    /// 移除选中效果的底部圆圈
    public func removeSelectionObject() {
        self.selectionModel.isHidden = true
    }
    
    public func resetSelectionObject(_ object:VirtualObject?) {
        debugPrint("selectionModel: \(selectionModel)")
        self.selectionModel.isHidden = false
        if ((object?.shadowObject) != nil) {
            self.selectionModel.simdPosition = (object?.shadowObject?.simdPosition)!
        }
    }
    
    func release() {
        isRelease = true
    }
    
    // 析构函数
    deinit {
        debugPrint("VirtualObjectLoader释放")
    }
    
    /// Loads all the model objects within `Models.scnassets`.
    static let availableObjectUrls: [URL] = {
        let modelsURL = Bundle.main.url(forResource: "LocalTest.scnassets", withExtension: nil)!
        let fileEnumerator = FileManager().enumerator(at: modelsURL, includingPropertiesForKeys: [])!
        //
        return fileEnumerator.compactMap { element in
            let url = element as! URL
            //
            guard url.pathExtension=="scn"||url.pathExtension=="obj"||url.pathExtension=="dae"||url.pathExtension=="DAE" else {
                return nil
            }
            return url;
        }
    }( );
}
