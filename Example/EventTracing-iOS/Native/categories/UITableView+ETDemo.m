//
//  UITableView+ETDemo.m
//  ETDemo
//
//  Created by xxq on 2022/4/13.
//

#import "UITableView+ETDemo.h"

@implementation UITableView (ETDemo)

+ (instancetype)et_demo_tableViewWithProvider:(id<UITableViewDelegate, UITableViewDataSource>)provider
                                     bgColor:(UIColor *)bgColor
                                contentInset:(UIEdgeInsets)contentInset {
    return
    [self et_demo_tableViewWithProvider:provider
                               bgColor:bgColor
                        separatorStyle:UITableViewCellSeparatorStyleNone
                          contentInset:contentInset
                     useSysFitSafeArea:NO
                            adaptIOS11:YES];
}
+ (instancetype)et_demo_tableViewWithProvider:(id<UITableViewDelegate, UITableViewDataSource>)provider
                                     bgColor:(UIColor *)bgColor
                              separatorStyle:(UITableViewCellSeparatorStyle)separatorStyle
                                contentInset:(UIEdgeInsets)contentInset
                           useSysFitSafeArea:(BOOL)useSysFitSafeArea
                                  adaptIOS11:(BOOL)adaptIOS11 {
    UITableView *tableView = [[UITableView alloc] init];
    tableView.delegate = provider;
    tableView.dataSource = provider;
    tableView.backgroundColor = bgColor;
    tableView.tableFooterView = [[UIView alloc] init];
    tableView.separatorStyle = separatorStyle;
    tableView.contentInset = contentInset;
    
    if (@available(iOS 11.0, *)) {
        tableView.insetsContentViewsToSafeArea = useSysFitSafeArea;
        if (adaptIOS11) {
            [tableView et_demo_adaptediOS11AdjustmentBehavior:UIScrollViewContentInsetAdjustmentNever];
        }
    } else {
        // Fallback on earlier versions
    } // 关闭系统自带的安全区域适配
    return tableView;
}

- (void)et_demo_adaptediOS11AdjustmentBehavior:(UIScrollViewContentInsetAdjustmentBehavior)behavior API_AVAILABLE(ios(11.0)) {
    self.estimatedRowHeight = 0;
    self.estimatedSectionHeaderHeight = 0;
    self.estimatedSectionFooterHeight = 0;
    if ([self respondsToSelector:@selector(contentInsetAdjustmentBehavior)]) {
        if (@available(iOS 11.0, *)) {
            self.contentInsetAdjustmentBehavior = behavior;
        }
    }
}

@end
