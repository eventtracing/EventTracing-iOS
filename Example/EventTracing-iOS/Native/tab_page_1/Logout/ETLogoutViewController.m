//
//  ETLogoutViewController.m
//  EventTracing-iOS_Example
//
//  Created by dl on 2022/12/14.
//  Copyright © 2022 9446796. All rights reserved.
//

#import "ETLogoutViewController.h"
#import "UITableView+ETDemo.h"
#import "UIColor+ET.h"
#import "EventTracingTestLogComing.h"
#import <Masonry/Masonry.h>
#import <EventTracing/NEEventTracingBuilder.h>

#define BUTTON_WIDTH 300

static EventTracingTestLogComing * s_logComing;


@interface ETLogoutViewController () <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) UITableView * tableView;
@property (nonatomic, strong) UIButton * refreshButton;
@property (nonatomic, strong) UIButton * gotoBottomButton;
@property (nonatomic, strong) NSArray<NSDictionary *> * logJsons;
@end

@implementation ETLogoutViewController

+ (void)load {
    s_logComing = [EventTracingTestLogComing logComingWithRandomKey];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.tableView];
    [self.view addSubview:self.refreshButton];
    [self.view addSubview:self.gotoBottomButton];
    [self.refreshButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(100);
        make.right.equalTo(self.view).offset(-20);
        make.size.mas_equalTo(CGSizeMake(120, 40));
    }];
    [self.gotoBottomButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.refreshButton.mas_bottom).offset(20);
        make.right.equalTo(self.view).offset(-20);
        make.size.mas_equalTo(CGSizeMake(120, 40));
    }];
    [NEEventTracingBuilder viewController:self pageId:@"log_out_page"];
    self.tableView.ne_et_esEventEnable = YES;
    [self refresh:nil];
}

- (void)refresh:(id)sender {
    self.logJsons = s_logComing.logJsons.reverseObjectEnumerator.allObjects;
    self.title = [NSString stringWithFormat:@"日志数量:%d", (int)self.logJsons.count];
    [self.tableView reloadData];
    dispatch_async(dispatch_get_main_queue(), ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            CGPoint off = self.tableView.contentOffset;
            off.y = 0 - self.tableView.contentInset.top;
            [self.tableView setContentOffset:off animated:YES];
        });
    });
}

- (void)scrollToBottom:(id)sender {
    CGPoint off = self.tableView.contentOffset;
    off.y = self.tableView.contentSize.height - self.tableView.bounds.size.height + self.tableView.contentInset.bottom;
    [self.tableView setContentOffset:off animated:YES];
}

- (UITableView *)tableView {
    if (!_tableView)
    {
        _tableView = [UITableView et_demo_tableViewWithProvider:self
                                                        bgColor:UIColor.whiteColor
                                                   contentInset:UIEdgeInsetsMake(88, 0, 100, 0)];
        _tableView.frame = self.view.bounds;
        _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _tableView.backgroundColor = [UIColor clearColor];
    }
    return _tableView;
}

- (UIButton *)refreshButton {
    if (!_refreshButton)
    {
        _refreshButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.bounds.size.width - 120 - 20, 20, 120, 40)];
        _refreshButton.layer.cornerRadius = 6;
        _refreshButton.layer.masksToBounds = YES;
        _refreshButton.backgroundColor = [UIColor et_bgColorWithHue:0.5];
        [_refreshButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        [_refreshButton setTitle:@"点击刷新" forState:UIControlStateNormal];
        [_refreshButton addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventTouchUpInside];
        [[NEEventTracingBuilder view:_refreshButton elementId:@"refresh_btn"] build:^(id<NEEventTracingLogNodeBuilder>  _Nonnull builder) {
            builder
                //.buildinEventLogDisableStrategy(NEETNodeBuildinEventLogDisableStrategyNone)
                .addClickParamsCallback(^(id<NEEventTracingLogNodeParamsBuilder>  _Nonnull params) {
                    params.set(@"custom_para_time", @(NSDate.date.timeIntervalSince1970).stringValue);
                });
        }];
    }
    return _refreshButton;
}

- (UIButton *)gotoBottomButton {
    if (!_gotoBottomButton)
    {
        _gotoBottomButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.bounds.size.width - 120 - 20, 20, 120, 40)];
        _gotoBottomButton.layer.cornerRadius = 6;
        _gotoBottomButton.layer.masksToBounds = YES;
        _gotoBottomButton.backgroundColor = [UIColor et_bgColorWithHue:0.3];
        [_gotoBottomButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        [_gotoBottomButton setTitle:@"滚到底部" forState:UIControlStateNormal];
        [_gotoBottomButton addTarget:self action:@selector(scrollToBottom:) forControlEvents:UIControlEventTouchUpInside];
        [[NEEventTracingBuilder view:_refreshButton elementId:@"go_bottom_btn"] build:^(id<NEEventTracingLogNodeBuilder>  _Nonnull builder) {
            builder
                //.buildinEventLogDisableStrategy(NEETNodeBuildinEventLogDisableStrategyNone)
                .addClickParamsCallback(^(id<NEEventTracingLogNodeParamsBuilder>  _Nonnull params) {
                    params.set(@"custom_para_time", @(NSDate.date.timeIntervalSince1970).stringValue);
                });
        }];
    }
    return _gotoBottomButton;
}

#pragma mark - UITableViewDelegate, UITableViewDataSource
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 100;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.logJsons.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static const NSInteger kContentLabelTag = 1234;
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
        UILabel * contentLabel = [[UILabel alloc] initWithFrame:cell.bounds];
        contentLabel.tag = kContentLabelTag;
        contentLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [cell addSubview:contentLabel];
        contentLabel.textColor = [UIColor whiteColor];
        contentLabel.numberOfLines = 0;
        contentLabel.font = [UIFont systemFontOfSize:14];
    }
    cell.backgroundColor = [UIColor colorWithHue:(indexPath.row % 100) / 100.0
                                      saturation:1.0
                                      brightness:0.5
                                           alpha:1.0];
    NSDictionary * json = self.logJsons[indexPath.row];
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self options:NSJSONWritingPrettyPrinted error:nil];
    
    NSString * content = [NSString stringWithFormat:@"【%@】%@"
                          , EventTracingDescForEvent(json[NE_ET_CONST_KEY_EVENT_CODE])
                          , [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]];
    if (content.length > 200) {
        content = [content substringToIndex:200];
    }
    [((UILabel *)[cell viewWithTag:kContentLabelTag]) setText:content];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSDictionary *json = self.logJsons[indexPath.row];
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self options:NSJSONWritingPrettyPrinted error:nil];
    NSString * content = [NSString stringWithFormat:@"%@", [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]];
    NSString * title = [NSString stringWithFormat:@"%@\n%@\n%@"
                        , EventTracingDescForEvent(json[NE_ET_CONST_KEY_EVENT_CODE])
                        , json[NE_ET_REFER_KEY_SPM]
                        , json[NE_ET_REFER_KEY_SCM]];
    UIAlertController * alertVC = [UIAlertController alertControllerWithTitle:title message:content preferredStyle:UIAlertControllerStyleAlert];
    [alertVC addAction:[UIAlertAction actionWithTitle:@"复制到剪切板" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UIPasteboard.generalPasteboard.string = content;
    }]];
    [alertVC addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {}]];
    @try {
        UILabel *messageLabel = [alertVC.view valueForKeyPath:@"_messageLabel"];
        if (messageLabel) {
            messageLabel.textAlignment = NSTextAlignmentLeft;
        }
    } @catch (NSException *exception) {
    } @finally {
    }
    [self presentViewController:alertVC animated:YES completion:nil];
}

@end
