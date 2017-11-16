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
    
    static func get(url:String, parameters:AnyObject?) -> Void {
        Alamofire.request(url, method:.get).responseJSON { (response) in
            debugPrint(response)
            let respData = response.result
        }
    }
    
    static func post(url:String, parameters:AnyObject?) -> Void {
        Alamofire.request(url, method:.post).responseJSON { (response) in
            debugPrint(response)
        }
    }
    
}
