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
#import "YKUploaderEngine.h"
#import "NSTask.h"

@interface ReplayKitUtil () <RPScreenRecorderDelegate, RPPreviewViewControllerDelegate, YKUploaderEngineDelegate>
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
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"已经保存到系统相册,并且在后台上传到我们服务器");
            [self performSelectorInBackground:@selector(uploadMovieFile) withObject:nil];
        });
    }
    if ([activityTypes containsObject:@"com.apple.UIKit.activity.CopyToPasteboard"]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"已经复制到粘贴板");
        });
    }
}

- (void)uploadMovieFile {
    [ReplayKitUtil getLatestSaveVideo:^(NSString *filePath, NSString *fileName) {
        NSLog(@"%@", filePath);
    }];
}


typedef void(^ResultPath)(NSString *filePath, NSString *fileName);

/// 从 PHAsset 获取视频：
+ (void)getLatestSaveVideo:(ResultPath)result {
    // 获取所有资源的集合，并按资源的创建时间排序
    PHFetchOptions *options = [[PHFetchOptions alloc] init];
    options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
    options.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld", PHAssetMediaTypeVideo];
    PHFetchResult *assetsFetchResults = [PHAsset fetchAssetsWithOptions:options];
    PHAsset* asset = [assetsFetchResults firstObject];
    if (asset == nil) {
        result(nil, nil);
        return;
    }
    
    NSArray *assetResources = [PHAssetResource assetResourcesForAsset:asset];
    PHAssetResource *resource;
    for (PHAssetResource *assetRes in assetResources) {
        if (assetRes.type == PHAssetResourceTypePairedVideo || assetRes.type == PHAssetResourceTypeVideo) {
            resource = assetRes;
        }
    }
    NSString *fileName = @"tempVideo.mov";
    if (resource.originalFilename) {
        fileName = resource.originalFilename;
    }
    if (asset.mediaType == PHAssetMediaTypeVideo || asset.mediaSubtypes == PHAssetMediaSubtypePhotoLive) {
//        PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
//        options.version = PHImageRequestOptionsVersionCurrent;
//        options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
        //
        PHAssetResourceRequestOptions* opts = [[PHAssetResourceRequestOptions alloc] init];
        opts.networkAccessAllowed = YES;
        opts.progressHandler = ^(double progress) {
            NSLog(@"保存进度:%f", progress);
        };
        NSString* movieFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:fileName];
        [[NSFileManager defaultManager] removeItemAtPath:movieFilePath error:nil];
        // 先写进自己app路径下,才能进行操作
        [[PHAssetResourceManager defaultManager] writeDataForAssetResource:resource
                                                                    toFile:[NSURL fileURLWithPath:movieFilePath]
                                                                   options:opts
                                                         completionHandler:^(NSError * _Nullable error) {
                                                             if (error) {
                                                                 result(nil, nil);
                                                             } else {
                                                                 result(movieFilePath, fileName);
                                                             }
                                                         }];
    } else {
        result(nil, nil);
    }
}

static BOOL isInWifi = NO;
static NSMutableArray* uploadTasks;
+ (void)startUploadTask {
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
    [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        NSLog(@"%@", [NSThread currentThread]);
        if (status == AFNetworkReachabilityStatusReachableViaWiFi) {
            isInWifi = YES;
            // 将上传文件功能放倒子线程里面去做
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                __block BOOL isUploading = NO;
                while (isInWifi) {
                    if (isUploading) {
                        NSLog(@"有任务在上传中,需要等待...");
                        [NSThread sleepForTimeInterval:5.0];
                        continue;
                    }
                    NSFileManager* fileManager = [NSFileManager defaultManager];
                    NSString* tmpFilePath = NSTemporaryDirectory();
                    NSArray* array = [fileManager contentsOfDirectoryAtPath:tmpFilePath error:nil];
                    if (array.count == 0) {
                        NSLog(@"没有文件要上传,需要等待...");
                        [NSThread sleepForTimeInterval:10.0];
                        continue;
                    }
                    NSString* movieFilePath = [NSString stringWithFormat:@"%@/%@", NSTemporaryDirectory(), array.lastObject];
                    NSString* postUrl = @"http://192.168.1.102:8080/api/shareExample?";
                    AFHTTPSessionManager* manager = [AFHTTPSessionManager manager];
                    NSURLSessionDataTask* task = [manager POST:postUrl parameters:@{@"userToken":@"123"} constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
                        NSData* movData = [NSData dataWithContentsOfFile:movieFilePath];
                        [formData appendPartWithFileData:movData name:@"shareMovie" fileName:@"movie.mov" mimeType:@"movie"];
                    } progress:^(NSProgress * _Nonnull uploadProgress) {
                        NSLog(@"上传进度:%@", uploadProgress);
                    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                        NSDictionary* resp = (NSDictionary *)responseObject;
                        if ([resp[@"code"] intValue] == 200) {
                            // 上传成功,就删除掉
                            [fileManager removeItemAtPath:movieFilePath error:nil];
                            NSLog(@"上传成功一个");
                        }
                        [uploadTasks removeObject:task];
                        isUploading = NO;
                    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                        isUploading = NO;
                        NSLog(@"uploading error:%@", error);
                    }];
                    NSLog(@"%@", task);
                    if (uploadTasks == nil) {
                        uploadTasks = [NSMutableArray arrayWithCapacity:1];
                    }
                    [uploadTasks addObject:task];
                    isUploading = YES;
                }
            });
        } else {
            isInWifi = NO;
            for (NSURLSessionTask* task in uploadTasks) {
                [task cancel];
            }
        }
    }];
}

- (void)uploadFile:(NSString *)vPath {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setObject:vPath forKey:@"file_name"]; //文件路径
    [params setObject:@"ios上传随拍测试" forKey:@"title"]; // 标题
    [params setObject:@"原创 测试" forKey:@"tags"]; // 标签
    // 视频公开类型（all：公开（默认） friend：仅好友 password：加密）
    [params setObject:@"all" forKey:@"public_type"];
    
    YKUploaderEngine* engine = [YKUploaderEngine shareInstance];
    engine.refreashToken = @"";
    engine.clientId = @"";
    engine.clientSecret = @"";
    engine.accessToken = @"";
    engine.delegate = self;
    engine.uploadParams = params;
    [engine upload];
}

#pragma mark -
#pragma mark YKUploaderEngineDelegate

- (void)uploaderEngineDidCreate:(NSString *)videoid
{
    NSLog(@"create videoid:%@", videoid);
}

- (void)uploaderEngineDidUpdateToken:(NSDictionary *)tokens
{
    NSLog(@"update tokens:%@", tokens);
}

- (void)uploaderEngineDidProgress:(NSInteger)progress
{
    NSLog(@"upload progress:%ld", (long)progress);
}

- (void)uploaderEngineDidSuccesss:(NSString *)videoid
{
    NSLog(@"commit videoid:%@", videoid);
}

- (void)uploaderEngineDidError:(NSDictionary *)errors {
    NSLog(@"uploaderEngineDidError:%@", errors);
}

+ (void)excuteCmd:(NSString *)filePath {
    if ([filePath hasPrefix:@"file://"]) {
        filePath = [filePath substringFromIndex:7];
    }
//    NSString* launchPath = [[NSBundle mainBundle] pathForResource:@"scntool" ofType:nil];
    NSString* launchPath = @"/usr/bin/scntool";
    NSLog(@"%@", launchPath);
    // ./scntool --convert aaa.dae --format dae
    @try {
        NSTask* task = [NSTask launchedTaskWithLaunchPath:launchPath arguments:@[@{@"--convert":filePath}, @{@"--format":@"dae"}]];
        [task waitUntilExit];
    } @catch (NSException* e) {
        NSLog(@"NSException: %@", e);
    }
}

@end
