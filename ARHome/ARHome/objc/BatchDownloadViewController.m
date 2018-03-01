//
//  BatchDownloadViewController.m
//  ARHome
//
//  Created by MrZhou on 2018/2/25.
//  Copyright © 2018年 vipme. All rights reserved.
//

#import "BatchDownloadViewController.h"
#import <AFNetworking/AFNetworking.h>
#import <SSZipArchive/SSZipArchive.h>
#import <SDWebImage/UIImageView+WebCache.h>

@interface BatchDownloadTableCell : UITableViewCell
@property (nonatomic, retain) UIImageView* bImageView;
@property (nonatomic, retain) UILabel* bLabel;
@property (nonatomic, retain) UILabel* pLabel;
@end

@implementation BatchDownloadTableCell
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        _bImageView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 2, 40, 40)];
        [self.contentView addSubview:_bImageView];
        _bLabel = [[UILabel alloc] initWithFrame:CGRectMake(60, 2, 120, 40)];
        _bLabel.font = [UIFont systemFontOfSize:14];
        _bLabel.textAlignment = NSTextAlignmentLeft;
        [self.contentView addSubview:_bLabel];
        _pLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.frame.size.width-120, 2, 110, 40)];
        _pLabel.textAlignment = NSTextAlignmentRight;
        _pLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        _pLabel.textColor = [UIColor redColor];
        _pLabel.font = [UIFont systemFontOfSize:12];
        [self.contentView addSubview:_pLabel];
    }
    return self;
}
@end

@interface BatchDownloadViewController () <UITableViewDataSource, UITableViewDelegate, SSZipArchiveDelegate>
{
    NSInteger _curSellerIndex;
}
@property (nonatomic, retain) UITableView* sTableView;
@property (nonatomic, retain) NSArray* sListData;
@property (nonatomic, retain) UITableView* tableView;
@property (nonatomic, retain) NSMutableArray* listData;
@property (nonatomic, retain) AFHTTPSessionManager* sessionManager;
@property (nonatomic, retain) NSMutableArray* downloadArray;
@end

@implementation BatchDownloadViewController

static int DOWNLOAD_SYNC_NUM = 3;

- (void)loadView {
    [super loadView];
    self.view.backgroundColor = [UIColor whiteColor];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationItem.title = @"批量下载";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"关闭" style:UIBarButtonItemStyleDone target:self action:@selector(closeIt:)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"开始" style:UIBarButtonItemStyleDone target:self action:@selector(startDownload:)];
    
    _sTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, 100, self.view.frame.size.height) style:UITableViewStylePlain];
    _sTableView.dataSource = self;
    _sTableView.delegate = self;
    [self.view addSubview:_sTableView];
    
    UITableView* tableView = [[UITableView alloc] initWithFrame:CGRectMake(100, 0, self.view.frame.size.width-100, self.view.frame.size.height) style:UITableViewStylePlain];
    tableView.dataSource = self;
    tableView.delegate = self;
    [self.view addSubview:tableView];
    self.tableView = tableView;
    
    _downloadArray = [NSMutableArray arrayWithCapacity:30];
    _sessionManager = [AFHTTPSessionManager manager];
    _sessionManager.requestSerializer.timeoutInterval = 24*60*60;
    _sessionManager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"text/html", nil];
    [_sessionManager GET:@"http://52.187.182.32/admin/api/getAllSellers?" parameters:nil progress:NULL success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSLog(@"%@", responseObject);
        NSArray* listData = (NSArray *)((NSDictionary *)responseObject[@"data"][@"items"]);
        self.sListData = listData;
        [self.sTableView reloadData];
        {
            NSNumber* preId = [[NSUserDefaults standardUserDefaults] objectForKey:@"user_default_seller_index"];
            if (preId && preId.intValue >= 0) {
                [self.sTableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:preId.intValue inSection:0] animated:YES scrollPosition:UITableViewScrollPositionNone];
                [self.sTableView.delegate tableView:_sTableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:preId.intValue inSection:0]];
            }
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"%@", error);
    }];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshTable:) name:@"kNotificationRefresh" object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)closeIt:(id)sender {
    for (int i=0; i<_sessionManager.downloadTasks.count; i++) {
        NSURLSessionDownloadTask* task = [_sessionManager.downloadTasks objectAtIndex:i];
        [task cancel];
    }
    NSIndexPath* indexPath = self.sTableView.indexPathForSelectedRow;
    if (indexPath) {
        NSNumber* index = @(indexPath.row);
        [[NSUserDefaults standardUserDefaults] setObject:index forKey:@"user_default_seller_index"];
    }
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (NSString *)md5:(NSString *)stringSrc
{
    const char *cStr = [stringSrc UTF8String];
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5( cStr, (CC_LONG)strlen(cStr), digest );
    
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [output appendFormat:@"%02x", digest[i]];
    }
    return output;
}

- (void)startDownload:(id)sender {
    if (_sessionManager.downloadTasks.count > 0) {
        return;
    }
    
    for (int i=0; i<self.listData.count; i++) {
        NSDictionary* dict = self.listData[i];
        NSArray* list = dict[@"list"];
        for (int j=0; j<list.count; j++) {
            NSMutableDictionary* dic = list[j];
            NSString* zipFileUrl = dic[@"fileUrl"];
            // 检测是否下载过了
            NSString* fileName = [self md5:zipFileUrl];
            NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString* documentsDirectory = [paths firstObject];
            NSString* zipFilePath = [NSString stringWithFormat:@"%@/%@", documentsDirectory, fileName];
            BOOL isDir = NO;
            BOOL bRet = [[NSFileManager defaultManager] fileExistsAtPath:zipFilePath isDirectory:&isDir];
            if (!bRet) {
                //
                [self downloadOne:dic];
            }
        }
    }
    NSLog(@"%@", _sessionManager.downloadTasks);
    if (_sessionManager.downloadTasks.count > 0) {
        self.navigationItem.rightBarButtonItem.title = @"下载中";
    }
}

- (void)downloadOne:(NSMutableDictionary *)dic {
    NSString* zipFileUrl = dic[@"fileUrl"];
    
    NSString* fileName = [self md5:zipFileUrl];
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* documentsDirectory = [paths firstObject];
    NSString* zipFilePath = [NSString stringWithFormat:@"%@/%@", documentsDirectory, fileName];
    
    NSString* enZipFileUrl = [zipFileUrl stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:enZipFileUrl] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:60*60];
    __block NSURLSessionDownloadTask* task = [_sessionManager downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
        //NSLog(@"下载进度:%@", downloadProgress);
        [dic setObject:[NSString stringWithFormat:@"%.2f%%", downloadProgress.fractionCompleted*100] forKey:@"progress"];
        // 更新table界面
        [[NSNotificationCenter defaultCenter] postNotificationName:@"kNotificationRefresh" object:nil];
    } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        return [NSURL URLWithString:zipFilePath]; // 下载路径
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        if (error == nil) {
            NSLog(@"下载完成: %@", zipFileUrl);
            // 下载完成,解压到当前文件
            NSString* toFilePath = [NSString stringWithFormat:@"%@/", zipFilePath];
            BOOL bRet = [[NSFileManager defaultManager] createDirectoryAtPath:toFilePath withIntermediateDirectories:YES attributes:nil error:nil];
            if (bRet) {
                NSError* error = nil;
                [SSZipArchive unzipFileAtPath:zipFilePath toDestination:toFilePath overwrite:YES password:nil error:nil delegate:self];
                if (error) {
                    NSLog(@"解压失败:%@", error);
                }
            }
        } else {
            NSLog(@"下载error: %@", error);
            [dic setObject:@"下载失败" forKey:@"progress"];
            // 更新table界面
            [[NSNotificationCenter defaultCenter] postNotificationName:@"kNotificationRefresh" object:nil];
        }
        NSLog(@"还剩%lu个下载任务", (unsigned long)_sessionManager.downloadTasks.count);
        [_downloadArray removeObject:task];
        //
        if (_downloadArray == 0) {
            self.navigationItem.rightBarButtonItem.title = @"开始";
        } else {
            // 注意,找到剩下队列中第一个需要resume的对象
            for (NSURLSessionTask* sTask in _downloadArray) {
                if (sTask.state == NSURLSessionTaskStateSuspended) {
                    [sTask resume];
                    break;
                }
            }
        }
    }];
    [task resume];
    [_downloadArray addObject:task];
    
    if (_downloadArray.count > DOWNLOAD_SYNC_NUM) {
        [task suspend]; // 挂起
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
- (void)dealloc {
    NSLog(@"BatchDownloadViewController dealloc");
}

- (void)refreshTable:(id)sender {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

#pragma mark -
#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (tableView == _sTableView) {
        return 1;
    }
    return self.listData.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == _sTableView) {
        return self.sListData.count;
    }
    NSDictionary* dic = self.listData[section];
    NSArray* list = dic[@"list"];
    return list.count;
}

//- (nullable NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
//    if (tableView == _sTableView) {
//        return nil;
//    }
//    NSDictionary* dic = self.listData[section];
//    return dic[@"typeName"];
//}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == _sTableView) {
        static NSString* cIden = @"cIden";
        UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cIden];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cIden];
        }
        NSDictionary* dic = self.sListData[indexPath.row];
        cell.textLabel.text = dic[@"sellerName"];
        cell.textLabel.numberOfLines = 0;
        cell.textLabel.font = [UIFont systemFontOfSize:14];
        return cell;
    }
    
    static NSString* cellIden = @"cellIden";
    BatchDownloadTableCell* cell = (BatchDownloadTableCell *)[tableView dequeueReusableCellWithIdentifier:cellIden];
    if (cell == nil) {
        cell = [[BatchDownloadTableCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellIden];
    }
    {
        NSDictionary* dict = self.listData[indexPath.section];
        NSArray* list = dict[@"list"];
        NSDictionary* dic = list[indexPath.row];
        [cell.bImageView sd_setImageWithURL:[NSURL URLWithString:dic[@"compressImage"]]];
        cell.bLabel.text = dic[@"modelName"];
        cell.pLabel.text = dic[@"progress"];
    }
    return cell;
}

#pragma mark -
#pragma mark UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == _sTableView) {
        return 60;
    }
    return 44;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == _sTableView) {
        if (_sessionManager.downloadTasks.count > 0) {
            UIAlertController* controller = [UIAlertController alertControllerWithTitle:@"警告" message:@"下载过程中不允许切换下载" preferredStyle:UIAlertControllerStyleAlert];
            [controller addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                //
            }]];
            [self presentViewController:controller animated:YES completion:NULL];
            [_sTableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:_curSellerIndex inSection:0] animated:NO scrollPosition:UITableViewScrollPositionNone];
            return ;
        }
        NSDictionary* dic = self.sListData[indexPath.row];
        [self changeSeller:dic[@"sellerId"]];
        _curSellerIndex = indexPath.row;
    }
}

- (void)changeSeller:(NSString *)sellerId {
    [_sessionManager GET:@"http://52.187.182.32/admin/api/getModelsList?" parameters:@{@"sellerId":sellerId} progress:NULL success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSLog(@"%@", responseObject);
        NSArray* listData = (NSArray *)((NSDictionary *)responseObject[@"data"]);
        
        NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString* documentsDirectory = [paths firstObject];
        
        NSMutableArray* results = [NSMutableArray arrayWithCapacity:1];
        for (int i=0; i<listData.count; i++) {
            NSDictionary* dic = listData[i];
            NSArray* list = dic[@"list"];
            NSMutableArray* array = [NSMutableArray arrayWithCapacity:1];
            for (int j=0; j<list.count; j++) {
                NSDictionary* dict = list[j];
                NSMutableDictionary* mDic = [NSMutableDictionary dictionaryWithCapacity:1];
                [mDic setDictionary:dict];
                [mDic setObject:@"未下载" forKey:@"progress"];
                // 检测是否下载过了
                NSString* fileName = [self md5:dict[@"fileUrl"]];
                NSString* zipFilePath = [NSString stringWithFormat:@"%@/%@", documentsDirectory, fileName];
                BOOL isDir = NO;
                BOOL bRet = [[NSFileManager defaultManager] fileExistsAtPath:zipFilePath isDirectory:&isDir];
                if (bRet) {
                    [mDic setObject:@"已经下载" forKey:@"progress"];
                }
                [array addObject:mDic];
            }
            NSMutableDictionary* mutableDic = [NSMutableDictionary dictionaryWithCapacity:1];
            [mutableDic setObject:dic[@"typeId"] forKey:@"typeId"];
            [mutableDic setObject:dic[@"typeName"] forKey:@"typeName"];
            [mutableDic setObject:array forKey:@"list"];
            
            [results addObject:mutableDic];
        }
        self.listData = results;
        [self.tableView reloadData];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"%@", error);
    }];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (tableView == _sTableView) {
        return 0;
    }
    return 40;
}

- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (tableView == _sTableView) {
        return nil;
    }
    UIView* headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 40)];
    headerView.backgroundColor = [UIColor whiteColor];
    UILabel* label =[headerView viewWithTag:10];
    if (label == nil) {
        label = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, tableView.frame.size.width, 40)];
        label.font = [UIFont boldSystemFontOfSize:14];
        label.tag = 10;
        [headerView addSubview:label];
    }
    NSDictionary* dic = self.listData[section];
    label.text = dic[@"typeName"];
    return headerView;
}

#pragma mark -
#pragma mark SSZipArchiveDelegate

- (void)zipArchiveProgressEvent:(unsigned long long)loaded total:(unsigned long long)total {
    NSLog(@"解压进度:%f", loaded*1.0/total);
}

@end
