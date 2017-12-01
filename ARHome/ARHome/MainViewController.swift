//
//  MainViewController.swift
//  ARHome
//
//  Created by MrZhou on 2017/11/24.
//  Copyright © 2017年 vipme. All rights reserved.
//

import UIKit
import ARKit
import SwiftyJSON

class MainViewController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let vc1 = HomeViewController()
        vc1.tabBarItem.title = "案例"
        vc1.tabBarItem.image = UIImage.init(named: "tab_0_n")
        vc1.tabBarItem.selectedImage = UIImage.init(named: "tab_0_s")
        let nav1 = UINavigationController.init(rootViewController: vc1)
        let vc2 = UIViewController()
        vc2.tabBarItem.title = nil
        vc2.tabBarItem.image = UIImage.init(named: "ar_start")
        vc2.tabBarItem.imageInsets = UIEdgeInsetsMake(0, 0, -10, 0)
        let vc3 = ProductsViewController()
        vc3.tabBarItem.title = "家具"
        vc3.tabBarItem.image = UIImage.init(named: "tab_0_n")
        vc3.tabBarItem.selectedImage = UIImage.init(named: "tab_0_s")
        let nav3 = UINavigationController.init(rootViewController: vc3)
        self.viewControllers = [nav1, vc2, nav3]
        
        self.delegate = self
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


extension MainViewController : UITabBarControllerDelegate {
    
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        print("\(viewController)")
        if viewController == tabBarController.viewControllers![1] {
            if ARWorldTrackingConfiguration.isSupported {
                let stroyboard = UIStoryboard.init(name: "Main", bundle: Bundle(identifier: "Main"))
                let vc = stroyboard.instantiateInitialViewController() as! ViewController
                present(vc, animated: true, completion: {
                    //
                    NetworkingHelper.get(url: req_modellist_url, parameters: ["sellerId":"1003"], callback: { (data:JSON?, error:NSError?) in
                        if error == nil {
                            let items = data?.rawValue as! NSArray
                            vc.resetModelList(array: items)
                        } else {
                            print("接口失败")
                        }
                    })
                })
            } else {
                debugPrint("设置不支持AR")
                let alertController = UIAlertController.init(title: "提示", message: "设备不支持AR", preferredStyle: UIAlertControllerStyle.alert)
                alertController.addAction(UIAlertAction.init(title: "确定", style: UIAlertActionStyle.default, handler: nil))
                present(alertController, animated: true, completion: nil)
            }
            return false
        }
        return true
    }
    
}
