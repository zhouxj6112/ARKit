//
//  ChooseHistoryViewController.m
//  ARHome
//
//  Created by MrZhou on 2018/5/27.
//  Copyright © 2018年 vipme. All rights reserved.
//

#import "ChooseHistoryViewController.h"

@interface ChooseHistoryViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, retain) NSMutableArray* listData;
@end

@implementation ChooseHistoryViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    UITableView* tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) style:UITableViewStylePlain];
    tableView.dataSource = self;
    tableView.delegate = self;
    tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:tableView];
    
    // 读取文件
    NSString* filePath = [NSString stringWithFormat:@"%@/Documents/his.txt", NSHomeDirectory()];
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        NSArray* array = [NSArray arrayWithContentsOfFile:filePath];
        NSArray* list = [[array reverseObjectEnumerator] allObjects];
        if (self.listData == nil) {
            self.listData = [NSMutableArray arrayWithCapacity:1];
        }
        if (list.count > 0) {
            [self.listData addObjectsFromArray:list];
            //
            [tableView reloadData];
        } else {
            UILabel* label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
            label.textAlignment = NSTextAlignmentCenter;
            label.text = @"无历史记录";
            tableView.backgroundView = label;
        }
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
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
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:iden];
    }
    NSDictionary* dic = self.listData[indexPath.row];
    cell.textLabel.text = dic[@"title"];
    cell.detailTextLabel.textColor = [UIColor lightGrayColor];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", dic[@"createTime"]];
    return cell;
}

-(UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleDelete;
}

-(NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return @"删除";
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath  {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self.listData removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self performSelector:@selector(delaySave:) withObject:nil afterDelay:0.5f];
    }
}

#pragma mark -
#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self dismissViewControllerAnimated:YES completion:NULL];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"kNotificationRecoverLasted" object:self userInfo:@{@"oper":@"recover",@"index":@(indexPath.row)}];
}

- (void)delaySave:(id)sender {
    NSString* filePath = [NSString stringWithFormat:@"%@/Documents/his.txt", NSHomeDirectory()];
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        BOOL bRet = [self.listData writeToFile:filePath atomically:YES];
        if (!bRet) {
            NSLog(@"保存文件失败");
        }
    }
}

@end
