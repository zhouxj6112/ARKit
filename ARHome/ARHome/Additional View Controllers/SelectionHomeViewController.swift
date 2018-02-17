//
//  SelectionHomeViewController.swift
//  ARHome
//
//  Created by MrZhou on 2018/2/13.
//  Copyright © 2018年 vipme. All rights reserved.
//

import UIKit
import SwiftyJSON

class SelectionHomeViewController: UIViewController {

    var scrollView:UIScrollView!
    
    override func loadView() {
        super.loadView()
        debugPrint("\(self.view.frame)")
        scrollView = UIScrollView.init(frame: CGRect.init(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height))
        scrollView.contentSize = CGSize.init(width: scrollView.frame.size.width, height: 300)
        self.view = scrollView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var startY: CGFloat = 10
        
        // 按照品牌
        let title1 = UILabel.init(frame: CGRect.init(x: 12, y: 10, width: 120, height: 20));
        title1.text = "品牌"
        title1.font = UIFont.boldSystemFont(ofSize: 14);
        scrollView.addSubview(title1)
        startY += 30
        // 获取所有品牌
        NetworkingHelper.get(url: all_brands_url, parameters: nil, callback: { (data:JSON?, error:NSError?) in
            if error == nil {
                let items = data?.rawValue as! NSArray
                var i = 0;
                for item in items {
                    let one = item as! Dictionary<String, Any>
                    //
                    var x:CGFloat = 12;
                    var y:CGFloat = startY;
                    if i % 3 == 0 {
                        x = 12;
                        y = startY
                    } else if (i % 3 == 1) {
                        x = 12 + 80;
                        y = startY
                    } else {
                        x = 12 + 80 + 80;
                        y = startY
                        //
                        startY += 80 + 10
                    }
                    let button = UIButton.init(frame: CGRect.init(x: Int(x), y: Int(y), width: 40, height: 80))
                    button.setImageWithUrl(imageUrl: one["brandLogo"] as! String, forState: .normal)
                    button.setTitle(one["brandName"] as? String, for: .normal)
                    self.scrollView.addSubview(button)

                    i += 1
                }
            }
        })
        
        startY += 20
        
        // 按照分类
        let title2 = UILabel.init(frame: CGRect.init(x: 12, y: startY, width: 120, height: 20));
        title2.text = "分类"
        title2.font = UIFont.boldSystemFont(ofSize: 14);
        scrollView.addSubview(title2)
        startY += 30
        // 获取所有分类
        NetworkingHelper.get(url: all_category_url, parameters: nil, callback: { (data:JSON?, error:NSError?) in
            if error == nil {
                let items = data?.rawValue as! NSArray
                var i = 0;
                for item in items {
                    let one = item as! Dictionary<String, Any>
                    //
                    var x:CGFloat = 12;
                    var y:CGFloat = startY;
                    if i % 3 == 0 {
                        x = 12;
                        y = startY
                    } else if (i % 3 == 1) {
                        x = 12 + 80;
                        y = startY
                    } else {
                        x = 12 + 80 + 80;
                        y = startY
                        //
                        startY += 80 + 10
                    }
                    let button = UIButton.init(frame: CGRect.init(x: x, y: y, width: 80, height: 40))
                    button.setTitle(one["typeName"] as? String, for: .normal)
                    button.layer.borderWidth = 1.0
                    button.layer.borderColor = UIColor.lightGray.cgColor
                    self.scrollView.addSubview(button)
                    
                    i += 1
                }
            }
        })
        startY += 10
        self.scrollView.contentSize = CGSize.init(width: self.scrollView.frame.size.width, height: startY)
    }
    
}
