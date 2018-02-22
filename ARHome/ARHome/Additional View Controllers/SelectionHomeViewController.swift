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

    private var scrollView:UIScrollView!
    private var brandList:NSArray?
    private var categoryList:NSArray?
    
    public weak var selectionDelegate: VirtualObjectSelectionViewControllerDelegate?
    
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
                self.brandList = items
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
                        x = 12 + 100;
                        y = startY
                    } else {
                        x = 12 + 100 + 100;
                        y = startY
                        //
                        startY += 80 + 10
                    }
                    let button = UIButton.init(type: .custom)
                    button.frame = CGRect.init(x: Int(x), y: Int(y), width: 40, height: 80)
                    let brandName:String = one["brandName"] as! String
                    button.titleLabel?.font = UIFont.systemFont(ofSize: 12)
                    button.setTitleColor(UIColor.black, for: .normal)
                    button.setTitle(brandName, for: .normal)
                    button.imageEdgeInsets = UIEdgeInsets.init(top: 0, left: 0, bottom: 40, right: 0)
                    button.titleEdgeInsets = UIEdgeInsets.init(top: 40, left: -20, bottom: 0, right: -20)
                    button.setImageWithUrl(imageUrl: one["brandLogo"] as! String, forState: .normal)
                    button.addTarget(self, action: #selector(self.toBrand(_:)), for: .touchUpInside)
                    button.tag = 1000 + i
                    self.scrollView.addSubview(button)

                    i += 1
                }
                if i % 3 > 0 {
                    startY += 80 + 10
                }
            }
            //
            self.displayAllCategory(startY + 10)
        })
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        //
        preferredContentSize = CGSize(width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height-180)
    }
    
    func displayAllCategory(_ startY:CGFloat) {
        var startY:CGFloat = startY
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
                self.categoryList = items
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
                        x = 12 + 100;
                        y = startY
                    } else {
                        x = 12 + 100 + 100;
                        y = startY
                        //
                        startY += 40 + 10
                    }
                    let button = UIButton.init(frame: CGRect.init(x: x, y: y, width: 80, height: 40))
                    button.setTitle(one["typeName"] as? String, for: .normal)
                    button.setTitleColor(UIColor.black, for: .normal)
                    button.titleLabel?.font = UIFont.systemFont(ofSize: 12)
                    button.layer.borderWidth = 1.0
                    button.layer.borderColor = UIColor.lightGray.cgColor
                    button.addTarget(self, action: #selector(self.toCategory(_:)), for: .touchUpInside)
                    button.tag = 2000+i
                    self.scrollView.addSubview(button)

                    i += 1
                }
                
                if i % 3 > 0 {
                    startY += 40 + 10
                }
                self.scrollView.contentSize = CGSize.init(width: self.scrollView.frame.size.width, height: startY)
            }
        })
    }
    
    @objc
    func toBrand(_ sender: UIButton) {
        let one = self.brandList![sender.tag-1000] as! Dictionary<String, Any>
        let vc = SelectionModelViewController.init(nibName: nil, bundle: nil)
        vc.viewType = 0
        vc.viewId = (one["brandId"] as! NSNumber).stringValue
        vc.viewTitle = one["brandName"] as! String
        vc.selectionDelegate = self.selectionDelegate
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc
    func toCategory(_ sender: UIButton) {
        let one = self.categoryList![sender.tag-2000] as! Dictionary<String, Any>
        let vc = SelectionModelViewController.init(nibName: nil, bundle: nil)
        vc.viewType = 1
        vc.viewId = (one["typeId"] as! NSNumber).stringValue;
        vc.viewTitle = one["typeName"] as! String
        vc.selectionDelegate = self.selectionDelegate
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
}
