//
//  NEEventTracingUIViewControllerAOP.m
//  BlocksKit
//
//  Created by dl on 2021/2/24.
//

#import "NEEventTracingUIViewControllerAOP.h"
#import "NEEventTracingEngine+Private.h"
#import "UIView+EventTracingPrivate.h"

#import <JRSwizzle/JRSwizzle.h>

@interface UIViewController (EventTracingAOP)

@end
@implementation UIViewController (EventTracingAOP)

- (void)ne_et_viewController_viewWillAppear:(BOOL)animated {
    self.ne_et_transitioning = YES;
    
    [self ne_et_viewController_viewWillAppear:animated];
    
    // 将导航栏上的节点，逻辑挂载到 从`NavigationController.view` '向下查找' 找到的第一个page节点上
    // 最内层的vc，这个时候发现会不在view树中，dispatch async 之后是OK的（放在下一个runloop中）
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.navigationController.navigationBar) {
            self.navigationController.navigationBar.ne_et_logicalParentView = NE_ET_FindSubNodeViewAt(self.navigationController.view, YES);
        }
    });
}

- (void)ne_et_viewController_viewDidAppear:(BOOL)animated {
    [self ne_et_viewController_viewDidAppear:animated];
    
    self.ne_et_transitioning = NO;
    [[NEEventTracingEngine sharedInstance] appViewController:self changedToAppear:YES];
}

- (void)ne_et_viewController_viewWillDisappear:(BOOL)animated {
    self.ne_et_transitioning = YES;
    
    [self ne_et_viewController_viewWillDisappear:animated];
}

- (void)ne_et_viewController_viewDidDisappear:(BOOL)animated {
    [self.view ne_et_tryRefreshDynamicParamsCascadeSubViews];
    [[NEEventTracingEngine sharedInstance] appViewController:self changedToAppear:NO];

    [self ne_et_viewController_viewDidDisappear:animated];
    
    self.ne_et_transitioning = NO;
}

@end

@implementation NEEventTracingUIViewControllerAOP

NEEventTracingAOPInstanceImp

- (void)inject {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [UIViewController jr_swizzleMethod:@selector(viewWillAppear:) withMethod:@selector(ne_et_viewController_viewWillAppear:) error:nil];
    });
}

- (void)asyncInject {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [UIViewController jr_swizzleMethod:@selector(viewDidAppear:) withMethod:@selector(ne_et_viewController_viewDidAppear:) error:nil];
        [UIViewController jr_swizzleMethod:@selector(viewWillDisappear:) withMethod:@selector(ne_et_viewController_viewWillDisappear:) error:nil];
        [UIViewController jr_swizzleMethod:@selector(viewDidDisappear:) withMethod:@selector(ne_et_viewController_viewDidDisappear:) error:nil];
    });
}

@end
