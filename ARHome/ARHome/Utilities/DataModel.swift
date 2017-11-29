//
//  DataModel.swift
//  ARHome
//
//  Created by MrZhou on 2017/11/16.
//  Copyright © 2017年 vipme. All rights reserved.
//

import Foundation
import ObjectMapper

struct DataModel {
    var id:Int32
    var name:String
}

class BaseResponse: Mappable {
    var code:Int32 = 0
    var msg:String = ""
    
    required init?(map: Map) {
        
    }
    
    //映射
    func mapping(map: Map) {
        code <- map["code"]
        msg <- map["msg"]
    }
}

class SellerListItem: Mappable {
    var sellerId:NSInteger = 0
    var sellerName:String = ""
    var sellerDesc:String = ""
    var sellerAddress:String = ""
    
    required init?(map: Map) {
        
    }
    
    //映射
    func mapping(map: Map) {
        sellerId <- map["sellerId"]
        sellerName <- map["sellerName"]
        sellerDesc <- map["sellerDesc"]
    }
}

class SellerListData: Mappable {
    var items:[SellerListItem]?
    
    required init?(map: Map) {
    
    }
    //映射
    func mapping(map: Map) {
        items <- map["items"]
    }
}

class SellerListResponse: Mappable  {
    var code:Int32 = 0
    var msg:String = ""
    var data:SellerListData?

    required init?(map: Map) {
        //
    }
    
    //映射
    func mapping(map: Map) {
        code <- map["code"]
        msg <- map["msg"]
        data <- map["data"]
    }
}

class ModelListItem: NSObject {
    var modelId:String = ""
    var modelName:String = ""
    var modelDesc:String = ""
}

class ModleListResponse: BaseResponse {
    var data:Array? = []
    
    func mj_objectClassInArray() -> NSDictionary {
        let dic:Dictionary = ["data":"ModelListItem"]
        return dic as NSDictionary
    }
}
