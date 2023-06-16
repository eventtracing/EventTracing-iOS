//
//  ETTabBarViewController.m
//  EventTracing-iOS_Example
//
//  Created by xxq on 2022/12/9.
//  Copyright © 2022 9446796. All rights reserved.
//

#import "ETTabBarViewController.h"
#import <EventTracing/NEEventTracingBuilder.h>

@interface ETTabBarViewController () <NEEventTracingVTreeNodeExtraConfigProtocol>
@property(nonatomic, strong) UIButton *floatBtn;
@end

@implementation ETTabBarViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NEEventTracingBuilder viewController:self pageId:@"page_main"] build:^(id<NEEventTracingLogNodeBuilder>  _Nonnull builder) {
        builder
            .logicalParentView(self.view.window)
            .params.set(@"abc", @"root.val.abc");
    }];
}

#pragma mark - NEEventTracingVTreeNodeExtraConfigProtocol
- (NSArray<NSString *> *)et_validForContainingSubNodeOids {
    return @[@"page_tab_vc_1", @"page_tab_vc_2"];
}

@end
