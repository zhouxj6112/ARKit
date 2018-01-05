//
//  YKUploaderConfig.h
//  YouKuUploaderDemo
//
//  Created by 周娜 on 16/6/22.
//  Copyright © 2016年 zhouna. All rights reserved.
//

#ifndef YKUploaderConfig_h
#define YKUploaderConfig_h


#endif /* YKUploaderConfig_h */

#ifdef DEBUG
#define YKLog( s, ... ) NSLog( @"< %@:(%d) > %@ ----- %@", [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__, [NSString stringWithFormat:(s), ##__VA_ARGS__], [NSThread currentThread])
#else
#define YKLog( s, ... )
#endif

#define YOUKU_VERSION @"2017042019"

/**
 * 分片最大长度KB
 */
#define YOUKU_SLICE_LENGTH 2048

/**
 * 一般接口请求 timeout
 */
#define YOUKU_TIMEOUT 15

/**
 * upload slice 接口 timeout
 */
#define YOUKU_TIMEOUT_UPLOAD_DATA 30

/**
 * check 2、3时 sleep
 */
#define YOUKU_SLEEPTIME 20

/**
 * error code ( 仅以下特殊code，其他均通过接口返回，更多查看主站提供error code 文档 )
 */
#define YOUKU_ERROR_1001 @"Client error"
#define YOUKU_ERROR_1002 @"Service exception occured"
#define YOUKU_ERROR_1012 @"Necessary parameter missing"
#define YOUKU_ERROR_1013 @"Invalid parameter"
#define YOUKU_ERROR_1014 @"The video clip does not exist"

/**
 * 自定义 custom
 */
#define YOUKU_ERROR_50002 @"connect exception"

#define YOUKU_ERROR_TYPE_FILE_NOT_FOUND @"FileNotFoundException"
#define YOUKU_ERROR_TYPE_SYSTEM @"SystemException"
#define YOUKU_ERROR_TYPE_CONNECT @"ConnectException"
