//
//  ETAutoImpressController.m
//  EventTracing-iOS_Example
//
//  Created by xxq on 2022/12/12.
//  Copyright © 2022 9446796. All rights reserved.
//

#import "ETAutoImpressController.h"
#import "UITableView+ETDemo.h"
#import <Masonry/Masonry.h>

@interface ETAutoImpressController () <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) UITableView * tableView;
@property (nonatomic, strong) UIButton * exitButton;
@end

@implementation ETAutoImpressController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor grayColor];
    [self.view addSubview:self.tableView];
    [self.view addSubview:self.exitButton];
    [self.exitButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(100);
        make.left.equalTo(self.view).offset(10);
        make.size.mas_equalTo(CGSizeMake(120, 40));
    }];
    
    [EventTracingBuilder viewController:self pageId:@"auto_impress_page"];
    [[EventTracingBuilder view:self.tableView elementId:@"auto_impress_test_list"] build:^(id<EventTracingLogNodeBuilder>  _Nonnull builder) {
        builder
            .buildinEventLogDisableStrategy(ETNodeBuildinEventLogDisableStrategyNone)
            .params.set(@"auto_key", @"auto_val_123");
    }];
    self.tableView.et_esEventEnable = YES;
}

- (void)exit:(id)sender {
    if (self.navigationController && self.navigationController.topViewController == self) {
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (UITableView *)tableView {
    if (!_tableView)
    {
        _tableView = [UITableView et_demo_tableViewWithProvider:self bgColor:UIColor.whiteColor contentInset:UIEdgeInsetsZero];
        _tableView.frame = self.view.bounds;
        _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _tableView.accessibilityLabel = @"列表";
        _tableView.accessibilityIdentifier = @"列表";
    }
    return _tableView;
}

- (UIButton *)exitButton {
    if (!_exitButton)
    {
        _exitButton = [[UIButton alloc] initWithFrame:CGRectMake(10, 20, 120, 40)];
        _exitButton.layer.cornerRadius = 6;
        _exitButton.layer.masksToBounds = YES;
        _exitButton.backgroundColor = [UIColor brownColor];
        [_exitButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        [_exitButton setTitle:@"退出" forState:UIControlStateNormal];
        [_exitButton addTarget:self action:@selector(exit:) forControlEvents:UIControlEventTouchUpInside];
        [[EventTracingBuilder view:_exitButton elementId:@"exit_btn"] build:^(id<EventTracingLogNodeBuilder>  _Nonnull builder) {
            builder
                //.buildinEventLogDisableStrategy(ETNodeBuildinEventLogDisableStrategyNone)
                .addClickParamsCallback(^(id<EventTracingLogNodeParamsBuilder>  _Nonnull params) {
                    params.set(@"custom_para_time", @(NSDate.date.timeIntervalSince1970).stringValue);
                });
        }];
    }
    return _exitButton;
}

#pragma mark - UITableViewDelegate, UITableViewDataSource
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 9999;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 5;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Cell"];
        [[EventTracingBuilder view:cell elementId:@"auto_impress_cell"] build:^(id<EventTracingLogNodeBuilder>  _Nonnull builder) {
            builder.buildinEventLogDisableStrategy(ETNodeBuildinEventLogDisableStrategyNone);
        }];
    }
    NSInteger position = indexPath.section * 5 + indexPath.row + 1; // position 要从 1开始
    cell.backgroundColor = [UIColor colorWithHue:((indexPath.section * 5 + indexPath.row) % 360) / 360.0
                                      saturation:1.0
                                      brightness:0.5
                                           alpha:1.0];
    cell.textLabel.text = [NSString stringWithFormat:@"color: %@", cell.backgroundColor.description];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"indexPath: %@ - %@",  @(indexPath.section), @(indexPath.row)];
    cell.textLabel.textColor = [UIColor colorWithWhite:1 alpha:1];
    cell.detailTextLabel.textColor = [UIColor colorWithWhite:1 alpha:1];
    [cell et_build:^(id<EventTracingLogNodeBuilder>  _Nonnull builder) {
        builder.bindDataForReuse(indexPath)
            .params
            .position(position)
            .set(@"index", @(indexPath.section * 5 + indexPath.row).stringValue);
    }];
    return cell;
}

@end
