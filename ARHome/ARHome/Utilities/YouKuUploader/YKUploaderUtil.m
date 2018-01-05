//
//  YKUploaderUtil.m
//  YouKuUploaderDemo
//
//  Created by 周娜 on 16/6/23.
//  Copyright © 2016年 zhouna. All rights reserved.
//

#import "YKUploaderUtil.h"
#import <zlib.h>
#import <arpa/inet.h>
#import <netdb.h>
#include <math.h>
#import <CommonCrypto/CommonDigest.h>

@implementation YKUploaderUtil

+ (NSString *)crcFromData:(NSData *)data
{
    uLong crc = crc32(0L, Z_NULL, 0);
    crc = crc32(crc, [data bytes], (uInt)[data length]);
    return [NSString stringWithFormat:@"%lx", crc];
}

+ (NSString *)md5FromFile:(NSString *)filename
{
    NSData* data = [NSData dataWithContentsOfFile:filename];
    
    const void* src = [data bytes];
    NSUInteger len = [data length];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(src, (CC_LONG)len, result);
    return [[NSString
             stringWithFormat: @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
             result[0], result[1],
             result[2], result[3],
             result[4], result[5],
             result[6], result[7],
             result[8], result[9],
             result[10], result[11],
             result[12], result[13],
             result[14], result[15]
             ]lowercaseString];
}

+ (NSString *)ipFromHost:(NSString *)host
{
    const char *hostName = [host UTF8String];
    struct hostent* phot;
    
    @try {
        phot = gethostbyname(hostName);
        
    } @catch (NSException *exception) {
        return nil;
    }
    
    struct in_addr ip_addr;
    memcpy(&ip_addr, phot->h_addr_list[0], 4);
    char ip[20] = {0};
    inet_ntop(AF_INET, &ip_addr, ip, sizeof(ip));
    
    NSString* strIPAddress = [NSString stringWithUTF8String:ip];
    return strIPAddress;
}

+ (BOOL)validateClientId:(NSString *)clientid clientSecret:(NSString *)secret
{
    NSPredicate *clientIdMatches = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", @"^[0-9a-z]{16}"];
    NSPredicate *clientSecretMatches = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", @"[0-9a-z]{32}"];
    BOOL isMatch = [clientIdMatches evaluateWithObject:clientid] && [clientSecretMatches evaluateWithObject:secret];
    return isMatch;
}

+ (BOOL)checkParamsValidWithVideoId:(NSString *)vid
{
    if (vid.length > 0 && [vid hasPrefix:@"X"]) {
        return true;
    }
    return false;
}
@end
