//
//  EventTracingUITabbarAOP.m
//  BlocksKit
//
//  Created by dl on 2021/2/24.
//

#import "EventTracingUITabbarAOP.h"
#import "EventTracingDelegateChain.h"
#import "EventTracingEngine+Private.h"

#import <BlocksKit/BlocksKit.h>
#import <JRSwizzle/JRSwizzle.h>
#import <objc/runtime.h>

@interface UITabBar (EventTracingAOP)
@property(nonatomic, strong, setter=et_setTabbarDelegateChain:) EventTracingDelegateChain *et_tabbarDelegateChain;
@end

@implementation UITabBar (EventTracingAOP)

ET_DelegateChainHock(tabbar, UITabBarDelegate, et_tabbarDelegateChain, EventTracingUITabbarAOP, @[NSStringFromSelector(@selector(tabBar:didSelectItem:))], nil)

- (void)et_setTabbarDelegateChain:(EventTracingDelegateChain *)et_tabbarDelegateChain {
    objc_setAssociatedObject(self, @selector(et_tabbarDelegateChain), et_tabbarDelegateChain, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (EventTracingDelegateChain *)et_tabbarDelegateChain {
    return objc_getAssociatedObject(self, _cmd);
}

@end

//@interface EventTracingUITabbarAOP (EventTracingAOP) <UITabBarDelegate>
//@end
@implementation EventTracingUITabbarAOP

EventTracingAOPInstanceImp

- (void)inject {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [UITabBar jr_swizzleMethod:@selector(setDelegate:) withMethod:@selector(et_tabbar_setDelegate:) error:nil];
    });
}

- (void)preCallTabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item {
    [[EventTracingEngine sharedInstance] AOP_preLogWithEvent:ET_EVENT_ID_E_CLCK view:tabBar eventAction:^(EventTracingEventActionConfig * _Nonnull config) {
        config.useForRefer = YES;
    }];
}

- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item {
    [[EventTracingEngine sharedInstance] AOP_logWithEvent:ET_EVENT_ID_E_CLCK view:tabBar params:@{
        @"_baritem_idx": @([tabBar.items indexOfObject:item]).stringValue,
        @"_baritem_title": (item.title ?: @"")
    } eventAction:^(EventTracingEventActionConfig * _Nonnull config) {
        config.useForRefer = YES;
    }];
}

@end
