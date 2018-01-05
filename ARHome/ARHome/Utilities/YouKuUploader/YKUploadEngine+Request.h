//
//  YKUploadEngine+Request.h
//  YouKuUploaderDemo
//
//  Created by 周娜 on 16/7/1.
//  Copyright © 2016年 zhouna. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YKUploaderEngine.h"

@interface YKUploaderEngine (Request)

- (void)updateVersionWithParams:(NSDictionary *)uploadParams
                        success:(void (^)(id responseObject))success
                        failure:(void (^)(NSError *error))failure;

- (void)refreshTokenWithParams:(NSDictionary *)uploadParams
                       success:(void (^)(id responseObject))success
                       failure:(void (^)(NSError *error))failure;

- (void)createWithParams:(NSDictionary *)uploadParams
                 success:(void (^)(id responseObject))success
                 failure:(void (^)(NSError *error))failure;

- (void)createFileWithParams:(NSDictionary *)uploadParams
                     success:(void (^)(id responseObject))success
                     failure:(void (^)(NSError *error))failure;

- (void)newSliceWithParams:(NSDictionary *)uploadParams
                   success:(void (^)(id responseObject))success
                   failure:(void (^)(NSError *error))failure;

- (void)uploadSliceWithParams:(NSDictionary *)uploadParams
                      success:(void (^)(id responseObject))success
                      failure:(void (^)(NSError *error))failure;

- (void)checkUploadWithParams:(NSDictionary *)uploadParams
                      success:(void (^)(id responseObject))success
                      failure:(void (^)(NSError *error))failure;

- (void)commitUploadWithParams:(NSDictionary *)uploadParams
                       success:(void (^)(id responseObject))success
                       failure:(void (^)(NSError *error))failure;
@end
