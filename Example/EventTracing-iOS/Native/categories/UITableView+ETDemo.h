//
//  UITableView+ETDemo.h
//  ETDemo
//
//  Created by xxq on 2022/4/13.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 提供一些快速创建 tableview  的工厂方法
@interface UITableView (ETDemo)

/// 内部调用的底部方法，缺省一些参数
/// @param provider tableView 的 delegate & datasource
/// @param bgColor 背景色
/// @param contentInset 边距
/*
 [self et_demo_tableViewWithProvider:provider
                            bgColor:bgColor
                     separatorStyle:UITableViewCellSeparatorStyleNone
                       contentInset:contentInset
                  useSysFitSafeArea:NO
                         adaptIOS11:YES];
 */
+ (instancetype)et_demo_tableViewWithProvider:(id<UITableViewDelegate, UITableViewDataSource>)provider
                                     bgColor:(UIColor *)bgColor
                                contentInset:(UIEdgeInsets)contentInset;

/// 创建tableView
/// @param provider tableView 的 delegate & datasource
/// @param bgColor 背景色
/// @param separatorStyle 分割线
/// @param contentInset 边距
/// @param useSysFitSafeArea 是否使用系统的安全边距适配，默认NO
/// @param adaptIOS11 是否适配 iOS11，默认 YES
+ (instancetype)et_demo_tableViewWithProvider:(id<UITableViewDelegate, UITableViewDataSource>)provider
                                     bgColor:(UIColor *)bgColor
                              separatorStyle:(UITableViewCellSeparatorStyle)separatorStyle
                                contentInset:(UIEdgeInsets)contentInset
                           useSysFitSafeArea:(BOOL)useSysFitSafeArea
                                  adaptIOS11:(BOOL)adaptIOS11;

@end

NS_ASSUME_NONNULL_END
