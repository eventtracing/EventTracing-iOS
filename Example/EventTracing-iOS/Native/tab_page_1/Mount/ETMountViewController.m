//
//  ETMountViewController.m
//  EventTracing-iOS_Example
//
//  Created by 熊勋泉 on 2022/12/14.
//  Copyright © 2022 9446796. All rights reserved.
//

#import "ETMountViewController.h"
#import "UIColor+ET.h"
#import <EventTracing/EventTracing.h>

#define VIEW_TOP 90
#define VIEW_WIDTH 50

@interface ETMountViewController ()
@property (nonatomic, strong) UIButton * logicMountButton;
@property (nonatomic, strong) UIView * view1; // = page => nil
@property (nonatomic, strong) UIView * view2; // => page
@property (nonatomic, strong) UIView * view2Sub1; // => v2
@property (nonatomic, strong) UIView * view2Sub2; // => v1
@property (nonatomic, strong) UIView * view2Sub3; // => virtual_oid  => v1

@property (nonatomic, strong) UIButton * showFloatBtn; // 浮层测试（可见区域穿透）
@property (nonatomic, strong) UIView * floatView;

@property (nonatomic, strong) UIButton * showCoverBtn; // 浮层遮挡
@property (nonatomic, strong) UIView * coverView;

@property (nonatomic, strong) UIViewController * logicParentVC;
@end

@implementation ETMountViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.view1];
    [self.view addSubview:self.view2];
    [self.view2 addSubview:self.view2Sub1];
    [self.view2 addSubview:self.view2Sub2];
    [self.view2 addSubview:self.view2Sub3];
    
    [self setupLogicVC];
    
    [self.view addSubview:self.showFloatBtn];
    [self.view addSubview:self.showCoverBtn];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // MARK: 默认根节点
    // MARK: spm = mount_root_1
    [EventTracingBuilder view:self.view pageId:@"mount_root_1"];
    
    // MARK: 逻辑根节点
    // MARK: spm = mount_root_logic
    [[EventTracingBuilder viewController:self.logicParentVC pageId:@"mount_root_logic"] build:^(id<EventTracingLogNodeBuilder>  _Nonnull builder) {
        //builder.logicalParentViewController(self.parentViewController);
        builder.logicalParentView(self.view.superview);//.autoMountOnCurrentRootPage(YES);
    }];
    //[self.logicParentVC.view et_setRootPage:YES];
    
    // MARK: 默认挂载在 mount_root_1
    // MARK: spm = mount_view_page_1|mount_root_1
    [[EventTracingBuilder view:self.view1 pageId:@"mount_view_page_1"] build:^(id<EventTracingLogNodeBuilder>  _Nonnull builder) {
        //builder.logicalParentViewController(self.logicParentVC);
    }];
    // MARK: 手动逻辑挂载到 mount_root_logic
    // MARK: spm = mount_view_page_2|mount_root_logic
    [[EventTracingBuilder view:self.view2 pageId:@"mount_view_page_2"] build:^(id<EventTracingLogNodeBuilder>  _Nonnull builder) {
        builder
            .logicalParentViewController(self.logicParentVC)
            .visibleRectCalculateStrategy(ETNodeVisibleRectCalculateStrategyPassthrough);
    }];
    // MARK: 默认挂载到 mount_view_page_1
    // MARK: spm = mount_subview_1|mount_root_logic
    [[EventTracingBuilder view:self.view2Sub1 elementId:@"mount_subview_1"] build:^(id<EventTracingLogNodeBuilder>  _Nonnull builder) {
        builder
            // .logicalParentView(self.view1)
            .logicalParentSPM(@"mount_root_logic")
            .visibleRectCalculateStrategy(ETNodeVisibleRectCalculateStrategyPassthrough)
            .buildinEventLogDisableStrategy(ETNodeBuildinEventLogDisableStrategyNone);
    }];
    // MARK: 手动逻辑挂载到 mount_view_page_1（默认挂载 mount_view_page_2）
    // MARK: spm = mount_subview_2|mount_view_page_1|mount_root_1
    [[EventTracingBuilder view:self.view2Sub2 elementId:@"mount_subview_2"] build:^(id<EventTracingLogNodeBuilder>  _Nonnull builder) {
        builder
            .logicalParentView(self.view1)
            .visibleRectCalculateStrategy(ETNodeVisibleRectCalculateStrategyPassthrough)
            .buildinEventLogDisableStrategy(ETNodeBuildinEventLogDisableStrategyNone);
    }];
    // MARK: 手动逻辑挂载到 mount_view_page_1（默认挂载 mount_view_page_2），同时设置虚拟父节点 virtual_parent_oid
    // MARK: 因此 spm 会是 mount_subview_3|virtual_parent_oid|mount_view_page_1|mount_root_1
    [[EventTracingBuilder view:self.view2Sub3 elementId:@"mount_subview_3"] build:^(id<EventTracingLogNodeBuilder>  _Nonnull builder) {
        builder
            .logicalParentView(self.view1)
            .visibleRectCalculateStrategy(ETNodeVisibleRectCalculateStrategyPassthrough)
            .virtualParent(@"virtual_parent_oid", self, ^(id<EventTracingLogVirtualParentNodeBuilder>  _Nonnull virtualBuilder) {
                virtualBuilder.params.set(@"virtual_para_key", @"virtual_para_val123");
            });
    }];
    
    // MARK: 可见区域穿透
    [EventTracingBuilder view:self.showFloatBtn elementId:@"float_btn"];
}

- (void)setupLogicVC
{
    _logicParentVC = [[UIViewController alloc] init];
    _logicParentVC.view.backgroundColor = [UIColor et_randomColor];
    [_logicParentVC willMoveToParentViewController:self];
    [self addChildViewController:_logicParentVC];
    [self.view addSubview:_logicParentVC.view];
    _logicParentVC.view.frame = CGRectMake(10, VIEW_TOP, 200, VIEW_WIDTH);
    UILabel *label = [[UILabel alloc] initWithFrame:_logicParentVC.view.bounds];
    label.text = @"LogicVC";
    label.textAlignment = NSTextAlignmentCenter;
    label.font = [UIFont boldSystemFontOfSize:30];
    [_logicParentVC.view addSubview:label];
    [_logicParentVC didMoveToParentViewController:self];
}

+ (UIView *)makeViewWithLeftTop:(CGPoint)leftTop size:(CGFloat)size
{
    UIView * view = [[UIView alloc] initWithFrame:CGRectMake(leftTop.x, leftTop.y, size, size)];
    view.backgroundColor = [UIColor et_randomColor];
    view.layer.borderColor = [UIColor blackColor].CGColor;
    view.layer.borderWidth = 2;
    return view;
}

+ (UIView *)makeViewWithLeftTop:(CGPoint)leftTop
{
    return [self makeViewWithLeftTop:leftTop size:VIEW_WIDTH];
}

- (UIView *)view1 {
    if (!_view1) {
        _view1 = [ETMountViewController makeViewWithLeftTop:CGPointMake(10, VIEW_TOP + VIEW_WIDTH + 10) size:VIEW_WIDTH * 3];
        _view1.backgroundColor = [UIColor et_randomColor];
    }
    return _view1;
}

- (UIView *)view2 {
    if (!_view2) {
        _view2 = [ETMountViewController makeViewWithLeftTop:CGPointMake(10 + VIEW_WIDTH * 3 + 10, VIEW_TOP + VIEW_WIDTH + 10) size:VIEW_WIDTH * 3];
    }
    return _view2;
}

- (UIView *)view2Sub1 {
    if (!_view2Sub1) {
        _view2Sub1 = [ETMountViewController makeViewWithLeftTop:CGPointMake(10, 10)];
    }
    return _view2Sub1;
}

- (UIView *)view2Sub2 {
    if (!_view2Sub2) {
        _view2Sub2 = [ETMountViewController makeViewWithLeftTop:CGPointMake(10 + VIEW_WIDTH + 10, 10)];
    }
    return _view2Sub2;
}

- (UIView *)view2Sub3 {
    if (!_view2Sub3) {
        _view2Sub3 = [ETMountViewController makeViewWithLeftTop:CGPointMake(10, 10 + VIEW_WIDTH + 10)];
    }
    return _view2Sub3;
}

#pragma mark - 可见区域穿透
- (void)showFloat:(id)sender {
    if (self.floatView.superview) {
        [UIView animateWithDuration:0.3 animations:^{
            CGRect frame = self.floatView.subviews.firstObject.frame;
            frame.origin.y += 400;
            self.floatView.subviews.firstObject.frame = frame;
        } completion:^(BOOL finished) {
            [self.floatView removeFromSuperview];
            self.floatView = nil;
        }];
    } else {
        [self.view.window addSubview:self.floatView];
        [UIView animateWithDuration:0.3 animations:^{
            CGRect frame = self.floatView.subviews.firstObject.frame;
            frame.origin.y -= 400;
            self.floatView.subviews.firstObject.frame = frame;
        } completion:^(BOOL finished) {
        }];
    }
}

- (UIButton *)showFloatBtn {
    if (!_showFloatBtn) {
        _showFloatBtn = [[UIButton alloc] initWithFrame:CGRectMake(10, self.view1.bounds.origin.y + self.view1.bounds.size.height + 10, 200, 40)];
        _showFloatBtn.backgroundColor = [[UIColor blueColor] colorWithAlphaComponent:0.3];
        _showFloatBtn.layer.cornerRadius = 4;
        _showFloatBtn.layer.masksToBounds = YES;
        [_showFloatBtn setTitle:@"点击弹出浮层" forState:UIControlStateNormal];
        [_showFloatBtn addTarget:self action:@selector(showFloat:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _showFloatBtn;
}

- (UIView *)floatView {
    if (!_floatView) {
        _floatView = [[UIView alloc] initWithFrame:UIScreen.mainScreen.bounds];
        _floatView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.1];
        _floatView.userInteractionEnabled = NO;
        UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake(0, UIScreen.mainScreen.bounds.size.height,
                                                                    UIScreen.mainScreen.bounds.size.width, 400)];
        label.backgroundColor = [UIColor et_randomColor];
        label.text = @"浮窗";
        label.textColor = [UIColor whiteColor];
        label.layer.cornerRadius = 8;
        label.layer.masksToBounds = YES;
        label.textAlignment = NSTextAlignmentCenter;
        [_floatView addSubview:label];
        
        // MARK: 可见区域穿透
        [[EventTracingBuilder view:_floatView elementId:@"float_alert"] build:^(id<EventTracingLogNodeBuilder>  _Nonnull builder) {
            builder
                .logicalParentSPM(@"float_btn|mount_root_1")
                .visiblePassthrough(YES)
            ;
        }];
    }
    return _floatView;
}

#pragma mark - 遮挡
- (void)showCover:(id)sender {
    if (self.coverView.superview) {
        [UIView animateWithDuration:0.3 animations:^{
            CGRect frame = self.coverView.frame;
            frame.origin.y = frame.size.height;
            self.coverView.frame = frame;
        } completion:^(BOOL finished) {
            [self.coverView removeFromSuperview];
            self.coverView = nil;
        }];
    } else {
        [self.navigationController.view addSubview:self.coverView];
        [UIView animateWithDuration:0.3 animations:^{
            CGRect frame = self.coverView.frame;
            frame.size.height = 50;
            self.coverView.frame = frame;
        } completion:^(BOOL finished) {
        }];
    }
}

- (UIButton *)showCoverBtn {
    if (!_showCoverBtn) {
        _showCoverBtn = [[UIButton alloc] initWithFrame:CGRectMake(10, self.view1.bounds.origin.y + self.view1.bounds.size.height + 10 + 50, 200, 40)];
        _showCoverBtn.backgroundColor = [[UIColor blueColor] colorWithAlphaComponent:0.3];
        _showCoverBtn.layer.cornerRadius = 4;
        _showCoverBtn.layer.masksToBounds = YES;
        [_showCoverBtn setTitle:@"弹出遮挡浮层" forState:UIControlStateNormal];
        [_showCoverBtn addTarget:self action:@selector(showCover:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _showCoverBtn;
}

- (UIView *)coverView {
    if (!_coverView) {
        _coverView = [[UILabel alloc] initWithFrame:UIScreen.mainScreen.bounds];
        CGRect frame = _coverView.frame;
        frame.origin.y = frame.size.height;
        _coverView.frame = frame;
        
        _coverView.backgroundColor = [UIColor colorWithWhite:0.5 alpha:1];
        _coverView.userInteractionEnabled = YES;
        _coverView.accessibilityLabel = @"CoverLabel";
        ((UILabel *)_coverView).text = @"(page遮挡验证)\n点击退出";
        ((UILabel *)_coverView).font = [UIFont boldSystemFontOfSize:40];
        ((UILabel *)_coverView).textColor = [UIColor whiteColor];
        ((UILabel *)_coverView).textAlignment = NSTextAlignmentCenter;
        ((UILabel *)_coverView).numberOfLines = 0;
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showCover:)];
        [_coverView addGestureRecognizer:tap];
        // MARK: 可见区域穿透
        [[EventTracingBuilder view:_coverView pageId:@"cover_alert_page"] build:^(id<EventTracingLogNodeBuilder>  _Nonnull builder) {
            builder.logicalParentView(self.navigationController.view);
        }];
    }
    return _coverView;
}

@end
