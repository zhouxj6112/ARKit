//
//  ReplayKitUtil.m
//  ARHome
//
//  Created by MrZhou on 2017/11/19.
//  Copyright © 2017年 vipme. All rights reserved.
//

#import "ReplayKitUtil.h"
#import <ReplayKit/ReplayKit.h>
#import <AFNetworking/AFNetworking.h>
#import <AssetsLibrary/ALAssetsLibrary.h>
#import <Photos/Photos.h>

@interface ReplayKitUtil () <RPScreenRecorderDelegate, RPPreviewViewControllerDelegate>
@property (nonatomic, assign) BOOL isRecording;
@property (nonatomic, assign) UIViewController* parentViewController;
@end

@implementation ReplayKitUtil

static ReplayKitUtil* mReplayKitUtil;

+ (void)startRecoder:(UIViewController *)parentViewController {
    if (mReplayKitUtil == nil) {
        mReplayKitUtil = [[ReplayKitUtil alloc] init];
    }
    if (mReplayKitUtil.isRecording) {
        return;
    }
    //这是录屏的类
    RPScreenRecorder* recorder = RPScreenRecorder.sharedRecorder;
    if (!recorder.isAvailable) {
        NSLog(@"设置不支持录屏");
        return;
    }
    recorder.delegate = mReplayKitUtil;
    //在此可以设置是否允许麦克风（传YES即是使用麦克风，传NO则不是用麦克风）
    recorder.microphoneEnabled = NO;
    recorder.cameraEnabled = NO;
    //开起录屏功能
    [recorder startRecordingWithHandler:^(NSError * _Nullable error) {
        NSLog(@"error: %@", error);
    }];
    UIViewController* vc = parentViewController;
    while (vc.parentViewController) {
        vc = vc.parentViewController;
    }
    mReplayKitUtil.parentViewController = parentViewController;
    mReplayKitUtil.isRecording = YES;
}

+ (void)stopRecoder {
    //这是录屏的类
    RPScreenRecorder* recorder = RPScreenRecorder.sharedRecorder;
    [recorder stopRecordingWithHandler:^(RPPreviewViewController * _Nullable previewViewController, NSError * _Nullable error) {
        NSLog(@"stopRecordingWithHandler: %@", error);
        if (error) {
            return ;
        }
        previewViewController.previewControllerDelegate = mReplayKitUtil;
        [mReplayKitUtil.parentViewController presentViewController:previewViewController animated:YES completion:NULL];
    }];
    mReplayKitUtil.isRecording = NO;
}

+ (BOOL)isRecording {
    return mReplayKitUtil.isRecording;
}

#pragma mark - RPScreenDelegate

- (void)screenRecorderDidChangeAvailability:(RPScreenRecorder *)screenRecorder {
    NSLog(@"screenRecorderDidChangeAvailability: %@", screenRecorder);
}

- (void)screenRecorder:(RPScreenRecorder *)screenRecorder didStopRecordingWithPreviewViewController:(nullable RPPreviewViewController *)previewViewController error:(nullable NSError *)error {
    NSLog(@"didStopRecordingWithPreviewViewController: %@", error);
}

#pragma mark - RPPreviewViewControllerDelegate

- (void)previewControllerDidFinish:(RPPreviewViewController *)previewController {
    [previewController dismissViewControllerAnimated:YES completion:NULL];
}

- (void)previewController:(RPPreviewViewController *)previewController didFinishWithActivityTypes:(NSSet <NSString *> *)activityTypes {
    if ([activityTypes containsObject:@"com.apple.UIKit.activity.SaveToCameraRoll"]) {
        NSURL* preUrl = [previewController valueForKey:@"movieURL"];
        __block NSData* movData = [NSData dataWithContentsOfURL:preUrl];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"已经保存到系统相册,并且在后台上传到我们服务器");
            
            NSString* postUrl = @"http://192.168.1.103:8080/admin/api/shareExample?";
            AFHTTPSessionManager* manager = [AFHTTPSessionManager manager];
            [manager POST:postUrl parameters:@{@"userToken":@"123"} constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
                [formData appendPartWithFileData:movData name:@"shareMovie" fileName:@"movie.mov" mimeType:@"move"];
            } progress:^(NSProgress * _Nonnull uploadProgress) {
                //
            } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                //
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                //
            }];
        });
    }
    if ([activityTypes containsObject:@"com.apple.UIKit.activity.CopyToPasteboard"]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"已经复制到粘贴板");
        });
    }
}

@end
