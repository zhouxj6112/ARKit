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
    public var viewTitle:String = ""
    
    var scrollView:UIScrollView!
    
    public weak var selectionDelegate: VirtualObjectSelectionViewControllerDelegate?
    private var modelList:NSArray?
    
    override func loadView() {
        super.loadView()
        //
        self.view.backgroundColor = UIColor.white
        ///
        scrollView = UIScrollView.init(frame: CGRect.init(x: 0, y: 40, width: self.view.frame.size.width, height:        self.view.frame.size.height-180-40))
        self.view.addSubview(scrollView)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 标题
        let titleLabel = UILabel.init(frame: CGRect.init(x: self.view.frame.size.width/2-90, y: 10, width: 120, height: 20))
        titleLabel.font = UIFont.boldSystemFont(ofSize: 14)
        titleLabel.text = self.viewTitle
        titleLabel.textAlignment = .center
        self.view.addSubview(titleLabel)
        // 返回按钮
        let back = UIButton.init(frame: CGRect.init(x: 0, y: 0, width: 40, height: 40))
        back.setImage(UIImage.init(named: "btn_close"), for: .normal)
        back.addTarget(self, action: #selector(backTo(_:)), for: .touchUpInside)
        self.view.addSubview(back)
        
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
                self.modelList = items
                //
                var startY:CGFloat = 10
                var i = 0;
                for item in items {
                    let one = item as! Dictionary<String, Any>
                    //
                    var x:CGFloat = self.view.frame.size.width/2-120;
                    var y:CGFloat = startY;
                    if i % 2 == 0 {
                        x = self.view.frame.size.width/2 - 120;
                        y = startY
                    } else {
                        x = self.view.frame.size.width/2 + 40;
                        y = startY
                        //
                        startY += 100 + 20
                    }
                    let button = UIButton.init(frame: CGRect.init(x: Int(x), y: Int(y), width: 80, height: 100))
                    button.imageEdgeInsets = UIEdgeInsets.init(top: 0, left: 0, bottom: 20, right: 0)
                    button.setTitle(one["modelName"] as? String, for: .normal)
                    button.setTitleColor(UIColor.black, for: .normal)
                    button.titleLabel?.font = UIFont.systemFont(ofSize: 12)
                    button.titleEdgeInsets = UIEdgeInsets.init(top: 80, left: -10, bottom: 0, right: -10)
                    button.setImageWithUrl(imageUrl: one["compressImage"] as! String, forState: .normal)
                    button.addTarget(self, action: #selector(self.didSelect(_:)), for: .touchUpInside)
                    button.tag = 100+i
                    self.scrollView.addSubview(button)
                    
                    i += 1
                }
                if i % 2 > 0 {
                    startY += 120
                }
                self.scrollView.contentSize = CGSize.init(width: self.scrollView.frame.size.width, height: startY)
            }
        })
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        //
        preferredContentSize = CGSize(width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height-180)
    }
    
    @objc
    func backTo(_ sender:UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc
    func didSelect(_ sender:UIButton) {
        if self.selectionDelegate != nil {
            let one = self.modelList![sender.tag - 100] as! Dictionary<String, Any?>
            let modelUrl = one["fileUrl"] as! String
            let encodedUrl = modelUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
            let url = URL.init(string: encodedUrl!)
            self.selectionDelegate?.virtualObjectSelectionViewController(self, didSelectObjectUrl: url!)
        }
        self.navigationController?.dismiss(animated: true) {
            debugPrint("选择模型导航关闭")
        }
    }
}
