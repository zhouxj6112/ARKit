//
//  SettingViewController.m
//  ARHome
//
//  Created by MrZhou on 2017/12/22.
//  Copyright © 2017年 vipme. All rights reserved.
//

#import "SettingViewController.h"
#import "PrefixHeader.h"
#import "BatchDownloadViewController.h"

@implementation SettingViewController

- (void)loadView {
    [super loadView];
    self.view.backgroundColor = [UIColor whiteColor];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"设置";
    
    UIButton* resetButton = [UIButton buttonWithType:UIButtonTypeCustom];
    resetButton.frame = CGRectMake(60, 120, 120, 44);
    [resetButton setTitle:@"重置AR" forState:UIControlStateNormal];
    [resetButton setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
    [resetButton addTarget:self action:@selector(resetAR:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:resetButton];
    
    UIButton* saveButton = [UIButton buttonWithType:UIButtonTypeCustom];
    saveButton.frame = CGRectMake(60, 180, 120, 44);
    [saveButton setTitle:@"保存当前场景" forState:UIControlStateNormal];
    [saveButton setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
    [saveButton addTarget:self action:@selector(saveLasted:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:saveButton];
    
    UIButton* recoverButton = [UIButton buttonWithType:UIButtonTypeCustom];
    recoverButton.frame = CGRectMake(60, 240, 120, 44);
    [recoverButton setTitle:@"恢复上次场景" forState:UIControlStateNormal];
    [recoverButton setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
    [recoverButton addTarget:self action:@selector(recoverLasted:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:recoverButton];
    
    UIButton* enterButton = [UIButton buttonWithType:UIButtonTypeCustom];
    enterButton.frame = CGRectMake(60, 300, 150, 44);
    [enterButton setTitle:@"进入批量下载界面" forState:UIControlStateNormal];
    [enterButton setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
    [enterButton addTarget:self action:@selector(enterBatchDownload:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:enterButton];
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
    [self dismissViewControllerAnimated:YES completion:NULL];
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

- (void)resetAR:(id)sender {
    [self dismissViewControllerAnimated:YES completion:NULL];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"kNotificationResetAR" object:self userInfo:nil];
}

- (void)enterBatchDownload:(id)sender {
    BatchDownloadViewController* vc = [[BatchDownloadViewController alloc] initWithNibName:nil bundle:Nil];
    UINavigationController* nav = [[UINavigationController alloc] initWithRootViewController:vc];
    UIViewController* rootViewController = self.presentingViewController;
    [self dismissViewControllerAnimated:NO completion:^{
        [rootViewController presentViewController:nav animated:YES completion:NULL];
    }];
}

- (void)saveLasted:(id)sender {
    [self dismissViewControllerAnimated:YES completion:NULL];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"kNotificationRecoverLasted" object:self userInfo:@{@"oper":@"save"}];
}

- (void)recoverLasted:(id)sender {
    [self dismissViewControllerAnimated:YES completion:NULL];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"kNotificationRecoverLasted" object:self userInfo:@{@"oper":@"recover"}];
}

@end
