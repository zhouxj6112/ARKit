//
//  SettingViewController.m
//  ARHome
//
//  Created by MrZhou on 2017/12/22.
//  Copyright © 2017年 vipme. All rights reserved.
//

#import "SettingViewController.h"

@implementation SettingViewController

- (void)loadView {
    [super loadView];
    self.view.backgroundColor = [UIColor whiteColor];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"设置";
    
    UILabel* label = [[UILabel alloc] initWithFrame:CGRectMake(60, 150, self.view.frame.size.width-120, 20)];
    label.text = @"总下载文件大小:";
    label.textColor = [UIColor blackColor];
    [self.view addSubview:label];
    {
        NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString* docDir = [paths objectAtIndex:0];
        float f = [self folderSizeAtPath:docDir];
        label.text = [NSString stringWithFormat:@"总下载文件大小: %.3fM", f];
    }
    
    UIButton* button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(60, 240, self.view.frame.size.width-120, 44);
    button.backgroundColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:0.5];
    [button setTitle:@"清空所有下载文件" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(clearAll:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
}

- (void)clearAll:(id)sender {
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSError* error;
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* docDir = [paths objectAtIndex:0];
    NSFileManager* manager = [NSFileManager defaultManager];
    NSEnumerator *childFilesEnumerator = [[manager subpathsAtPath:docDir] objectEnumerator];
    NSString* fileName;
    while ((fileName = [childFilesEnumerator nextObject]) != nil) {
        NSString* fileAbsolutePath = [docDir stringByAppendingPathComponent:fileName];
        BOOL bRet = [fileManager removeItemAtPath:fileAbsolutePath error:&error];
        if (!bRet) {
            NSLog(@"%@", error.localizedDescription);
        }
    }
    [self.navigationController popViewControllerAnimated:YES];
}

//单个文件的大小
- (long long) fileSizeAtPath:(NSString*) filePath {
    NSFileManager* manager = [NSFileManager defaultManager];
    
    if ([manager fileExistsAtPath:filePath]){
        return [[manager attributesOfItemAtPath:filePath error:nil] fileSize];
    }
    return 0;
}

- (float) folderSizeAtPath:(NSString *)folderPath {
    NSFileManager* manager = [NSFileManager defaultManager];
    
    if (![manager fileExistsAtPath:folderPath]) return 0;
    
    NSEnumerator *childFilesEnumerator = [[manager subpathsAtPath:folderPath] objectEnumerator];
    
    NSString* fileName;
    
    long long folderSize = 0;
    
    while ((fileName = [childFilesEnumerator nextObject]) != nil) {
        NSString* fileAbsolutePath = [folderPath stringByAppendingPathComponent:fileName];
        folderSize += [self fileSizeAtPath:fileAbsolutePath];
    }
    return folderSize/(1024.0*1024.0);
}

@end
