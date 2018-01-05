//
//  YKUploadEngine+Request.m
//  YouKuUploaderDemo
//
//  Created by 周娜 on 16/7/1.
//  Copyright © 2016年 zhouna. All rights reserved.
//

#import "YKUploadEngine+Request.h"
#import "AFHTTPSessionManager.h"
#import "YKUploaderConfig.h"
#import "YKUploaderUtil.h"

@implementation YKUploaderEngine (Request)


- (void)updateVersionWithParams:(NSDictionary *)uploadParams
                        success:(void (^)(id responseObject))success
                        failure:(void (^)(NSError *error))failure
{
    NSURL *URL = [NSURL URLWithString:@"https://api.youku.com/sdk/version_update"];
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer.timeoutInterval = YOUKU_TIMEOUT;
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    NSDictionary *params = @{
                             @"client_id" : self.clientId,
                             @"version" : YOUKU_VERSION,
                             @"category" : @"upload",
                             @"type" : @"ios"
                             };
    [manager GET:URL.absoluteString parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        success(responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        failure(error);
    }];
}

- (void)refreshTokenWithParams:(NSDictionary *)uploadParams
                       success:(void (^)(id responseObject))success
                       failure:(void (^)(NSError *error))failure
{
    NSURL *URL = [NSURL URLWithString:@"https://api.youku.com/oauth2/token"];
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer.timeoutInterval = YOUKU_TIMEOUT;
    
    NSDictionary *params = @{
                             @"client_id" : self.clientId,
                             @"client_secret" : self.clientSecret,
                             @"refresh_token" : self.refreashToken,
                             @"grant_type" : @"refresh_token",
                             };
    [manager POST:URL.absoluteString parameters:params constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        success(responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        failure(error);
    }];
}

- (void)createWithParams:(NSDictionary *)uploadParams
                      success:(void (^)(id responseObject))success
                      failure:(void (^)(NSError *error))failure
{
    NSURL *URL = [NSURL URLWithString:@"https://api.youku.com/uploads/create.json"];
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer.timeoutInterval = YOUKU_TIMEOUT;

    NSDictionary *params = @{
                             @"client_id" : self.clientId,
                             @"access_token" : self.accessToken,
                             @"target" : @"youku",
                             @"file_name" : [uploadParams objectForKey:@"file_name"],
                             @"file_md5" : [uploadParams objectForKey:@"file_md5"],
                             @"file_size" : [uploadParams objectForKey:@"file_size"],
                             @"title" : [uploadParams objectForKey:@"title"],
                             @"public_type" : [uploadParams objectForKey:@"public_type"],
                             @"tags" : [uploadParams objectForKey:@"tags"],
                             };
    NSMutableDictionary *mParams = [NSMutableDictionary dictionaryWithDictionary:params];
    if ([uploadParams objectForKey:@"public_type"] && [[uploadParams objectForKey:@"public_type"] isEqualToString:@"password"]) {
        [mParams setObject:[uploadParams objectForKey:@"watch_password"] forKey:@"watch_password"];
    }
    [manager GET:URL.absoluteString parameters:mParams progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        success(responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        failure(error);
    }];
}

- (void)createFileWithParams:(NSDictionary *)uploadParams
                     success:(void (^)(id responseObject))success
                     failure:(void (^)(NSError *error))failure
{
    NSString *ip = [YKUploaderUtil ipFromHost:[uploadParams objectForKey:@"upload_server_uri"]];
    NSString *url = [NSString stringWithFormat:@"http://%@/gupload/create_file",ip];
    NSURL *URL = [NSURL URLWithString:url];
//    NSURL *URL = [NSURL URLWithString:@"http://220.181.183.58/gupload/create_file"];
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer.timeoutInterval = YOUKU_TIMEOUT;
    
    NSDictionary *params = @{
                             @"upload_token" : [uploadParams objectForKey:@"upload_token"],
                             @"file_size" : [uploadParams objectForKey:@"file_size"],
                             @"ext" : [uploadParams objectForKey:@"ext"],
                             @"slice_length" : [NSString stringWithFormat:@"%d", YOUKU_SLICE_LENGTH],
                             };
//    NSDictionary *params = @{
//                             @"upload_token" : @"MTQ4OTE5NjkwXzAxMDA2NDNBQTI1NzgzNUYyN0IxRkIwNjM2NTUyQkE2MkIzMzdCLTE1MTktMjZBQy02ODQxLTg3Q0MzNDVGNjRERl8xX2MxZjk0YTFhNGM4MjU1ZTJjNDE0ZmU3NDQwY2Q3NmY2",
//                             @"file_size" : @"47485912",
//                             @"ext" : @"mov",
//                             @"slice_length" : [NSString stringWithFormat:@"%d", YOUKU_SLICE_LENGTH],
//                             };
//    YKLog(@"create_file url:%@", URL.absoluteString);
//    YKLog(@"create_file params:%@", params);
    
    [manager POST:URL.absoluteString parameters:params constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        success(responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        failure(error);
    }];
    
}

- (void)newSliceWithParams:(NSDictionary *)uploadParams
                   success:(void (^)(id responseObject))success
                   failure:(void (^)(NSError *error))failure
{
    NSString *ip = [YKUploaderUtil ipFromHost:[uploadParams objectForKey:@"upload_server_uri"]];
    NSString *url = [NSString stringWithFormat:@"http://%@/gupload/new_slice",ip];
    NSURL *URL = [NSURL URLWithString:url];
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer.timeoutInterval = YOUKU_TIMEOUT;

    NSDictionary *params = @{
                             @"upload_token" : [uploadParams objectForKey:@"upload_token"],
                            };
    [manager GET:URL.absoluteString parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        success(responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        failure(error);
    }];
}

- (void)uploadSliceWithParams:(NSDictionary *)uploadParams
                       success:(void (^)(id responseObject))success
                       failure:(void (^)(NSError *error))failure
{
    NSString *ip = [YKUploaderUtil ipFromHost:[uploadParams objectForKey:@"upload_server_uri"]];
    NSString *url = [NSString stringWithFormat:@"http://%@/gupload/upload_slice?ver=2.0&upload_token=%@&slice_task_id=%@&offset=%@&length=%@&crc=%@",ip,[uploadParams objectForKey:@"upload_token"], [uploadParams objectForKey:@"slice_task_id"], [uploadParams objectForKey:@"offset"], [uploadParams objectForKey:@"length"], [YKUploaderUtil crcFromData:[uploadParams objectForKey:@"data"]]];

    NSURL *URL = [NSURL URLWithString:url];
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer.timeoutInterval = YOUKU_TIMEOUT_UPLOAD_DATA;
//    manager.requestSerializer.removeBoundary = true;
    
    NSDictionary *params = @{@"data" : [uploadParams objectForKey:@"data"]};
    ;
    [manager POST:URL.absoluteString parameters:params constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        success(responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        failure(error);
    }];
}

- (void)checkUploadWithParams:(NSDictionary *)uploadParams
                      success:(void (^)(id responseObject))success
                      failure:(void (^)(NSError *error))failure
{
    NSString *ip = [YKUploaderUtil ipFromHost:[uploadParams objectForKey:@"upload_server_uri"]];
    NSString *url = [NSString stringWithFormat:@"http://%@/gupload/check",ip];
    NSURL *URL = [NSURL URLWithString:url];
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer.timeoutInterval = YOUKU_TIMEOUT;

    NSDictionary *params = @{
                             @"upload_token" : [uploadParams objectForKey:@"upload_token"],
                             };
    [manager GET:URL.absoluteString parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        success(responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        failure(error);
    }];
}

- (void)commitUploadWithParams:(NSDictionary *)uploadParams
                       success:(void (^)(id responseObject))success
                       failure:(void (^)(NSError *error))failure
{
    NSURL *URL = [NSURL URLWithString:@"https://api.youku.com/uploads/commit.json"];
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer.timeoutInterval = YOUKU_TIMEOUT;
    
    NSDictionary *params = @{
                             @"client_id" : self.clientId,
                             @"access_token" : self.accessToken,
                             @"upload_token" : [uploadParams objectForKey:@"upload_token"],
                             @"upload_server_ip" : [uploadParams objectForKey:@"upload_server_ip"],
                             };
    [manager POST:URL.absoluteString parameters:params constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        success(responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        failure(error);
    }];
}

@end
