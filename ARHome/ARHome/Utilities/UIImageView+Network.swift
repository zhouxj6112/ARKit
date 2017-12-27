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
