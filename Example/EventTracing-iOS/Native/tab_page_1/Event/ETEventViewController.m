//
//  ETEventViewController.m
//  EventTracing-iOS_Example
//
//  Created by dl on 2022/12/14.
//  Copyright © 2022 9446796. All rights reserved.
//

#import "ETEventViewController.h"
#import "UIColor+ET.h"
#import "ETReferViewController.h"
#import <BlocksKit/UIView+BlocksKit.h>
#import <EventTracing/NEEventTracingBuilder.h>

#define BUTTON_WIDTH 300

@interface ETEventViewController ()
@property(nonatomic, strong) UILabel *l1;
@property(nonatomic, strong) UILabel *l2;
@property(nonatomic, strong) UILabel *l3;
@property(nonatomic, strong) UILabel *l4;
@property(nonatomic, strong) UIButton * button;
@end

@implementation ETEventViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self addLabels];
    [self.view addSubview:self.button];
    
    [NEEventTracingBuilder viewController:self pageId:@"event_test_page"];
}

- (void)clickButton:(id)sender {
    NSLog(@"%s", __func__);
}

- (void)tapLabel:(id)sender {
    NSLog(@"%s", __func__);
    if (![sender isKindOfClass:UITapGestureRecognizer.class]) {
        return;
    }
    UIView * view = [(UITapGestureRecognizer *)sender view];
    if (view == self.l2) {
        // 自定义事件，需要有节点，与 VTree 有关，参与链路追踪
        [NEEventTracingBuilder logWithView:view event:^(id<NEEventTracingLogNodeEventActionBuilder>  _Nonnull builder) {
            builder.ec();
        }];
    } else if (view == self.l3) {
        // 手动事件，无节点 无血缘，与 VTree 无关，也不存在链路追踪
        [NEEventTracingBuilder logManuallyWithBuilder:^(id<NEEventTracingLogManuallyEventActionBuilder>  _Nonnull builder) {
            builder
                .event(@"manual_ec")
                // 不参与链路追踪也就无 spm 的必要，这里仅用于测试
                // 手动事件默认不携带内置参数(包括 _eventcode、_spm 等)，如果有必要的话，需要手动添加
                .addParams(@{NE_ET_CONST_KEY_EVENT_CODE:@"manual_ec",
                             NE_ET_REFER_KEY_SPM:@"manual_label"});
        }];
    } else if (view == self.l4) {
        // 手动事件，无节点 无血缘，与 VTree 无关，但是参与链路追踪
        [NEEventTracingBuilder logManuallyUseForReferWithBuilder:^(id<NEEventTracingLogManuallyUseForReferEventActionBuilder>  _Nonnull builder) {
            builder
                .event(@"manual_ec_2")
                .referSPM(@"custom_label|event_test_page")
                .referType(@"custom_refer_type")
                // 手动事件默认不携带内置参数(包括 _eventcode、_spm 等)，如果有必要的话，需要手动添加
                .addParams(@{NE_ET_CONST_KEY_EVENT_CODE:@"manual_ec_2",
                             NE_ET_REFER_KEY_SPM:@"custom_label|event_test_page"});
        }];
        // 跳转到下一个页面，测试refer链路追踪
        [self.navigationController pushViewController:ETReferViewController.new animated:YES];
    }
}

- (UIButton *)button {
    if (!_button) {
        _button = [[UIButton alloc] initWithFrame:CGRectMake(20, 100, BUTTON_WIDTH, 50)];
        [_button addTarget:self action:@selector(clickButton:) forControlEvents:UIControlEventTouchUpInside];
        [_button setTitle:@"按钮点击" forState:UIControlStateNormal];
        [_button setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        _button.layer.cornerRadius = 4;
        _button.layer.masksToBounds = YES;
        [_button setBackgroundColor:[UIColor et_bgColorWithHue:0.7]];
        [[NEEventTracingBuilder view:_button elementId:@"button"] build:^(id<NEEventTracingLogNodeBuilder>  _Nonnull builder) {
            //builder.buildinEventLogDisableImpressend(NO);
        }];
    }
    return _button;
}

- (void)addLabels {
    self.l1 = [self createViewWithIndex:1];
    self.l2 = [self createViewWithIndex:2];
    self.l3 = [self createViewWithIndex:3];
    self.l4 = [self createViewWithIndex:4];
    
    // l1 通过手势点击，也会自动产生ec埋点
    self.l1.text = @"手势点击，自动ec";
    [self.l1 ne_et_setBuildinEventLogDisableStrategy:NEETNodeBuildinEventLogDisableStrategyNone];
    [self.l1 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(170);
        make.left.equalTo(self.view).offset(20.f);
        make.size.mas_equalTo(CGSizeMake(BUTTON_WIDTH, 50));
    }];
    
    // l2
    self.l2.text = @"手势点击，手动ec";
    // 禁止自动点击事件
    [self.l2 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(240);
        make.left.equalTo(self.view).offset(20.f);
        make.size.mas_equalTo(CGSizeMake(BUTTON_WIDTH, 50));
    }];
    
    // l3
    self.l3.text = @"手动事件，无链路追踪";
    // 禁止自动点击事件
    [self.l3 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(310);
        make.left.equalTo(self.view).offset(20.f);
        make.size.mas_equalTo(CGSizeMake(BUTTON_WIDTH, 50));
    }];
    
    // l4
    self.l4.text = @"手动事件，参与链路追踪";
    // 禁止自动点击事件
    [self.l4 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(380);
        make.left.equalTo(self.view).offset(20.f);
        make.size.mas_equalTo(CGSizeMake(BUTTON_WIDTH, 50));
    }];
}

- (UILabel *)createViewWithIndex:(NSInteger)index {
    UILabel *v = [[UILabel alloc] init];
    v.backgroundColor = [UIColor et_bgColorWithHue:[@[@0.1,@0.5,@0.9][index % 3] floatValue]];
    v.textColor = [UIColor whiteColor];
    v.textAlignment = NSTextAlignmentCenter;
    v.font = [UIFont boldSystemFontOfSize:16];
    v.userInteractionEnabled = YES;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapLabel:)];
    [v addGestureRecognizer:tap];
    [[NEEventTracingBuilder view:v elementId:[NSString stringWithFormat:@"label_%ld", index]] build:^(id<NEEventTracingLogNodeBuilder>  _Nonnull builder) {
        builder.buildinEventLogDisableClick();
    }];
    [self.view addSubview:v];
    return v;
}

@end
