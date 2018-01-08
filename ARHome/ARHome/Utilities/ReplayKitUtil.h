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

/// 开始后台上传任务
+ (void)startUploadTask;

+ (void)excuteCmd:(NSString *)filePath;

@end
