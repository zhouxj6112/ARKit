//
//  SelectionModelViewController.swift
//  ARHome
//
//  Created by MrZhou on 2018/2/17.
//  Copyright © 2018年 vipme. All rights reserved.
//

import Foundation
import SwiftyJSON

class SelectionModelViewController: UIViewController {
    
    // 控制视图类别 (0: 品牌商品列表 1: 分类商品列表)
    public var viewType:Int8 = 0
    public var viewId:String = "1"
    
    var scrollView:UIScrollView!
    
    override func loadView() {
        super.loadView()
        //
        scrollView = UIScrollView.init(frame: CGRect.init(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height))
        scrollView.contentSize = CGSize.init(width: scrollView.frame.size.width, height: 300)
        self.view = scrollView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var urlString:String = ""
        var par:[String:String] = [:]
        if self.viewType == 0 {
            urlString = all_modelInBrand_url
            par = ["brandId":viewId]
        } else {
            urlString = all_modelInType_url
            par = ["typeId":viewId]
        }
        NetworkingHelper.get(url: urlString, parameters: par, callback: { (data:JSON?, error:NSError?) in
            if error == nil {
                let items = data?.rawValue as! NSArray
                
                var startY:CGFloat = 30
                var i = 0;
                for item in items {
                    let one = item as! Dictionary<String, Any>
                    //
                    var x:CGFloat = 12;
                    var y:CGFloat = startY;
                    if i % 2 == 0 {
                        x = 12;
                        y = startY
                    } else {
                        x = 12 + 80 + 80;
                        y = startY
                        //
                        startY += 80 + 10
                    }
                    let button = UIButton.init(frame: CGRect.init(x: Int(x), y: Int(y), width: 40, height: 80))
                    button.setImageWithUrl(imageUrl: one["compressImage"] as! String, forState: .normal)
                    button.setTitle(one["modelName"] as? String, for: .normal)
                    self.scrollView.addSubview(button)
                    
                    i += 1
                }
            }
        })
    }
}
