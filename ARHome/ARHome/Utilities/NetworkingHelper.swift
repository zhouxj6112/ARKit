//
//  NetworkingHelper.swift
//  ARHome
//
//  Created by MrZhou on 2017/11/15.
//  Copyright © 2017年 vipme. All rights reserved.
//

import Foundation
import Alamofire

class NetworkingHelper {
    
    typealias ResponseBlock = (_ data:AnyObject?, _ error:AnyObject?) -> Void
    
    static func get(url:String, parameters:AnyObject?, callback:@escaping ResponseBlock) -> Void {
        Alamofire.request(url, method:.get).responseJSON { (response) in
            if let JSON = response.result.value {
                debugPrint("JSON: \(JSON)")
                let returnData = JSON as! NSDictionary
                let respData = returnData.object(forKey: "data") as! NSDictionary
                callback(respData, nil)
            }
        }
    }
    
    static func post(url:String, parameters:AnyObject?) -> Void {
        Alamofire.request(url, method:.post).responseJSON { (response) in
            if let JSON = response.result.value {
                debugPrint("JSON: \(JSON)")
            }
        }
    }
    
    static func download(url:String, parameters:AnyObject?, callback:@escaping ResponseBlock) -> Void {
        let fileManager = FileManager.default
        let destFileName = url.MD5()
        
        let filePath = NSHomeDirectory() + "/Documents/" + destFileName
        debugPrint(filePath)
        if fileManager.fileExists(atPath: filePath) {
            return;
        }
        //
        //指定下载路径和保存文件名
        let destination: DownloadRequest.DownloadFileDestination = { _, _ in
            let documentsUrl = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileUrl = documentsUrl.appendingPathComponent(destFileName)
            return (fileUrl, [.removePreviousFile, .createIntermediateDirectories]) //两个参数表示如果有同名文件则会覆盖，如果路径中文件夹不存在则会自动创建
        }
        Alamofire.download(
            url,
            method: .get,
            parameters: nil,
            encoding: JSONEncoding.default,
            headers: nil,
            to: destination).downloadProgress(closure: { (progress) in
                //progress closure
                debugPrint(progress)
            }).responseData { ( response ) in
                //result closure
                debugPrint(response)
                let destUrl = response.destinationURL
                let image = UIImage.init(contentsOfFile: (destUrl?.path)!);
                debugPrint(image)
            }
    }
    
}
