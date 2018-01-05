//
//  YKUploaderEngine.m
//  YouKuUploaderDemo
//
//  Created by 周娜 on 16/6/24.
//  Copyright © 2016年 zhouna. All rights reserved.
//

#import "YKUploaderEngine.h"
#import "YKUploaderConfig.h"
#import "YKUploaderUtil.h"
#import "YKUploadEngine+Request.h"

@interface  YKUploaderEngine () {
    NSString *mUpload_token;
    NSString *mUpload_uri;
    NSString *mUpload_ip;
    NSString *mSlice_task_id;
    NSString *mSlice_offset;
    NSString *mSlice_length;
    NSInteger mStatus;
    NSInteger mTransferred;
    BOOL mIsFinished;
    NSMutableDictionary *mUpload_info;
    long mFile_size;
    NSFileHandle *mFile_handle;
}
@end

@implementation YKUploaderEngine

@synthesize clientId;
@synthesize clientSecret;
@synthesize accessToken;
@synthesize refreashToken;
@synthesize uploadParams;
@synthesize delegate;

#pragma mark - init
+ (YKUploaderEngine *)shareInstance
{
    static YKUploaderEngine *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[YKUploaderEngine alloc] init];
    });
    return sharedInstance;
}

- (void)upload
{
    if (![self checkParamsEmpty]) {
        [self failureResponseWithType:YOUKU_ERROR_TYPE_SYSTEM desc:YOUKU_ERROR_1012 code:1012];
        return;
    }
    
    if (![self checkValidClient]) {
        [self failureResponseWithType:YOUKU_ERROR_TYPE_SYSTEM desc:YOUKU_ERROR_1013 code:1013];
        return;
    }
    
    mUpload_info = [NSMutableDictionary dictionaryWithDictionary:uploadParams];
    
    if (![self checkUploadInfos]) {
        [self failureResponseWithType:YOUKU_ERROR_TYPE_FILE_NOT_FOUND desc:YOUKU_ERROR_1014 code:1014];
        return;
    }
    [self updateVersion];
    [self uploadCreate];
}

- (void)updateVersion
{
    [self updateVersionWithParams:mUpload_info success:^(id responseObject) {
        YKLog(@"update version success!");
    } failure:^(NSError *error) {
        YKLog(@"update version fail, error:%@!", error);
    }];
}

- (void)uploadCreate
{
    mIsFinished = false;
    [self createWithParams:[NSDictionary dictionaryWithDictionary:mUpload_info] success:^(id responseObject) {
        NSDictionary *response = (NSDictionary *)responseObject;
        mUpload_token = [response objectForKey:@"upload_token"];
        mUpload_uri = [response objectForKey:@"upload_server_uri"];
        [mUpload_info setObject:mUpload_token forKey:@"upload_token"];
        [mUpload_info setObject:mUpload_uri forKey:@"upload_server_uri"];
        
        __weak YKUploaderEngine *weakself = self;
        if (weakself.delegate && [(NSObject*)weakself.delegate respondsToSelector:@selector(uploaderEngineDidCreate:)]){
            [weakself.delegate uploaderEngineDidCreate:[response objectForKey:@"video_id"]];
        }
        YKLog(@"create success, create response:%@!", responseObject);
        
        [weakself createFileWithParams:mUpload_info success:^(id responseObject) {
            NSDictionary *response = (NSDictionary *)responseObject;
            if (![response objectForKey:@"error"]) {
                YKLog(@"create file success!");
                [weakself newSliceWithParams:mUpload_info success:^(id responseObject) {
                    NSDictionary *response = (NSDictionary *)responseObject;
                    if (![response objectForKey:@"error"]) {
                        YKLog(@"new slice success! result:%@",response);
                        mSlice_offset = [response objectForKey:@"offset"];
                        mSlice_length = [response objectForKey:@"length"];
                        mSlice_task_id = [response objectForKey:@"slice_task_id"];
                        [mUpload_info setObject:mSlice_offset forKey:@"offset"];
                        [mUpload_info setObject:mSlice_length forKey:@"length"];
                        [mUpload_info setObject:mSlice_task_id forKey:@"slice_task_id"];
                        [weakself uploadSlices];
                    } else {
                        [weakself sendUploaderEngineError:response];
                    }
                } failure:^(NSError *error) {
                    YKLog(@"new slice fail, error:%@!", error);
                    [weakself failureResponseWithType:YOUKU_ERROR_TYPE_CONNECT desc:YOUKU_ERROR_50002 code:50002];
                }];
            } else {
                [weakself sendUploaderEngineError:response];
            }
        } failure:^(NSError *error) {
            YKLog(@"create file fail, error:%@!", error);
            [weakself failureResponseWithType:YOUKU_ERROR_TYPE_CONNECT desc:YOUKU_ERROR_50002 code:50002];
        }];

    } failure:^(NSError *error) {
        YKLog(@"get upload_token fail, error:%@!", error);
        __weak YKUploaderEngine *weakself = self;
        [weakself refreshTokenWithParams:mUpload_info success:^(id responseObject) {
            NSDictionary *response = (NSDictionary *)responseObject;
            if (![response objectForKey:@"error"]) {
                YKLog(@"get access_token success, response:%@",response);
                if (weakself.delegate && [(NSObject*)weakself.delegate respondsToSelector:@selector(uploaderEngineDidUpdateToken:)]) {
                    [weakself.delegate uploaderEngineDidUpdateToken:response];
                }
            } else {
                [weakself sendUploaderEngineError:response];
            }
        } failure:^(NSError *error) {
            YKLog(@"get refresh_token fail, error:%@!", error);
            [weakself failureResponseWithType:YOUKU_ERROR_TYPE_CONNECT desc:YOUKU_ERROR_50002 code:50002];
        }];
    }];
}

- (void)uploadSlices
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        dispatch_semaphore_t semaphoreSlice = dispatch_semaphore_create(0);
        do {
            NSData *sliceData = [self sliceData];
            YKLog(@"slice data length:%ld", (long)sliceData.length);
            [mUpload_info setObject:sliceData forKey:@"data"];
            [self uploadSliceWithParams:mUpload_info success:^(id responseObject) {
                __weak YKUploaderEngine *weakself = self;
                NSDictionary *response = (NSDictionary *)responseObject;
                if (![response objectForKey:@"error"]) {
                    YKLog(@"upload slice success! result:%@",response);
                    mIsFinished = [[response objectForKey:@"finished"] boolValue];
                    mSlice_offset = [response objectForKey:@"offset"];
                    mSlice_length = [response objectForKey:@"length"];
                    mSlice_task_id = [response objectForKey:@"slice_task_id"];
                    long transferredBytes = [[response objectForKey:@"transferred"] longValue];
                    mTransferred = [NSString stringWithFormat:@"%.2f", ((float)transferredBytes / (float)mFile_size) * 100 ].integerValue;
                    [mUpload_info setObject:mSlice_offset forKey:@"offset"];
                    [mUpload_info setObject:mSlice_length forKey:@"length"];
                    [mUpload_info setObject:mSlice_task_id forKey:@"slice_task_id"];
                    if (mSlice_task_id.integerValue == 0) {
                        do {
                            dispatch_semaphore_t semaphoreCheck = dispatch_semaphore_create(1);
                            [weakself checkUploadBeforeCommit:^(NSInteger status) {
                                dispatch_semaphore_signal(semaphoreCheck);
                             }];
                            dispatch_semaphore_wait(semaphoreCheck, DISPATCH_TIME_FOREVER);
                        }while (mStatus > 1);
                    }
                    if (mTransferred > 0 && weakself.delegate && [(NSObject*)weakself.delegate respondsToSelector:@selector(uploaderEngineDidProgress:)]) {
                        [weakself.delegate uploaderEngineDidProgress:mTransferred];
                    }
                } else {
                    [weakself sendUploaderEngineError:response];
                }
                dispatch_semaphore_signal(semaphoreSlice);
            } failure:^(NSError *error) {
                YKLog(@"upload slice fail, error:%@!", error);
                [self failureResponseWithType:YOUKU_ERROR_TYPE_CONNECT desc:YOUKU_ERROR_50002 code:50002];
                dispatch_semaphore_signal(semaphoreSlice);
            }];
            dispatch_semaphore_wait(semaphoreSlice, DISPATCH_TIME_FOREVER);

        } while (mSlice_task_id.integerValue > 0);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            YKLog(@"upload finished!");
        });
    });
}

- (NSData *)sliceData
{
    [mFile_handle seekToFileOffset:[mSlice_offset longLongValue]];
    return [mFile_handle readDataOfLength:[mSlice_length integerValue]];
}


- (BOOL)checkValidClient
{
    if ([YKUploaderUtil validateClientId:self.clientId clientSecret:self.clientSecret]) {
        return true;
    }
    return false;
}

- (BOOL)checkParamsEmpty
{
    if (!self.clientId || !self.clientSecret) {
        return false;
    }
    if (!self.uploadParams || [self.uploadParams count] == 0) {
        return false;
    }
    if (!self.accessToken) {
        return false;
    }
    if (![self.uploadParams objectForKey:@"title"] || ![self.uploadParams objectForKey:@"tags"] || ![self.uploadParams objectForKey:@"file_name"]) {
        return false;
    }
    return true;
}

- (BOOL)checkUploadInfos
{
    NSString *filename = [mUpload_info objectForKey:@"file_name"];
    if (filename != nil) {
        YKLog(@"upload file_name:%@", filename);
        mFile_handle = [NSFileHandle fileHandleForReadingAtPath:filename];
        BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:filename];
        if (fileExists) {
            YKLog(@"upload file exist!");
            NSError *attributesError = nil;
            NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filename error:&attributesError];
            NSNumber *fileSizeNumber = [fileAttributes objectForKey:NSFileSize];
            mFile_size = [fileSizeNumber longValue];
            [mUpload_info setValue:[YKUploaderUtil md5FromFile:filename] forKey:@"file_md5"];
            [mUpload_info setValue:[NSString stringWithFormat:@"%ld",mFile_size] forKey:@"file_size"];
            [mUpload_info setValue:[filename pathExtension] forKey:@"ext"];
            return true;
        }
    }
    return false;
}

- (void)checkUploadBeforeCommit:(void (^)(NSInteger status))completionHander
{
    [self checkUploadWithParams:mUpload_info success:^(id responseObject) {
        NSDictionary *response = (NSDictionary *)responseObject;
        YKLog(@"upload check success, result:%@!", response);
        mStatus = [[response objectForKey:@"status"] integerValue];
        mUpload_ip = [response objectForKey:@"upload_server_ip"];
        mIsFinished = [[response objectForKey:@"finished"] boolValue];
        [mUpload_info setObject:mUpload_ip forKey:@"upload_server_ip"];
        
        __weak YKUploaderEngine *weakself = self;

        if (mStatus == 1) {
            mTransferred = 100;
            [weakself commitUpload];
        } else if (mStatus == 2 || mStatus == 3) {
            mTransferred = [[response objectForKey:@"confirmed_percent"] longValue];
            [NSThread sleepForTimeInterval:YOUKU_SLEEPTIME];
        }
        if (completionHander) {
            completionHander (mStatus);
        }
        
    } failure:^(NSError *error) {
        YKLog(@"upload check fail, error:%@!", error);
        [self failureResponseWithType:YOUKU_ERROR_TYPE_CONNECT desc:YOUKU_ERROR_50002 code:50002];
        if (completionHander) {
            completionHander (-1);
        }
    }];
}

- (void)commitUpload
{
    [self commitUploadWithParams:mUpload_info success:^(id responseObject) {
        NSDictionary *response = (NSDictionary *)responseObject;
        YKLog(@"upload commit success, result:%@!", response);
        if (self.delegate && [(NSObject*)self.delegate respondsToSelector:@selector(uploaderEngineDidSuccesss:)]) {
            [self.delegate uploaderEngineDidSuccesss:[response objectForKey:@"video_id"]];
        }
    } failure:^(NSError *error) {
        YKLog(@"upload commit fail, error:%@!", error);
        [self failureResponseWithType:YOUKU_ERROR_TYPE_CONNECT desc:YOUKU_ERROR_50002 code:50002];
    }];
}

- (void)failureResponseWithType:(const NSString*)type desc:(const NSString*)desc code:(int)code
{
    NSDictionary *resp = [NSDictionary dictionaryWithObjectsAndKeys:type, @"type", desc, @"desc", [NSNumber numberWithInt:code], @"code", nil];
    if (self.delegate && [(NSObject*)self.delegate respondsToSelector:@selector(uploaderEngineDidError:)]) {
        [self.delegate uploaderEngineDidError:resp];
    }
}

- (void)sendUploaderEngineError:(NSDictionary *)error
{
    if (self.delegate && [(NSObject*)self.delegate respondsToSelector:@selector(uploaderEngineDidError:)]) {
        [self.delegate uploaderEngineDidError:error];
    }
}

@end
