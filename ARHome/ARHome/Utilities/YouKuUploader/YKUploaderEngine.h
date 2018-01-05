//
//  YKUploaderEngine.h
//  YouKuUploaderDemo
//
//  Created by 周娜 on 16/6/24.
//  Copyright © 2016年 zhouna. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol YKUploaderEngineDelegate<NSObject>

// 上传错误信息
- (void)uploaderEngineDidError:(NSDictionary *)errors;

// 创建上传任务
- (void)uploaderEngineDidCreate:(NSString *)videoid;

// access_token过期,tokens含有效token
- (void)uploaderEngineDidUpdateToken:(NSDictionary *)tokens;

// 上传进度，如：10
- (void)uploaderEngineDidProgress:(NSInteger)progress;

// 上传成功
- (void)uploaderEngineDidSuccesss:(NSString *)videoid;

@end

@interface YKUploaderEngine : NSObject

@property (nonatomic, weak) id<YKUploaderEngineDelegate> delegate;
@property (nonatomic, copy) NSString *clientId;
@property (nonatomic, copy) NSString *clientSecret;
@property (nonatomic, strong) NSString *accessToken;
@property (nonatomic, strong) NSString *refreashToken;
@property (nonatomic, strong) NSDictionary *uploadParams;

+ (YKUploaderEngine *)shareInstance;

- (void)upload;

@end
