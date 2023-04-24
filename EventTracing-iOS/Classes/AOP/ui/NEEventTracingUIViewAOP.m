//
//  NEEventTracingUIViewAOP.m
//  BlocksKit
//
//  Created by dl on 2021/2/24.
//

#import "NEEventTracingUIViewAOP.h"
#import "NEEventTracingDefines.h"
#import "NEEventTracingEngine+Private.h"
#import "UIView+EventTracingPrivate.h"
#import "NEEventTracingClickMonitor.h"
#import "EventTracingConfuseMacro.h"

#import <BlocksKit/BlocksKit.h>
#import <JRSwizzle/JRSwizzle.h>
#import <objc/runtime.h>

@interface UIViewEventTracingAOPTapGesHandler : NSObject
@property(nonatomic, assign) BOOL isPre;
- (void)view_action_gestureRecognizerEvent:(UITapGestureRecognizer *)gestureRecognizer;
@end

@interface UITapGestureRecognizer (EventTracingAOP)
@property(nonatomic, strong, setter=ne_et_setPreGesHandler:) UIViewEventTracingAOPTapGesHandler *ne_et_preGesHandler;
@property(nonatomic, strong, setter=ne_et_setAfterGesHandler:) UIViewEventTracingAOPTapGesHandler *ne_et_afterGesHandler;
@property(nonatomic, strong, readonly) NSMapTable<id, NSMutableSet<NSString *> *> *ne_et_validTargetActions;
@end

@implementation UITapGestureRecognizer (EventTracingAOP)

- (instancetype)ne_et_tap_initWithTarget:(id)target action:(SEL)action {
    if ([self _ne_et_needsAOP]) {
        [self _ne_et_initPreAndAfterGesHanderIfNeeded];
    }
    
    if (target && action) {
        UITapGestureRecognizer *ges = [self init];
        [self addTarget:target action:action];
        return ges;
    }

    return [self ne_et_tap_initWithTarget:target action:action];
}

- (void)ne_et_tap_addTarget:(id)target action:(SEL)action {
    if (!target || !action
        || ![self _ne_et_needsAOP]
        || [[self.ne_et_validTargetActions objectForKey:target] containsObject:NSStringFromSelector(action)]) {
        [self ne_et_tap_addTarget:target action:action];
        return;
    }
    
    SEL handlerAction = @selector(view_action_gestureRecognizerEvent:);
    
    // 1. pre
    [self _ne_et_initPreAndAfterGesHanderIfNeeded];
    if (self.ne_et_validTargetActions.count == 0) {   // 第一个 target+action 被添加的时候，才添加 pre
        [self ne_et_tap_addTarget:self.ne_et_preGesHandler action:handlerAction];
    }
    [self ne_et_tap_removeTarget:self.ne_et_afterGesHandler action:handlerAction];  // 保障 after 是最后一个，所以先行尝试删除一次
    
    // 2. original
    [self ne_et_tap_addTarget:target action:action];
    NSMutableSet *actions = [self.ne_et_validTargetActions objectForKey:target] ?: [NSMutableSet set];
    [actions addObject:NSStringFromSelector(action)];
    [self.ne_et_validTargetActions setObject:actions forKey:target];
    
    // 3. after
    [self ne_et_tap_addTarget:self.ne_et_afterGesHandler action:handlerAction];
}

- (void)ne_et_tap_removeTarget:(id)target action:(SEL)action {
    [self ne_et_tap_removeTarget:target action:action];
    
    NSMutableSet *actions = [self.ne_et_validTargetActions objectForKey:target];
    [actions removeObject:NSStringFromSelector(action)];
    if (actions.count == 0) {
        [self.ne_et_validTargetActions removeObjectForKey:target];
    }
    
    if (self.ne_et_validTargetActions.count > 0) {    // 删除当前 target+action 之后，还有其他的，则不需做任何处理，否则清理掉 pre+after
        return;
    }
    
    SEL handlerAction = @selector(view_action_gestureRecognizerEvent:);
    [self ne_et_tap_removeTarget:self.ne_et_preGesHandler action:handlerAction];
    [self ne_et_tap_removeTarget:self.ne_et_afterGesHandler action:handlerAction];
}

- (BOOL)_ne_et_needsAOP {
    return self.numberOfTapsRequired == 1 && self.numberOfTouchesRequired == 1;
}

- (void)_ne_et_initPreAndAfterGesHanderIfNeeded {
    if (!self.ne_et_preGesHandler) {
        UIViewEventTracingAOPTapGesHandler *preGesHandler = [[UIViewEventTracingAOPTapGesHandler alloc] init];
        preGesHandler.isPre = YES;
        self.ne_et_preGesHandler = preGesHandler;
    }
    if (!self.ne_et_afterGesHandler) {
        self.ne_et_afterGesHandler = [[UIViewEventTracingAOPTapGesHandler alloc] init];
    }
}

/// MARK: getters & setters
- (UIViewEventTracingAOPTapGesHandler *)ne_et_preGesHandler {
    return objc_getAssociatedObject(self, _cmd);
}
- (void)ne_et_setPreGesHandler:(UIViewEventTracingAOPTapGesHandler *)ne_et_preGesHandler {
    objc_setAssociatedObject(self, @selector(ne_et_preGesHandler), ne_et_preGesHandler, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (UIViewEventTracingAOPTapGesHandler *)ne_et_afterGesHandler {
    return objc_getAssociatedObject(self, _cmd);
}
- (void)ne_et_setAfterGesHandler:(UIViewEventTracingAOPTapGesHandler *)ne_et_afterGesHandler {
    objc_setAssociatedObject(self, @selector(ne_et_afterGesHandler), ne_et_afterGesHandler, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSMapTable<id,NSMutableSet<NSString *> *> *)ne_et_validTargetActions {
    NSMapTable<id,NSMutableSet<NSString *> *> *validTargetActions = objc_getAssociatedObject(self, _cmd);
    if (!validTargetActions) {
        validTargetActions = [NSMapTable weakToStrongObjectsMapTable];
        objc_setAssociatedObject(self, _cmd, validTargetActions, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return validTargetActions;
}

@end

@implementation UIViewEventTracingAOPTapGesHandler
- (void)view_action_gestureRecognizerEvent:(UITapGestureRecognizer *)gestureRecognizer {
    if (![gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]]
        || gestureRecognizer.ne_et_validTargetActions.count == 0) {
        return;
    }
    
    UIView *view = gestureRecognizer.view;
    
    /// MARK: 是否命中黑名单
    if ([self _shouldFilterdTapGesureForView:view]) {
        return;
    }
    
    void(^eventActionBlock)(NEEventTracingEventActionConfig * _Nullable) = ^(NEEventTracingEventActionConfig * _Nullable config) {
        config.useForRefer = YES;
    };
    
    // for: pre
    if (self.isPre) {
        // observers => pre
        [[[NEEventTracingClickMonitor sharedInstance] observersForView:view] enumerateObjectsUsingBlock:^(id<NEEventTracingClickObserver>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj respondsToSelector:@selector(clickMonitor:willTapView:)]) {
                [(id<NEEventTracingClickViewSingleTapObserver>)obj clickMonitor:[NEEventTracingClickMonitor sharedInstance] willTapView:view];
            }
        }];
        
        [[NEEventTracingEngine sharedInstance] AOP_preLogWithEvent:NE_ET_EVENT_ID_E_CLCK view:view eventAction:eventActionBlock];
        return;
    }
    
    // for: after
    [[NEEventTracingEngine sharedInstance] AOP_logWithEvent:NE_ET_EVENT_ID_E_CLCK view:view params:nil eventAction:eventActionBlock];
    
    // observers => after
    [[[NEEventTracingClickMonitor sharedInstance] observersForView:view] enumerateObjectsUsingBlock:^(id<NEEventTracingClickObserver>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj respondsToSelector:@selector(clickMonitor:didTapView:)]) {
            [(id<NEEventTracingClickViewSingleTapObserver>)obj clickMonitor:[NEEventTracingClickMonitor sharedInstance] didTapView:view];
        }
    }];
}

- (BOOL)_shouldFilterdTapGesureForView:(UIView *)view {
    /// MARK: WKWebView中，系统默认给添加了一个 TapGesture 到 WKContentView 上
    return ET_STR_MATCHES(NSStringFromClass(view.class), ET_CONFUSED(W,K), ET_CONFUSED(C,o,n,t,e,n,t), @"View");
}
@end

@implementation UIView (EventTracingAOP)

- (void)ne_et_view_didMoveToSuperview {
    [self ne_et_view_didMoveToSuperview];
    
    [[NEEventTracingEngine sharedInstance] traverse:self];
}

- (void)ne_et_view_didMoveToWindow {
    [self ne_et_view_didMoveToWindow];
    
    // view即将被从屏幕中移除，需要再次同步下dynamic params
    if (self.window == nil) {
        [self ne_et_tryRefreshDynamicParamsCascadeSubViews];
    }
    
    if (NE_ET_isPageOrElement(self) && self.window == nil) {
        [[NEEventTracingEngine sharedInstance] traverse];
        return;
    }
    
    [[NEEventTracingEngine sharedInstance] traverse:self];
}

- (void)ne_et_view_bringSubviewToFront:(UIView *)view {
    [self ne_et_view_bringSubviewToFront:view];
    
    if (view) {
        [[NEEventTracingEngine sharedInstance] traverse:view];
    }
}

- (void)ne_et_view_sendSubviewToBack:(UIView *)view {
    [self ne_et_view_sendSubviewToBack:view];
    
    if (view) {
        [[NEEventTracingEngine sharedInstance] traverse:view];
    }
}

- (void)ne_et_view_insertSubview:(UIView *)view aboveSubview:(UIView *)siblingSubview {
    [self ne_et_view_insertSubview:view aboveSubview:siblingSubview];
    
    if (view) {
        [[NEEventTracingEngine sharedInstance] traverse:view];
    }
}

- (void)ne_et_view_insertSubview:(UIView *)view belowSubview:(UIView *)siblingSubview {
    [self ne_et_view_insertSubview:view belowSubview:siblingSubview];
    
    if (view) {
        [[NEEventTracingEngine sharedInstance] traverse:view];
    }
}

/// MARK: -[UIView setHidden:] => -[CALayer setHidden:]
/// MARK: 减小 hook 范围, 仅 hook 到 `-[UIView setHidden:]` 层面
- (void)ne_et_view_setHidden:(BOOL)hidden {
    BOOL preHidden = self.hidden;

    //可见性有变化，可能有新元素曝光
    if (preHidden != hidden) {
        [[NEEventTracingEngine sharedInstance] traverse:self traverseAction:^(NEEventTracingTraverseAction * _Nonnull action) {
            if (hidden) {
                action.ignoreViewInvisible = YES;
            }
        }];
    }
    [self ne_et_view_setHidden:hidden];
}

/// MARK: -[UIView setAlpha:] => -[CALayer setOpacity:]
/// MARK: 减小 hook 范围, 仅 hook 到 `-[UIView setAlpha:]` 层面
- (void)ne_et_view_setAlpha:(CGFloat)alpha {
    CGFloat preAlpha = self.alpha;

    //透明度有变化，可能有新元素曝光
    CGFloat invisibleAlpha = 0.001f;
    if (((alpha > invisibleAlpha)?1:0) != ((preAlpha > invisibleAlpha)?1:0)) {
        [[NEEventTracingEngine sharedInstance] traverse:self traverseAction:^(NEEventTracingTraverseAction * _Nonnull action) {
            if (alpha < invisibleAlpha) {
                action.ignoreViewInvisible = YES;
            }
        }];
    }
    [self ne_et_view_setAlpha:alpha];
}

/// MARK: -[UIView setFrame:] => -[CALayer setFrame:] => -[CALayer setPosition:]
/// MARK: 仅 hook 到 `-[UIView setFrame:]` 层面即可，不适合 hook 太底层的UI变动，太频繁了
- (void) ne_et_view_setFrame:(CGRect)frame {
    CGRect preFrame = self.frame;

    if (!CGRectEqualToRect(preFrame, frame)) {
        [[NEEventTracingEngine sharedInstance] traverse:self];
    }

    [self ne_et_view_setFrame:frame];
}

@end

@implementation CALayer (EventTracingAOP)

/// MARK: -[UIView setTransform:] => -[CALayer setAffineTransform:] => -[CALayer setTransform:]
- (void)ne_et_layer_setTransform:(CATransform3D)transform {
    CATransform3D preTransform = self.transform;
    [self ne_et_layer_setTransform:transform];
    
    if (CATransform3DEqualToTransform(transform, preTransform)) {
        return;
    }
    
    [self _ne_et_doTraverseIfNeeded];
}

- (void)_ne_et_doTraverseIfNeeded {
    if (![self.delegate isKindOfClass:UIView.class]) {
        return;
    }
    
    UIView *view = (UIView *)self.delegate;
    [[NEEventTracingEngine sharedInstance] traverse:view];
}

@end

@implementation NEEventTracingUIViewAOP

NEEventTracingAOPInstanceImp

- (void)inject {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [UITapGestureRecognizer jr_swizzleMethod:@selector(initWithTarget:action:) withMethod:@selector(ne_et_tap_initWithTarget:action:) error:nil];
        [UITapGestureRecognizer jr_swizzleMethod:@selector(addTarget:action:) withMethod:@selector(ne_et_tap_addTarget:action:) error:nil];
        [UITapGestureRecognizer jr_swizzleMethod:@selector(removeTarget:action:) withMethod:@selector(ne_et_tap_removeTarget:action:) error:nil];
    });
}

- (void)asyncInject {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [UIView jr_swizzleMethod:@selector(didMoveToSuperview) withMethod:@selector(ne_et_view_didMoveToSuperview) error:nil];
        [UIView jr_swizzleMethod:@selector(didMoveToWindow) withMethod:@selector(ne_et_view_didMoveToWindow) error:nil];
        [UIView jr_swizzleMethod:@selector(bringSubviewToFront:) withMethod:@selector(ne_et_view_bringSubviewToFront:) error:nil];
        [UIView jr_swizzleMethod:@selector(sendSubviewToBack:) withMethod:@selector(ne_et_view_sendSubviewToBack:) error:nil];
        [UIView jr_swizzleMethod:@selector(insertSubview:aboveSubview:) withMethod:@selector(ne_et_view_insertSubview:aboveSubview:) error:nil];
        [UIView jr_swizzleMethod:@selector(insertSubview:belowSubview:) withMethod:@selector(ne_et_view_insertSubview:belowSubview:) error:nil];
        [UIView jr_swizzleMethod:@selector(setHidden:) withMethod:@selector(ne_et_view_setHidden:) error:nil];
        [UIView jr_swizzleMethod:@selector(setAlpha:) withMethod:@selector(ne_et_view_setAlpha:) error:nil];
        [UIView jr_swizzleMethod:@selector(setFrame:) withMethod:@selector(ne_et_view_setFrame:) error:nil];
        
        [CALayer jr_swizzleMethod:@selector(setTransform:) withMethod:@selector(ne_et_layer_setTransform:) error:nil];
    });
}

@end
