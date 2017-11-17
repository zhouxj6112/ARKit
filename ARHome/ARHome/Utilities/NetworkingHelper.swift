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
        let destination = DownloadRequest.suggestedDownloadDestination(for: .documentDirectory)
        let fileName = url.MD5()
        let filePath = NSHomeDirectory() + "/" + fileName
        debugPrint(filePath)
        if let data = FileManager.default.contents(atPath: filePath) {
            return;
        }
        //
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
                let image = UIImage.init(contentsOfFile: "file://" + (destUrl?.absoluteString)!);
                debugPrint(image)
            }
    }
    
}
