//
//  NetworkingHelper.swift
//  ARHome
//
//  Created by MrZhou on 2017/11/15.
//  Copyright © 2017年 vipme. All rights reserved.
//

import Foundation
import Alamofire
import AlamofireObjectMapper
import SSZipArchive
import SwiftyJSON

//final let req_sellerlist_url:String = "https://api.sanweiyun.com/users?"
//final let req_modellist_url:String  = "https://api.sanweiyun.com/users/3/posts?"
//let req_sellerlist_url:String = "http://10.199.196.241:8080/api/getAllSellers?"
//let req_modellist_url:String = "http://10.199.196.241:8080/api/getModelsList?"
let req_sellerlist_url:String = "http://52.187.182.32/admin/api/getAllSellers?"
let req_modellist_url:String = "http://52.187.182.32/admin/api/getModelsList?"

class NetworkingHelper {
    
    typealias ResponseBlock = (_ data:JSON?, _ error:NSError?) -> Void
    
    static func get(url:String, parameters:[String:Any]?, callback:@escaping ResponseBlock) -> Void {
        //
        Alamofire.request(url, method:.get, parameters:parameters).responseJSON { (response) in
            let respDic = response.result.value
            if respDic != nil {
                let json = JSON(respDic!) // 使用SwiftJSON格式化数据
                if json["code"] == 200 {
                    let jData = json["data"]
                    callback(jData, nil)
                } else {
                    let error = NSError.init(domain: "", code: 0, userInfo: nil)
                    callback(nil, error)
                }
            } else {
                let error = NSError.init(domain: "", code: -1, userInfo: nil)
                callback(nil, error)
            }
        }
    }
    
    static func post(url:String, parameters:[String:Any]?, callback:@escaping ResponseBlock) -> Void {
        Alamofire.request(url, method:.post, parameters:parameters).responseJSON { (response) in
            let response = response.result.value
            if response != nil {
                let json = JSON(response!) // 使用SwiftJSON格式化数据
                if json["code"] == 200 {
                    let data = json["data"]
                    callback(data, nil)
                } else {
                    let error = NSError.init(domain: "", code: 0, userInfo: nil)
                    callback(nil, error)
                }
            } else {
                let error = NSError.init(domain: "", code: -1, userInfo: nil)
                callback(nil, error)
            }
        }
    }
    
    static func uploadData(url:String) -> Void {
        // 上传文件
        Alamofire.upload (
            multipartFormData: { multipartFormData in
                multipartFormData.append(Data.init(), withName: "file")
            },
            to: url,
            encodingCompletion: { encodingResult in
                switch encodingResult {
                case .success(let upload, _, _):
                    upload.responseJSON { response in
                        debugPrint(response)
                    }
                case .failure(let encodingError):
                    print(encodingError)
                }
            }
        )
    }
    
    static func download(url:String, parameters:[String:Any]?, callback:@escaping ResponseBlock) -> Void {
        let fileManager = FileManager.default
        var fileName = URL.init(string: url)?.lastPathComponent
        if (fileName?.contains("."))! {
            fileName = fileName?.components(separatedBy: CharacterSet.init(charactersIn: "."))[0]
        }
        let destFileName = url.MD5()
        
        // 判断是否下载过了,下载过了就直接返回
        let filePath = NSHomeDirectory() + "/Documents/" + destFileName
        if fileManager.fileExists(atPath: filePath) {
            let downloadDestFilePath = NSHomeDirectory() + "/Documents/" + fileName! + "/" + fileName! + ".scn"
            if (fileManager.fileExists(atPath: downloadDestFilePath)) {
                let dic = ["code":200, "msg":"succ", "data":["url":url, "file":downloadDestFilePath]] as [String : Any]
                let result = JSON(dic)
                callback(result, nil)
            } else {
                callback(nil, NSError.init(domain: "", code: -1, userInfo: nil))
                // 并且删除以前下载过的文件
                try! fileManager.removeItem(atPath: filePath)
            }
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
                let destPath = response.destinationURL?.path
                if (destPath != nil) {
                    // 解压
                    let destFilePath = NSHomeDirectory() + "/Documents/"
                    if SSZipArchive.unzipFile(atPath: destPath!, toDestination: destFilePath) {
                        let modelName:String = fileName!
                        // 获取模型主文件路径
                        let downloadDestFilePath = destFilePath + modelName + "/" + modelName + ".scn"
                        let dic = ["code":200, "msg":"succ", "data":["url":url, "file":downloadDestFilePath]] as [String : Any]
                        let result = JSON(dic)
                        callback(result, nil)
                    } else {
                        callback(nil, NSError.init(domain: "", code: -2, userInfo: nil))
                    }
                } else {
                    callback(nil, NSError.init(domain: "", code: -1, userInfo: nil))
                }
          }
    }
    
}
