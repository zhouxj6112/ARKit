//
//  ReplayKitUtil.m
//  ARHome
//
//  Created by MrZhou on 2017/11/19.
//  Copyright © 2017年 vipme. All rights reserved.
//

#import "ReplayKitUtil.h"
#import <ReplayKit/ReplayKit.h>

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
    mReplayKitUtil.parentViewController = parentViewController;
}

+ (void)stopRecoder {
    //这是录屏的类
    RPScreenRecorder* recorder = RPScreenRecorder.sharedRecorder;
    [recorder stopRecordingWithHandler:^(RPPreviewViewController * _Nullable previewViewController, NSError * _Nullable error) {
        NSLog(@"stopRecordingWithHandler: %@", error);
        if (error) {
            return ;
        }
    }];
    mReplayKitUtil.isRecording = NO;
}

#pragma mark - RPScreenDelegate

- (void)screenRecorderDidChangeAvailability:(RPScreenRecorder *)screenRecorder {
    NSLog(@"screenRecorderDidChangeAvailability: %@", screenRecorder);
}

- (void)screenRecorder:(RPScreenRecorder *)screenRecorder didStopRecordingWithPreviewViewController:(nullable RPPreviewViewController *)previewViewController error:(nullable NSError *)error {
    NSLog(@"didStopRecordingWithPreviewViewController: %@", error);
    if (error==nil && previewViewController!=nil) {
        NSLog(@"可以预览了");
        previewViewController.previewControllerDelegate = mReplayKitUtil;
        [self.parentViewController presentViewController:previewViewController animated:YES completion:NULL];
    }
}

#pragma mark - RPPreviewViewControllerDelegate

- (void)previewControllerDidFinish:(RPPreviewViewController *)previewController {
    
}

- (void)previewController:(RPPreviewViewController *)previewController didFinishWithActivityTypes:(NSSet <NSString *> *)activityTypes {
    
}

@end
