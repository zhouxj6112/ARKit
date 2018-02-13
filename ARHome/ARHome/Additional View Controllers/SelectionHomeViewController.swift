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
        
        // 按照品牌
        let title1 = UILabel.init(frame: CGRect.init(x: 0, y: 0, width: 120, height: 20));
        title1.text = "品牌"
        title1.font = UIFont.boldSystemFont(ofSize: 14);
        scrollView.addSubview(title1)
        let scroll1 = UIScrollView.init(frame: CGRect.init(x: 0, y: 30, width: scrollView.frame.size.width, height: 180))
        // 获取所有品牌
        NetworkingHelper.get(url: all_brands_url, parameters: nil, callback: { (data:JSON?, error:NSError?) in
            if error == nil {
                let items = data?.rawValue as! NSArray
                var i = 0;
                for item in items {
                    let bgView = UIImageView.init(frame: CGRect.init(x: 200*i, y: 0, width: 240, height: 180));
                    bgView.backgroundColor = UIColor.red
                    scroll1.addSubview(bgView)
                    i += 1
                }
                scroll1.contentSize = CGSize.init(width: CGFloat(240*items.count), height: scroll1.frame.size.height)
            }
        })
        scrollView.addSubview(scroll1)
        
        // 按照分类
        
    }
    
}
