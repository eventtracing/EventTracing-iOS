//
//  EventTracingUIViewControllerAOP.m
//  BlocksKit
//
//  Created by dl on 2021/2/24.
//

#import "EventTracingUIViewControllerAOP.h"
#import "EventTracingEngine+Private.h"
#import "UIView+EventTracingPrivate.h"

#import <JRSwizzle/JRSwizzle.h>

@interface UIViewController (EventTracingAOP)

@end
@implementation UIViewController (EventTracingAOP)

- (void)et_viewController_viewWillAppear:(BOOL)animated {
    self.et_transitioning = YES;
    
    [self et_viewController_viewWillAppear:animated];
    
    // 将导航栏上的节点，逻辑挂载到 从`NavigationController.view` '向下查找' 找到的第一个page节点上
    // 最内层的vc，这个时候发现会不在view树中，dispatch async 之后是OK的（放在下一个runloop中）
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.navigationController.navigationBar) {
            self.navigationController.navigationBar.et_logicalParentView = ET_FindSubNodeViewAt(self.navigationController.view, YES);
        }
    });
}

- (void)et_viewController_viewDidAppear:(BOOL)animated {
    [self et_viewController_viewDidAppear:animated];
    
    self.et_transitioning = NO;
    [[EventTracingEngine sharedInstance] appViewController:self changedToAppear:YES];
}

- (void)et_viewController_viewWillDisappear:(BOOL)animated {
    self.et_transitioning = YES;
    
    [self et_viewController_viewWillDisappear:animated];
}

- (void)et_viewController_viewDidDisappear:(BOOL)animated {
    [self.view et_tryRefreshDynamicParamsCascadeSubViews];
    [[EventTracingEngine sharedInstance] appViewController:self changedToAppear:NO];

    [self et_viewController_viewDidDisappear:animated];
    
    self.et_transitioning = NO;
}

@end

@implementation EventTracingUIViewControllerAOP

EventTracingAOPInstanceImp

- (void)inject {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [UIViewController jr_swizzleMethod:@selector(viewWillAppear:) withMethod:@selector(et_viewController_viewWillAppear:) error:nil];
    });
}

- (void)asyncInject {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [UIViewController jr_swizzleMethod:@selector(viewDidAppear:) withMethod:@selector(et_viewController_viewDidAppear:) error:nil];
        [UIViewController jr_swizzleMethod:@selector(viewWillDisappear:) withMethod:@selector(et_viewController_viewWillDisappear:) error:nil];
        [UIViewController jr_swizzleMethod:@selector(viewDidDisappear:) withMethod:@selector(et_viewController_viewDidDisappear:) error:nil];
    });
}

@end
