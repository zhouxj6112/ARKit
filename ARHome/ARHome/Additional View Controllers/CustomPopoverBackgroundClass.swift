//
//  CustomPopoverBackgroundClass.swift
//  ARHome
//
//  Created by MrZhou on 2018/2/14.
//  Copyright © 2018年 vipme. All rights reserved.
//

import Foundation
import UIKit

class CustomPopoverBackgroundClass: UIPopoverBackgroundView {
    
    var _arrowOffset:CGFloat = 0
    
    override var arrowOffset: CGFloat{
        get{
            return self._arrowOffset
        }
        set(newValue){
            self._arrowOffset = newValue
        }
    }
    
    var _arrowDirection: UIPopoverArrowDirection = .unknown
    
    override var arrowDirection: UIPopoverArrowDirection{
        get{
            return self._arrowDirection
        }
        set(newValue){
            self._arrowDirection = newValue
        }
    }
    
    override static func arrowBase() -> CGFloat{
        return 0
    }
    
    override static func arrowHeight() -> CGFloat{
        return 0
    }
    
    override static func contentViewInsets() -> UIEdgeInsets{
        return UIEdgeInsetsMake(0.0, 0.0, 0.0, 0.0)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.white
    }
    
//    override func drawRect(rect: CGRect) {
//        super.drawRect(rect)
//    }
}
