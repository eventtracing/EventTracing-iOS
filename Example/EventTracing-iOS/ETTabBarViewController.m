//
//  ETTabBarViewController.m
//  EventTracing-iOS_Example
//
//  Created by xxq on 2022/12/9.
//  Copyright © 2022 9446796. All rights reserved.
//

#import "ETTabBarViewController.h"

@interface ETTabBarViewController () <EventTracingVTreeNodeExtraConfigProtocol>
@property(nonatomic, strong) UIButton *floatBtn;
@end

@implementation ETTabBarViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[EventTracingBuilder viewController:self pageId:@"page_main"] build:^(id<EventTracingLogNodeBuilder>  _Nonnull builder) {
        builder
            .logicalParentView(self.view.window)
            .params.set(@"abc", @"root.val.abc");
    }];
}

#pragma mark - EventTracingVTreeNodeExtraConfigProtocol
- (NSArray<NSString *> *)et_validForContainingSubNodeOids {
    return @[@"page_tab_vc_1", @"page_tab_vc_2"];
}

@end
