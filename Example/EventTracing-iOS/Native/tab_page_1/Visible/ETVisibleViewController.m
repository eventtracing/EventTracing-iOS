//
//  ETVisibleViewController.m
//  EventTracing-iOS_Example
//
//  Created by dl on 2022/12/14.
//  Copyright © 2022 9446796. All rights reserved.
//

#import "ETVisibleViewController.h"
#import "UIColor+ET.h"
#import <BlocksKit/UIView+BlocksKit.h>

@interface ETVisibleViewController ()
@property(nonatomic, strong) UILabel *l1;
@property(nonatomic, strong) UILabel *l2;
@property(nonatomic, strong) UILabel *l3;
@property(nonatomic, strong) UILabel *l4;

@property(nonatomic, strong) UIView *floatViewBg;
@property(nonatomic, strong) UIView *floatView;
@property(nonatomic, strong) UIButton *closeBtnOnFloatView;
@end

@implementation ETVisibleViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    [[EventTracingBuilder viewController:self pageId:@"page_visible"] build:^(id<EventTracingLogNodeBuilder>  _Nonnull builder) {
        builder
            .visibleEdgeInsetsTop(200)
            .visibleEdgeInsetsLeft(20)
            .visibleEdgeInsetsRight(20)
            .visibleEdgeInsetsBottom(200);
    }];
    
    [self addLabels];
    [self addControlsForLabel3];
    [self addFloatViewShowBtn];
}

- (void)addFloatViewShowBtn {
    UIButton *showFloatViewBtn = [[UIButton alloc] init];
    [showFloatViewBtn setTitle:@"Show" forState:UIControlStateNormal];
    showFloatViewBtn.backgroundColor = [UIColor et_randomColor];
    [self.view addSubview:showFloatViewBtn];
    [showFloatViewBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(100.f);
        make.right.mas_equalTo(-20);
        make.size.mas_equalTo(CGSizeMake(100, 44));
    }];
    @weakify(self)
    [showFloatViewBtn bk_addEventHandler:^(id sender) {
        @strongify(self)
        [self showFloatView];
    } forControlEvents:UIControlEventTouchUpInside];
}

- (void)showFloatView {
    UIView *floatViewBg = [[UIView alloc] init];
    floatViewBg.backgroundColor = [UIColor clearColor];
    floatViewBg.alpha = 0.f;
    [[UIApplication sharedApplication].keyWindow addSubview:floatViewBg];
    [floatViewBg mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.centerX.centerY.equalTo(self.view);
    }];
    UIView *floatView = [[UIView alloc] init];
    floatView.backgroundColor = [UIColor whiteColor];
    [[UIApplication sharedApplication].keyWindow addSubview:floatView];
    [[EventTracingBuilder view:floatView pageId:@"page_float_example_0"] build:^(id<EventTracingLogNodeBuilder>  _Nonnull builder) {
        builder.autoMountOnCurrentRootPage(YES);
    }];
    [floatView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.centerX.bottom.equalTo(floatViewBg);
        make.top.mas_equalTo(250.f + 25.f); // 覆盖 l3 一半
    }];
    [[UIApplication sharedApplication].keyWindow layoutIfNeeded];
    
    void(^closeBlock)(void) = ^() {
        [UIView animateWithDuration:0.3 animations:^{
            floatView.transform = CGAffineTransformMakeTranslation(0.f, floatView.bounds.size.height);
            floatViewBg.backgroundColor = [UIColor clearColor];
        } completion:^(BOOL finished) {
            [floatViewBg removeFromSuperview];
            [floatView removeFromSuperview];
        }];
    };
    UIButton *closeBtn = [[UIButton alloc] init];
    [closeBtn setTitle:@"Close" forState:UIControlStateNormal];
    [closeBtn setBackgroundColor:[UIColor greenColor]];
    [floatView addSubview:closeBtn];
    [EventTracingBuilder view:closeBtn elementId:@"btn_close"];
    [closeBtn bk_addEventHandler:^(id sender) {
        closeBlock();
    } forControlEvents:UIControlEventTouchUpInside];
    [floatViewBg bk_whenTapped:^{
        closeBlock();
    }];
    [closeBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(floatView);
        make.size.mas_equalTo(CGSizeMake(150, 40));
    }];
    
    floatView.transform = CGAffineTransformMakeTranslation(0.f, floatView.bounds.size.height);
    [UIView animateWithDuration:0.3f animations:^{
        floatViewBg.alpha = 0.5f;
        floatView.transform = CGAffineTransformIdentity;
        floatViewBg.backgroundColor = [UIColor lightGrayColor];
    } completion:^(BOOL finished) {
    }];
}

- (void)addLabels {
    self.l1 = [self createViewWithIndex:1];
    self.l2 = [self createViewWithIndex:2];
    self.l3 = [self createViewWithIndex:3];
    self.l4 = [self createViewWithIndex:4];
    
    // l1 被父节点 全部裁剪掉, 节点不可见
    self.l1.text = @"被裁剪，不可见";
    [self.l1 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(100);
        make.left.equalTo(self.view).offset(20.f);
        make.size.mas_equalTo(CGSizeMake(150, 50));
    }];
    
    // l2 节点被 部分裁剪，节点可见
    self.l2.text = @"部分裁剪，可见";
    [self.l2 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(170);
        make.left.equalTo(self.view).mas_offset(20);
        make.size.mas_equalTo(CGSizeMake(150, 50));
    }];
    
    // l3 节点完全可见
    self.l3.text = @"完全可见，浮层遮挡部分";
    [self.l3 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(250);
        make.left.equalTo(self.view).offset(60);
        make.size.mas_equalTo(CGSizeMake(150, 50));
    }];
    /// MARK: 开启 _ed 埋点
    [self.l3 et_build:^(id<EventTracingLogNodeBuilder>  _Nonnull builder) {
        builder.buildinEventLogDisableImpressend(NO);
    }];
    
    // l4 节点完全可见
    self.l4.text = @"完全可见，浮层可遮挡";
    [self.l4 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(400);
        make.left.equalTo(self.view).offset(60);
        make.size.mas_equalTo(CGSizeMake(150, 50));
    }];
}

- (void)addControlsForLabel3 {
    @weakify(self)
    
    // MARK: 逻辑可见
    UIButton *logicalVisibleBtn = [[UIButton alloc] init];
    logicalVisibleBtn.selected = YES;
    logicalVisibleBtn.backgroundColor = [UIColor greenColor];
    [logicalVisibleBtn setTitle:@"逻辑可见" forState:UIControlStateNormal];
    [logicalVisibleBtn setTitle:@"逻辑不可见" forState:UIControlStateSelected];
    logicalVisibleBtn.accessibilityLabel = @"LogicalVisible";
    [logicalVisibleBtn bk_addEventHandler:^(UIButton *sender) {
        sender.selected = !sender.selected;
        @strongify(self)
        [self.l3 et_build:^(id<EventTracingLogNodeBuilder>  _Nonnull builder) {
            builder.logicalVisible(sender.selected);
        }];
    } forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:logicalVisibleBtn];
    [logicalVisibleBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.view).offset(-20);
        make.top.equalTo(self.l3);
        make.size.mas_equalTo(CGSizeMake(150, 30));
    }];
    
    // MARK: 重新曝光
    UIButton *setNeedsImpressBtn = [[UIButton alloc] init];
    setNeedsImpressBtn.backgroundColor = [UIColor brownColor];
    [setNeedsImpressBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [setNeedsImpressBtn setTitle:@"SetNeedImpress" forState:UIControlStateNormal];
    [setNeedsImpressBtn bk_addEventHandler:^(id sender) {
        @strongify(self)
        [self.l3 et_setNeedsImpress];
    } forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:setNeedsImpressBtn];
    [setNeedsImpressBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.height.equalTo(logicalVisibleBtn);
        make.width.mas_equalTo(150);
        make.top.equalTo(logicalVisibleBtn.mas_bottom).offset(20);
    }];
    
    // MARK: hidden
    UIButton *hiddenBtn = [[UIButton alloc] init];
    hiddenBtn.accessibilityLabel = @"Hidden";
    hiddenBtn.backgroundColor = [UIColor greenColor];
    [hiddenBtn setTitle:@"逻辑可见" forState:UIControlStateNormal];
    [hiddenBtn setTitle:@"逻辑不可见" forState:UIControlStateSelected];
    [hiddenBtn bk_addEventHandler:^(UIButton *sender) {
        @strongify(self)
        sender.selected = !sender.selected;
        self.l3.hidden = sender.selected;
    } forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:hiddenBtn];
    [hiddenBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.width.height.equalTo(logicalVisibleBtn);
        make.top.equalTo(setNeedsImpressBtn.mas_bottom).offset(20);
    }];
    
    // MARK: Alpha
    UIButton *alphaBtn = [[UIButton alloc] init];
    alphaBtn.accessibilityLabel = @"Alpha";
    alphaBtn.selected = YES;
    alphaBtn.backgroundColor = [UIColor greenColor];
    [alphaBtn setTitle:@"Alpha 0" forState:UIControlStateNormal];
    [alphaBtn setTitle:@"Alpha 1" forState:UIControlStateSelected];
    [alphaBtn bk_addEventHandler:^(UIButton *sender) {
        @strongify(self)
        sender.selected = !sender.selected;
        self.l3.alpha = sender.selected ? 1.f : 0.f;
    } forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:alphaBtn];
    [alphaBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.width.height.equalTo(logicalVisibleBtn);
        make.top.equalTo(hiddenBtn.mas_bottom).offset(20);
    }];
}

- (UILabel *)createViewWithIndex:(NSInteger)index {
    UILabel *v = [[UILabel alloc] init];
    v.backgroundColor = [UIColor et_randomColor];
    v.textAlignment = NSTextAlignmentCenter;
    v.font = [UIFont systemFontOfSize:12];
    [[EventTracingBuilder view:v elementId:[NSString stringWithFormat:@"label_%ld", index]] build:^(id<EventTracingLogNodeBuilder>  _Nonnull builder) {
        builder.buildinEventLogDisableImpressend(NO);
    }];
    [self.view addSubview:v];
    return v;
}

@end
