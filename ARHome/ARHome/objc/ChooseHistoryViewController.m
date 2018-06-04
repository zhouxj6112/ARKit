//
//  ChooseHistoryViewController.m
//  ARHome
//
//  Created by MrZhou on 2018/5/27.
//  Copyright © 2018年 vipme. All rights reserved.
//

#import "ChooseHistoryViewController.h"

@interface ChooseHistoryViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, retain) NSArray* listData;
@end

@implementation ChooseHistoryViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    UITableView* tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) style:UITableViewStylePlain];
    tableView.dataSource = self;
    tableView.delegate = self;
    [self.view addSubview:tableView];
    
    // 读取文件
    NSString* filePath = [NSString stringWithFormat:@"%@/Documents/his.txt", NSHomeDirectory()];
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        self.listData = [NSArray arrayWithContentsOfFile:filePath];
        [tableView reloadData];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark -
#pragma mark UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.listData.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString* iden = @"";
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:iden];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:iden];
    }
    NSDictionary* dic = self.listData[indexPath.row];
    cell.textLabel.text = dic[@"title"];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", dic[@"createTime"]];
    return cell;
}

#pragma mark -
#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self dismissViewControllerAnimated:YES completion:NULL];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"kNotificationRecoverLasted" object:self userInfo:@{@"oper":@"recover",@"index":@(indexPath.row)}];
}

@end
