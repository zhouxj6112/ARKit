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
        //
        self.sd_setImage(with: URL.init(string: imageUrl), placeholderImage: nil) { (image, error, cacheType, url) -> Void in
            print("下载\(imageUrl)完成")
        }
    }
    
}
