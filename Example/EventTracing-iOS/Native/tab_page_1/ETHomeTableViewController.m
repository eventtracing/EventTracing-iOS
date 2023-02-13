//
//  ETHomeTableViewController.m
//  EventTracing-iOS_Example
//
//  Created by xxq on 2022/12/9.
//  Copyright © 2022 9446796. All rights reserved.
//

#import "ETHomeTableViewController.h"
#import "ETMainTestCell.h"
#import "ETMainTestCellItem.h"
#import "ETMainTestInputCell.h"
#import "ETAutoImpressController.h"

#import "ETHomeParamsViewController.h"
#import "ETVisibleViewController.h"
#import "ETMountViewController.h"
#import "ETReferViewController.h"
#import "ETAlertViewController.h"
#import "ETEventViewController.h"
#import "ETLogoutViewController.h"
#import "ETH5ViewController.h"
#import "ETQRCodeScanViewController.h"

typedef NS_ENUM(NSInteger, ETTest) {
    ETTestAutoImpress,     // 自动曝光
    ETTestParams,          // 参数
    ETTestVisibleArea,     // 可见区域
    ETTestLogicMount,      // 逻辑挂载
    ETTestReferTrack,      // 链路追踪
    ETTestEvent,           // 事件
    ETTestLogOut,          // 日志输出
    ETTestUIAlert,         // UIAlertController
    ETTestH5,              // H5 页
    ETTestLogViewer,       // 实时校验（扫码连接）
    ETTestMAX
};

@interface ETHomeTableViewController () <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) NSDictionary<NSNumber *, ETMainTestCellItem *> *optionToItem;
@property (nonatomic, strong) NSString * inputPlaceholder;
@end

#define ADD_TEST_ITEM(_ETTest, _Title) @(_ETTest):[ETMainTestCellItem itemWithTitle:@#_Title target:self action:@selector(_ETTest:)]

@implementation ETHomeTableViewController

- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        if (@available(iOS 13.0, *)) {
            UIImage *image = [UIImage systemImageNamed:@"square.and.arrow.up"];
            self.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Home" image:image tag:0];
        } else {
            // Fallback on earlier versions
        }
    }
    return self;
}

- (NSDictionary<NSNumber *,ETMainTestCellItem *> *)optionToItem {
    if (!_optionToItem) {
        _optionToItem = @{
            ADD_TEST_ITEM(ETTestAutoImpress, 自动曝光),
            ADD_TEST_ITEM(ETTestParams,参数),
            ADD_TEST_ITEM(ETTestVisibleArea,可见区域),
            ADD_TEST_ITEM(ETTestLogicMount,逻辑挂载),
            ADD_TEST_ITEM(ETTestReferTrack,链路追踪),
            ADD_TEST_ITEM(ETTestEvent,事件测试),
            ADD_TEST_ITEM(ETTestLogOut,日志输出),
            ADD_TEST_ITEM(ETTestUIAlert,系统Alert),
            ADD_TEST_ITEM(ETTestH5,H5 页),
            ADD_TEST_ITEM(ETTestLogViewer,实时校验(扫码连接)),
        };
    }
    return _optionToItem;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.accessibilityLabel = @"Demo列表";
    [self.tableView registerClass:ETMainTestCell.class forCellReuseIdentifier:NSStringFromClass(ETMainTestCell.class)];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.tableFooterView = [UIView new];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.contentInset = UIEdgeInsetsMake(10, 0, 50, 0);

    [EventTracingBuilder viewController:self pageId:@"mod_list_page"];
    
    [[EventTracingBuilder view:self.tableView elementId:@"mod_list_table"] build:^(id<EventTracingLogNodeBuilder>  _Nonnull builder) {
#if 1
        builder.virtualParent(@"mod_virtual_parent_of_table", self, ^(id<EventTracingLogVirtualParentNodeBuilder>  _Nonnull virtualBuilder) {
            virtualBuilder.params.set(@"virtual_key", @"virtual_val");
        });
#else
        builder.visibleEdgeInsets(UIEdgeInsetsMake(0.f, 0.f, CGRectGetHeight(self.tabBarController.tabBar.bounds), 0.f))
        .params
        .set(@"drand48", @(drand48()).stringValue)
        .set(@"my_key1", @"my_valu1");
#endif
    }];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self.view endEditing:YES];
}

#pragma mark - tableview
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return ETTestMAX;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    ETMainTestCell *btnCell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass(ETMainTestCell.class) forIndexPath:indexPath];
    ETMainTestCellItem *item = [self.optionToItem objectForKey:@(indexPath.row)];
    [btnCell configWithItem:item];
    cell = btnCell;
    NSInteger position = indexPath.section * 100 + indexPath.row;
    
#if 0
    NSString *virtualParentOid = (indexPath.row % 2 == 0) ? @"mode_virtual_parent_even" : @"mode_virtual_parent_odd";
    NSString *virtualParentIdentifier = [NSString stringWithFormat:@"%@-%ld", virtualParentOid, indexPath.row / 2];
    [cell et_build:^(id<EventTracingLogNodeBuilder>  _Nonnull builder) {
        builder
            .virtualParent(virtualParentOid, virtualParentIdentifier, ^(id<EventTracingLogVirtualParentNodeBuilder>  _Nonnull virtualBuilder) {
                virtualBuilder
                    .params
                    .addParams(@{@"param_virtual_parent_key": @"param_virtual_parent_value"});
            })
            .bindDataForReuse(item)
            .params
            .position(position);
    }];
#else
    [cell et_build:^(id<EventTracingLogNodeBuilder>  _Nonnull builder) {
        builder.bindDataForReuse(item)
            .params
            .position(position);
    }];
#endif
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    ETMainTestCellItem *item = [self.optionToItem objectForKey:@(indexPath.row)];
    if (!item) {
        return;
    }
    NSMethodSignature *sign = [item.target methodSignatureForSelector:item.action];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:sign];
    invocation.target = item.target;
    invocation.selector = item.action;
    [invocation invoke];
}

#pragma mark - test imp
- (void)ETTestAutoImpress:(id)sender {
    NSLog(@"ETTest cell clicked - %s\n", __func__);
    ETAutoImpressController * listVC = [[ETAutoImpressController alloc] init];
    [self.navigationController pushViewController:listVC animated:YES];
} // 自动曝光
- (void)ETTestParams:(id)sender {
    NSLog(@"ETTest cell clicked - %s\n", __func__);
    [self.navigationController pushViewController:[ETHomeParamsViewController new] animated:YES];
} // 动态参数
- (void)ETTestVisibleArea:(id)sender {
    NSLog(@"ETTest cell clicked - %s\n", __func__);
    [self.navigationController pushViewController:[ETVisibleViewController new] animated:YES];
} // 可见区域
- (void)ETTestLogicMount:(id)sender {
    NSLog(@"ETTest cell clicked - %s\n", __func__);
    [self.navigationController pushViewController:[ETMountViewController new] animated:YES];
} // 逻辑挂载
- (void)ETTestReferTrack:(id)sender {
    NSLog(@"ETTest cell clicked - %s\n", __func__);
    [self.navigationController pushViewController:[ETReferViewController new] animated:YES];
} // 链路追踪
- (void)ETTestEvent:(id)sender {
    NSLog(@"ETTest cell clicked - %s\n", __func__);
    [self.navigationController pushViewController:[ETEventViewController new] animated:YES];
} // 事件
- (void)ETTestLogOut:(id)sender {
    [self.navigationController pushViewController:[ETLogoutViewController new] animated:YES];
    NSLog(@"ETTest cell clicked - %s\n", __func__);
} // 日志输出
- (void)ETTestUIAlert:(id)sender {
    NSLog(@"ETTest cell clicked - %s\n", __func__);
    [self.navigationController pushViewController:[ETAlertViewController new] animated:YES];
} // UIAlertController
- (void)ETTestH5:(id)sender {
    NSLog(@"ETTest cell clicked - %s\n", __func__);
    [self.navigationController pushViewController:[ETH5ViewController new] animated:YES];
} // H5 页
- (void)ETTestLogViewer:(id)sender {
    NSLog(@"ETTest cell clicked - %s\n", __func__);
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [[EventTracingLogRealtimeViewer sharedInstance] setupWithOptions:EventTracingLogRealtimeViewerOptions.new];
        
        [[NSNotificationCenter defaultCenter] addObserverForName:@"et.log.realtime" object:nil queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification * _Nonnull note) {
            NSDictionary * info =  note.object;
            NSString * msg = [info objectForKey:@"msg"];
            UIAlertController * alert = [UIAlertController alertControllerWithTitle:nil message:msg preferredStyle:UIAlertControllerStyleAlert];
            [self.navigationController presentViewController:alert animated:YES completion:nil];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [alert dismissViewControllerAnimated:YES completion:nil];
            });
        }];
    });
    ETQRCodeScanViewController * scanVC = [[ETQRCodeScanViewController alloc] init];
    scanVC.didFinishScanBlk = ^(NSString * _Nonnull text) {
        NSURL * url = [NSURL URLWithString:text];
        if (!url || ![url.query hasPrefix:@"ws="]) {
            return;
        }
        NSString * path = [url.query substringFromIndex:@"ws=".length];
        NSString * connectToken = [path lastPathComponent];
        NSString * connectPath = [path stringByDeletingLastPathComponent];
        [[EventTracingLogRealtimeViewer sharedInstance] connectWithPath:connectPath connectToken:connectToken];
    };
    [self.navigationController presentViewController:scanVC animated:YES completion:nil];
    
} // 实时校验（扫码连接）

@end
