//
//  ETBridgeViewController.m
//  EventTracing-iOS_Example
//
//  Created by 熊勋泉 on 2022/12/16.
//  Copyright © 2022 9446796. All rights reserved.
//

#import "ETBridgeViewController.h"

@interface ETBridgeViewController ()

@end

@implementation ETBridgeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = [NSString stringWithFormat:@"曙光-[不参与]链路追踪-%@层", @(self.depth+1)];
    
    [[EventTracingBuilder viewController:self pageId:[@"bridge_page" stringByAppendingFormat:@"_%@", @(self.depth)]] build:^(id<EventTracingLogNodeBuilder>  _Nonnull builder) {
        //builder.doNotParticipateMultirefer(YES);
    }];
    
    [EventTracingBuilder view:self.pushVCBtn elementId:@"bridge_push_btn"];
    [EventTracingBuilder view:self.presentVCBtn elementId:@"bridge_present_btn"];
    [EventTracingBuilder view:self.exitBtn elementId:@"bridge_exit_btn"];
    [EventTracingBuilder view:self.pushBridgeVCBtn elementId:@"bridge_push_bridge_btn"];
    
    /// 下面的节点不参与 multirefer(链路追踪)
    /// 因此从下面按钮点击出去的事件表现为：有ec事件产生，后续的 multirefers 里无此节点
    /// multirefers 会降级到根节点，即 bridge_page_xx
    self.pushVCBtn.et_psreferMute = YES;
    self.presentVCBtn.et_psreferMute = YES;
    self.exitBtn.et_psreferMute = YES;
    self.pushBridgeVCBtn.et_psreferMute = YES;
}

@end
