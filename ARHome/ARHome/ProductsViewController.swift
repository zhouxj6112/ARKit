//
//  ProductsViewController.swift
//  ARHome
//
//  Created by MrZhou on 2017/11/24.
//  Copyright © 2017年 vipme. All rights reserved.
//

import UIKit

class ProductsViewController: UIViewController {

    private var tableView1:UITableView?;
    private var tableView2:UITableView?;
    private var mSellerList:NSArray = [];
    private var mModelList:NSArray = [];
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.navigationItem.title = "所有家具"
        
        tableView1 = UITableView.init(frame: CGRect.init(x: 0, y: 0, width: 120, height: self.view.frame.size.height), style: UITableViewStyle.plain)
        tableView1?.dataSource = self
        tableView1?.delegate = self
        self.view.addSubview(tableView1!)
        tableView2 = UITableView.init(frame: CGRect.init(x: 120, y: 0, width: self.view.frame.size.width-120, height: self.view.frame.size.height), style: UITableViewStyle.plain)
        tableView2?.dataSource = self
        tableView2?.delegate = self
        self.view.addSubview(tableView2!)
        
        // 获取所有商家列表
        NetworkingHelper.get(url: req_sellerlist_url, parameters: nil, callback: { (data, error) in
            if error == nil {
                let items = data!["items"]
                self.mSellerList = items.arrayValue as! NSArray
                self.tableView1?.reloadData()
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
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == self.tableView1 {
            return mSellerList.count
        } else {
            return mModelList.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == self.tableView1 {
            let ident:String = "cell"
            var cell = tableView.dequeueReusableCell(withIdentifier: ident)
            if cell == nil {
                cell = UITableViewCell.init(style: UITableViewCellStyle.default, reuseIdentifier: ident)
            }
            let cellData = self.mSellerList.object(at: indexPath.row)
            let data = cellData as! Dictionary<String, Any>
            let sName = data["sellerName"] as! String
            cell?.textLabel?.text = sName
            return cell!
        } else {
            let ident:String = "cell2"
            var cell = tableView.dequeueReusableCell(withIdentifier: ident)
            if cell == nil {
                cell = UITableViewCell.init(style: UITableViewCellStyle.default, reuseIdentifier: ident)
            }
            let item:ModelListItem = mModelList[indexPath.row] as! ModelListItem
            cell?.textLabel?.text = item.modelName
            return cell!
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == self.tableView1 {
            let data = self.mSellerList.object(at: indexPath.row) as! NSDictionary
            let sId = data.object(forKey: "sellerId") as! NSInteger
            
        }
    }
}
