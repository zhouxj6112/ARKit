//
//  HomeViewController.swift
//  ARHome
//
//  Created by MrZhou on 2017/11/24.
//  Copyright © 2017年 vipme. All rights reserved.
//

import UIKit
import SwiftyJSON
import AVFoundation

class HomeViewController: UIViewController {

    var mList:NSArray = NSArray.init()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.navigationItem.title = "分享案例"
        let tableView = UITableView.init(frame: CGRect.init(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height), style: .plain);
        tableView.dataSource = self as UITableViewDataSource;
        tableView.delegate = self as UITableViewDelegate;
        self.view.addSubview(tableView)
        
        // 获取所有分享视频案例
        NetworkingHelper.get(url: req_examplelist_url, parameters: ["userToken":"123"], callback: { (data:JSON?, error:NSError?) in
            if error == nil {
                let items = data!["items"]
                self.mList = items.rawValue as! NSArray
                tableView.reloadData()
            } else {
                print("接口失败")
            }
        })
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

extension HomeViewController : UITableViewDataSource, UITableViewDelegate {
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.mList.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let ident:String = "video_cell"
        var cell = tableView.dequeueReusableCell(withIdentifier: ident)
        if cell == nil {
            cell = UITableViewCell.init(style: UITableViewCellStyle.default, reuseIdentifier: ident)
        }
        let dic = self.mList[indexPath.row] as! NSDictionary
        let urlString = dic["exampleUrl"] as! String
        let avPlayer = AVPlayer.init(url: URL.init(string: urlString)!)
        let playerLayer = AVPlayerLayer.init(player: avPlayer);
        playerLayer.frame = CGRect.init(x: 0, y: 0, width: tableView.frame.size.width, height: 240);
        playerLayer.videoGravity = .resizeAspect
        cell?.contentView.layer.addSublayer(playerLayer);
        return cell!
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 300
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath);
        let layers = cell?.contentView.layer.sublayers;
        var playerLayer:AVPlayerLayer;
        for layer in layers! {
            if layer.isKind(of: AVPlayerLayer.self) {
                playerLayer = layer as! AVPlayerLayer;
                playerLayer.player?.play();
                break;
            }
        }
    }
    
}

