//
//  ReplayKitUtil.h
//  ARHome
//
//  Created by MrZhou on 2017/11/19.
//  Copyright © 2017年 vipme. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface ReplayKitUtil : NSObject

+ (void)startRecoder:(UIViewController *)parentViewController;
+ (void)stopRecoder;
+ (BOOL)isRecording;

///
+ (void)startUploadTask;

@end
