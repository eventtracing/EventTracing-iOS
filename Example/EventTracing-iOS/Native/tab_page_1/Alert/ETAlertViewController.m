//
//  ETAlertViewController.m
//  EventTracing-iOS_Example
//
//  Created by dl on 2022/12/15.
//  Copyright © 2022 9446796. All rights reserved.
//

#import "ETAlertViewController.h"
#import "UIColor+ET.h"
#import "EventTracingTestLogComing.h"

@interface ETAlertViewController ()

@end

@implementation ETAlertViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    [EventTracingBuilder viewController:self pageId:@"page_alert"];
    
    [self addShowAlertBtn];
    [self addShowActionSheetBtn];
}

- (void)addShowAlertBtn {
    UIButton *showAlertBtn = [[UIButton alloc] init];
    [showAlertBtn setTitle:@"ShowAlert" forState:UIControlStateNormal];
    [showAlertBtn setBackgroundColor:[UIColor et_randomColor]];
    [EventTracingBuilder view:showAlertBtn elementId:@"btn_show_alert"];
    [self.view addSubview:showAlertBtn];
    [showAlertBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(20.f);
        make.top.mas_equalTo(100.f);
        make.size.mas_equalTo(CGSizeMake(150, 44));
    }];
    @weakify(self)
    [showAlertBtn bk_addEventHandler:^(id sender) {
        @strongify(self)
        /// MARK: 这里故意延后执行
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self showAlert];
        });
    } forControlEvents:UIControlEventTouchUpInside];
}

- (void)addShowActionSheetBtn {
    UIButton *btn = [[UIButton alloc] init];
    [btn setTitle:@"ShowSheet" forState:UIControlStateNormal];
    [EventTracingBuilder view:btn elementId:@"btn_show_sheet"];
    [btn setBackgroundColor:[UIColor et_randomColor]];
    [self.view addSubview:btn];
    [btn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(-20.f);
        make.top.mas_equalTo(100.f);
        make.size.mas_equalTo(CGSizeMake(150, 44));
    }];
    @weakify(self)
    [btn bk_addEventHandler:^(id sender) {
        @strongify(self)
        [self showActionSheet];
    } forControlEvents:UIControlEventTouchUpInside];
}

- (void)showAlert {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Alert"
                                                                   message:@"Alert做了额外扩展，可以在Alert维度支持设置page节点，以及在 `UIAlertAction` 维度为按钮设置节点"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    NSString *pageId = @"page_float_alert";
    [[EventTracingBuilder viewController:alert pageId:pageId] build:^(id<EventTracingLogNodeBuilder>  _Nonnull builder) {
        builder
        .params
        .ctype(@"alert")
        .cid([NSUUID UUID].UUIDString);
    }];
    
    UIAlertAction *OK = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [EventTracingAllTestLogComings().lastObject alertController:pageId didClickActionWithElementId:@"btn" position:1];
    }];
    [OK et_setElementId:@"btn" position:1 params:@{
        @"alert_btn_ok_p_key": @"alert_btn_ok_p_value"
    } eventAction:^(EventTracingEventActionConfig * _Nonnull config) {
        config.useForRefer = YES;
    }];
    [alert addAction:OK];
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [EventTracingAllTestLogComings().lastObject alertController:pageId didClickActionWithElementId:@"btn" position:2];
    }];
    [alert addAction:cancel];
    [alert et_configLastestActionWithElementId:@"btn" position:2 params:@{
        @"alert_btn_cancel_p_key": @"alert_btn_cancel_p_value"
    } eventAction:^(EventTracingEventActionConfig * _Nonnull config) {
        config.increaseActseq = NO;
    }];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)showActionSheet {
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:@"Sheet" message:@"Alert扩展，同时适用于 Sheet 样式" preferredStyle:UIAlertControllerStyleActionSheet];
    NSString *pageId = @"page_float_sheet";
    [[EventTracingBuilder viewController:sheet pageId:pageId] build:^(id<EventTracingLogNodeBuilder>  _Nonnull builder) {
        builder
        .params
        .ctype(@"sheet")
        .cid([NSUUID UUID].UUIDString);
    }];
    
    UIAlertAction *OK = [UIAlertAction actionWithTitle:@"你很帅" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [EventTracingAllTestLogComings().lastObject alertController:pageId didClickActionWithElementId:@"btn_handsome_boy" position:1];
    }];
    [OK et_setElementId:@"btn_handsome_boy" position:1 params:@{
        @"sheet_btn_handsome_boy_p_key": @"sheet_btn_handsome_boy_p_value"
    } eventAction:^(EventTracingEventActionConfig * _Nonnull config) {
        config.increaseActseq = NO;
    }];
    [sheet addAction:OK];
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [EventTracingAllTestLogComings().lastObject alertController:pageId didClickActionWithElementId:@"btn_cancel" position:2];
    }];
    [sheet addAction:cancel];
    [sheet et_configLastestActionWithElementId:@"btn_cancel" position:2 params:@{
        @"sheet_btn_cancel_p_key": @"sheet_btn_cancel_p_value"
    }];
    
    [self presentViewController:sheet animated:YES completion:nil];
}

@end
