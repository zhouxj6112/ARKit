//
//  YKUploaderUtil.h
//  YouKuUploaderDemo
//
//  Created by 周娜 on 16/6/23.
//  Copyright © 2016年 zhouna. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface YKUploaderUtil : NSObject

+ (NSString *)crcFromData:(NSData *)data;
+ (NSString *)md5FromFile:(NSString *)filename;
+ (NSString *)ipFromHost:(NSString *)host;
+ (BOOL)validateClientId:(NSString *)clientid clientSecret:(NSString *)secret;
+ (BOOL)checkParamsValidWithVideoId:(NSString *)vid;

@end
