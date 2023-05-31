//
//  NEEventTracingUITabbarAOP.m
//  BlocksKit
//
//  Created by dl on 2021/2/24.
//

#import "NEEventTracingUITabbarAOP.h"
#import "NEEventTracingDelegateChain.h"
#import "NEEventTracingEngine+Private.h"

#import <BlocksKit/BlocksKit.h>
#import <JRSwizzle/JRSwizzle.h>
#import <objc/runtime.h>

@interface UITabBar (EventTracingAOP)
@property(nonatomic, strong, setter=ne_et_setTabbarDelegateChain:) NEEventTracingDelegateChain *ne_et_tabbarDelegateChain;
@end

@implementation UITabBar (EventTracingAOP)

NE_ET_DelegateChainHock(tabbar, UITabBarDelegate, ne_et_tabbarDelegateChain, NEEventTracingUITabbarAOP, @[NSStringFromSelector(@selector(tabBar:didSelectItem:))], nil)

- (void)ne_et_setTabbarDelegateChain:(NEEventTracingDelegateChain *)ne_et_tabbarDelegateChain {
    objc_setAssociatedObject(self, @selector(ne_et_tabbarDelegateChain), ne_et_tabbarDelegateChain, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (NEEventTracingDelegateChain *)ne_et_tabbarDelegateChain {
    return objc_getAssociatedObject(self, _cmd);
}

@end

//@interface NEEventTracingUITabbarAOP (EventTracingAOP) <UITabBarDelegate>
//@end
@implementation NEEventTracingUITabbarAOP

NEEventTracingAOPInstanceImp

- (void)inject {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [UITabBar jr_swizzleMethod:@selector(setDelegate:) withMethod:@selector(ne_et_tabbar_setDelegate:) error:nil];
    });
}

- (void)preCallTabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item {
    [[NEEventTracingEngine sharedInstance] AOP_preLogWithEvent:NE_ET_EVENT_ID_E_CLCK view:tabBar eventAction:^(NEEventTracingEventActionConfig * _Nonnull config) {
        config.useForRefer = YES;
    }];
}

- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item {
    [[NEEventTracingEngine sharedInstance] AOP_logWithEvent:NE_ET_EVENT_ID_E_CLCK view:tabBar params:@{
        @"_baritem_idx": @([tabBar.items indexOfObject:item]).stringValue,
        @"_baritem_title": (item.title ?: @"")
    } eventAction:^(NEEventTracingEventActionConfig * _Nonnull config) {
        config.useForRefer = YES;
    }];
}

@end
