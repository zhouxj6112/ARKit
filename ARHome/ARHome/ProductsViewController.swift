//
//  ProductsViewController.swift
//  ARHome
//
//  Created by MrZhou on 2017/11/24.
//  Copyright © 2017年 vipme. All rights reserved.
//

import UIKit
import SwiftyJSON
import ARKit

class ModelTableCell : UITableViewCell {
    public var mImageView:UIImageView?
    public var mTitleLabel:UILabel?
    
    public override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        //
        self.mImageView = UIImageView.init(frame: CGRect.init(x: 10, y: 2, width: 40, height: 40));
        self.contentView.addSubview(mImageView!)
        self.mTitleLabel = UILabel.init(frame: CGRect.init(x: 60, y: 12, width: 180, height: 20));
        self.contentView.addSubview(mTitleLabel!)
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class ProductsViewController: UIViewController {

    private var tableView1:UITableView?;
    private var tableView2:UITableView?;
    private var mSellerList:NSArray = [];
    private var mModelList:NSArray = [];
    
    public static func navForProductsViewController() -> UINavigationController {
        let vc = ProductsViewController()
        let nav = UINavigationController.init(rootViewController: vc)
        return nav
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.navigationItem.title = "所有家具"
        self.navigationItem.rightBarButtonItem = UIBarButtonItem.init(image: UIImage.init(named: "user_setting"), style: .plain, target: self, action: #selector(toSetting))
        
        tableView1 = UITableView.init(frame: CGRect.init(x: 0, y: 0, width: 120, height: self.view.frame.size.height), style: UITableViewStyle.plain)
        tableView1?.dataSource = self
        tableView1?.delegate = self
        self.view.addSubview(tableView1!)
        tableView2 = UITableView.init(frame: CGRect.init(x: 120, y: 0, width: self.view.frame.size.width-120, height: self.view.frame.size.height), style: UITableViewStyle.plain)
        tableView2?.dataSource = self
        tableView2?.delegate = self
        self.view.addSubview(tableView2!)
        // 注册cell
        tableView2?.register(ObjectCell.self, forCellReuseIdentifier: ObjectCell.reuseIdentifier)
        
        //
        let preId = UserDefaults.standard.value(forKey: "user_default_seller")
        var sId:NSInteger = 0
        if preId != nil {
            sId = preId as! NSInteger
        }
        
        // 获取所有商家列表
        NetworkingHelper.get(url: req_sellerlist_url, parameters: nil, callback: { (data:JSON?, error:NSError?) in
            if error == nil {
                let items = data!["items"]
                self.mSellerList = items.rawValue as! NSArray
                self.tableView1?.reloadData()
                
                for (index, value) in self.mSellerList.enumerated() {
                    let item = value as! Dictionary<String, Any?>
                    let sellerId = item["sellerId"] as! NSInteger
                    if sellerId == sId {
                        self.tableView1?.selectRow(at: IndexPath.init(row: index, section: 0), animated: false, scrollPosition: .top)
                        break;
                    }
                }
            } else {
                print("接口失败")
            }
        })
        // 默认展示个商家里面的所有模型
        NetworkingHelper.get(url: req_modellist_url, parameters: ["sellerId":sId], callback: { (data:JSON?, error:NSError?) in
            if error == nil {
                let items = data?.rawValue as! NSArray
                self.mModelList = items
                self.tableView2?.reloadData()
            } else {
                print("接口失败")
            }
        })
    }
    
    func getModelListForSeller(sId: NSInteger) -> Void {
        // 获取某个商家下所有家具模型
        NetworkingHelper.get(url: req_modellist_url, parameters: ["sId":sId]) { (data, error) in
            //
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

extension ProductsViewController : UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        if tableView == self.tableView1 {
            return 1
        } else {
            return mModelList.count
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == self.tableView1 {
            return mSellerList.count
        } else {
            let sData = mModelList.object(at: section)
            let data = sData as! Dictionary<String, Any>
            let list = data["list"] as! NSArray
            return list.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == self.tableView1 {
            let ident1:String = "cell1"
            var cell = tableView.dequeueReusableCell(withIdentifier: ident1)
            if cell == nil {
                cell = UITableViewCell.init(style: UITableViewCellStyle.default, reuseIdentifier: ident1)
            }
            let cellData = self.mSellerList.object(at: indexPath.row)
            let data = cellData as! Dictionary<String, Any>
            let sName = data["sellerName"] as! String
            cell?.textLabel?.numberOfLines = 0
            cell?.textLabel?.textAlignment = .center
            cell?.textLabel?.text = sName
            return cell!
        } else {
            let ident2:String = "cell2"
//            var cell:ModelTableCell = tableView.dequeueReusableCell(withIdentifier: ident2) as! ModelTableCell
//            if cell == nil {
//                cell = ModelTableCell.init(style: UITableViewCellStyle.default, reuseIdentifier: ident2)
//            }
            let cell = ModelTableCell.init(style: UITableViewCellStyle.default, reuseIdentifier: ident2)
            let sData = self.mModelList[indexPath.section]
            let section = sData as! Dictionary<String, Any>
            let list = section["list"] as! NSArray
            //
            let data = list[indexPath.row] as! Dictionary<String, Any>
            let sName = data["modelName"] as! String
            cell.mTitleLabel?.text = sName
            let sImage = data["compressImage"] as! String
            cell.mImageView?.loadImageWithUrl(imageUrl: sImage)
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if tableView == self.tableView2 {
            return 40
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if tableView == self.tableView1 {
            return 60
        }
        return 44
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if tableView == self.tableView2 {
            let sData = self.mModelList.object(at: section)
            let data = sData as! Dictionary<String, Any>
            let tName = data["typeName"] as! String
            let headerView = UIView.init(frame: CGRect.init(x: 0, y: 0, width: tableView.frame.size.width, height: 40))
            headerView.backgroundColor = UIColor.lightGray
            let label = UILabel.init(frame: CGRect.init(x: 10, y: 0, width: 120, height: 40))
            label.text = tName
            headerView.addSubview(label)
            return headerView
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == self.tableView1 {
            let data = self.mSellerList.object(at: indexPath.row) as! NSDictionary
            let sId = data.object(forKey: "sellerId") as! NSInteger
            //
            NetworkingHelper.get(url: req_modellist_url, parameters: ["sellerId":sId], callback: { (data:JSON?, error:NSError?) in
                if error == nil {
                    let items = data?.rawValue as! NSArray
                    self.mModelList = items
                    self.tableView2?.reloadData()
                } else {
                    print("接口失败")
                }
            })
            UserDefaults.standard.set(sId, forKey: "user_default_seller")
        } else {
            let sData = self.mModelList.object(at: indexPath.section) as! Dictionary<String, Any>
            let list = sData["list"] as! NSArray
            let cellData = list[indexPath.row] as! Dictionary<String, Any>
            let modelId = cellData["modelId"] as! String // 模型id
            let sId = modelId.components(separatedBy: "_")[0]
            self.toAR(sId: sId)
        }
    }
    
    private func toAR(sId: String) {
        if ARWorldTrackingConfiguration.isSupported {
            let stroyboard = UIStoryboard.init(name: "Main", bundle: Bundle(identifier: "Main"))
            let vc = stroyboard.instantiateInitialViewController() as! ViewController
            present(vc, animated: true, completion: {
                //
                NetworkingHelper.get(url: req_modellist_url, parameters: ["sellerId":sId], callback: { (data:JSON?, error:NSError?) in
                    if error == nil {
                        let items = data?.rawValue as! NSArray
                        vc.resetModelList(array: items)
                    } else {
                        print("接口失败")
                    }
                })
            })
        }
    }
    
    @objc private func toSetting() {
        let vc = SettingViewController();
        self.navigationController?.pushViewController(vc, animated: true)
    }
}
