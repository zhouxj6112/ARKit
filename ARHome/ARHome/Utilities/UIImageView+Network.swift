//
//  UIImageView+Network.swift
//  ARKitInteraction
//
//  Created by MrZhou on 2017/11/14.
//  Copyright © 2017年 Apple. All rights reserved.
//

import Foundation
import UIKit
import SDWebImage

extension UIImageView {

    func loadImageWithUrl(imageUrl: String) {
        // 过滤url里面的中文
        let encodedUrl = imageUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        let iUrl = URL.init(string: encodedUrl!)
        self.sd_setImage(with: iUrl!, placeholderImage: nil) { (image, error, cacheType, url) -> Void in
            if image != nil {
                self.image = image
            }
            if error != nil {
                debugPrint("下载\(imageUrl)结果 Error:\(String(describing: error?.localizedDescription))")
            }
        }
    }
    
}

extension UIButton {
    
    func setImageWithUrl(imageUrl: String, forState:UIControlState) {
//        SDWebImageManager.shared().loadImage(with: URL.init(string: imageUrl), options: .retryFailed, progress: nil) { (image, data, error, _, _, _) in
//            if image != nil {
//                self.setImage(image, for: forState)
//            }
//        }
        let edge = self.imageEdgeInsets
        let rect = CGRect.init(x: edge.left, y: edge.top, width: self.frame.size.width-edge.left-edge.right, height: self.frame.size.height-edge.top-edge.bottom)
        var imageView = self.viewWithTag(100)
        if imageView == nil {
            imageView = UIImageView.init(frame: rect)
            imageView?.isUserInteractionEnabled = false
            imageView?.tag = 100
            self.addSubview(imageView!)
        }
        (imageView as! UIImageView).loadImageWithUrl(imageUrl: imageUrl)
    }
    
}
