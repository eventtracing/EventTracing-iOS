//
//  ETReferViewController.m
//  EventTracing-iOS_Example
//
//  Created by 熊勋泉 on 2022/12/15.
//  Copyright © 2022 9446796. All rights reserved.
//

#import "ETReferViewController.h"
#import "UIColor+ET.h"
#import "ETBridgeViewController.h"
#import <EventTracing/EventTracing.h>

#define VIEW_LEFT 20
#define VIEW_TOP 100
#define VIEW_HEIGHT 50
#define VIEW_WIDTH 200

@interface ETReferViewController ()
@property (nonatomic, strong) UIButton * pushVCBtn;
@property (nonatomic, strong) UIButton * presentVCBtn;
@property (nonatomic, strong) UIButton * exitBtn;
@property (nonatomic, strong) UIButton * pushBridgeVCBtn;
@property (nonatomic, assign) NSInteger depth;
@end

@implementation ETReferViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = [NSString stringWithFormat:@"曙光-链路追踪-%@层", @(self.depth+1)];
    [self.view addSubview:self.pushVCBtn];
    [self.view addSubview:self.presentVCBtn];
    [self.view addSubview:self.exitBtn];
    [self.view addSubview:self.pushBridgeVCBtn];
    
    [EventTracingBuilder viewController:self pageId:[@"refer_page" stringByAppendingFormat:@"_%@", @(self.depth)]];
    [EventTracingBuilder view:self.pushVCBtn elementId:@"push_btn"];
    [EventTracingBuilder view:self.presentVCBtn elementId:@"present_btn"];
    [EventTracingBuilder view:self.exitBtn elementId:@"exit_btn"];
    [EventTracingBuilder view:self.pushBridgeVCBtn elementId:@"push_bridge_btn"];
}

- (instancetype)initWithDepth:(NSInteger)depth {
    if (self = [super init]) {
        _depth = depth;
    }
    return self;
}

- (void)exit:(id)sender {
    if (self.navigationController.childViewControllers.count > 1 && self.navigationController.topViewController == self) {
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)pushVC:(id)sender {
    [self.navigationController pushViewController:[[ETReferViewController alloc] initWithDepth:_depth + 1] animated:YES];
}

- (void)pushBridgeVC:(id)sender {
    [self.navigationController pushViewController:[[ETBridgeViewController alloc] initWithDepth:_depth + 1] animated:YES];
}

- (void)presentVC:(id)sender {
    UINavigationController * nav = [[UINavigationController alloc] initWithRootViewController:[[ETReferViewController alloc] initWithDepth:_depth + 1]];
    [self presentViewController:nav animated:YES completion:nil];
}

- (UIColor *)colorWithHue:(float)hue {
    return [UIColor et_bgColorWithHue:hue];
}

- (UIButton *)pushVCBtn {
    if (!_pushVCBtn) {
        _pushVCBtn = [[UIButton alloc] initWithFrame:CGRectMake(VIEW_LEFT, VIEW_TOP, VIEW_WIDTH, VIEW_HEIGHT)];
        _pushVCBtn.backgroundColor = [self colorWithHue:0.1];
        _pushVCBtn.layer.cornerRadius = 4;
        _pushVCBtn.layer.masksToBounds = YES;
        [_pushVCBtn setTitle:@"PushVC" forState:UIControlStateNormal];
        [_pushVCBtn addTarget:self action:@selector(pushVC:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _pushVCBtn;
}
- (UIButton *)presentVCBtn {
    if (!_presentVCBtn) {
        _presentVCBtn = [[UIButton alloc] initWithFrame:CGRectMake(VIEW_LEFT, self.pushVCBtn.bounds.origin.y + self.pushVCBtn.bounds.size.height + 10, VIEW_WIDTH, VIEW_HEIGHT)];
        _presentVCBtn.backgroundColor = [self colorWithHue:0.5];
        _presentVCBtn.layer.cornerRadius = 4;
        _presentVCBtn.layer.masksToBounds = YES;
        [_presentVCBtn setTitle:@"PresentVC" forState:UIControlStateNormal];
        [_presentVCBtn addTarget:self action:@selector(presentVC:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _presentVCBtn;
}
- (UIButton *)exitBtn {
    if (!_exitBtn) {
        _exitBtn = [[UIButton alloc] initWithFrame:CGRectMake(VIEW_LEFT, self.presentVCBtn.bounds.origin.y + self.presentVCBtn.bounds.size.height + 10, VIEW_WIDTH, VIEW_HEIGHT)];
        _exitBtn.backgroundColor = [self colorWithHue:0.9];
        _exitBtn.layer.cornerRadius = 4;
        _exitBtn.layer.masksToBounds = YES;
        [_exitBtn setTitle:@"ExitVC" forState:UIControlStateNormal];
        [_exitBtn addTarget:self action:@selector(exit:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _exitBtn;
}
- (UIButton *)pushBridgeVCBtn {
    if (!_pushBridgeVCBtn) {
        _pushBridgeVCBtn = [[UIButton alloc] initWithFrame:CGRectMake(VIEW_LEFT, self.exitBtn.bounds.origin.y + self.exitBtn.bounds.size.height + 10, VIEW_WIDTH, VIEW_HEIGHT)];
        _pushBridgeVCBtn.backgroundColor = [self colorWithHue:0.9];
        _pushBridgeVCBtn.layer.cornerRadius = 4;
        _pushBridgeVCBtn.layer.masksToBounds = YES;
        [_pushBridgeVCBtn setTitle:@"PushBridgeVC" forState:UIControlStateNormal];
        [_pushBridgeVCBtn addTarget:self action:@selector(pushBridgeVC:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _pushBridgeVCBtn;
}

@end
