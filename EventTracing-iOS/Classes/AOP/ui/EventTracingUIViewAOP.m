//
//  EventTracingUIViewAOP.m
//  BlocksKit
//
//  Created by dl on 2021/2/24.
//

#import "EventTracingUIViewAOP.h"
#import "EventTracingDefines.h"
#import "EventTracingEngine+Private.h"
#import "UIView+EventTracingPrivate.h"
#import "EventTracingClickMonitor.h"

#import <BlocksKit/BlocksKit.h>
#import <JRSwizzle/JRSwizzle.h>
#import <objc/runtime.h>

@interface UIViewEventTracingAOPTapGesHandler : NSObject
@property(nonatomic, assign) BOOL isPre;
- (void)view_action_gestureRecognizerEvent:(UITapGestureRecognizer *)gestureRecognizer;
@end

@interface UITapGestureRecognizer (EventTracingAOP)
@property(nonatomic, strong, setter=et_setPreGesHandler:) UIViewEventTracingAOPTapGesHandler *et_preGesHandler;
@property(nonatomic, strong, setter=et_setAfterGesHandler:) UIViewEventTracingAOPTapGesHandler *et_afterGesHandler;
@property(nonatomic, strong, readonly) NSMapTable<id, NSMutableSet<NSString *> *> *et_validTargetActions;
@end

@implementation UITapGestureRecognizer (EventTracingAOP)

- (instancetype)et_tap_initWithTarget:(id)target action:(SEL)action {
    if ([self _et_needsAOP]) {
        [self _et_initPreAndAfterGesHanderIfNeeded];
    }
    
    if (target && action) {
        UITapGestureRecognizer *ges = [self init];
        [self addTarget:target action:action];
        return ges;
    }

    return [self et_tap_initWithTarget:target action:action];
}

- (void)et_tap_addTarget:(id)target action:(SEL)action {
    if (!target || !action
        || ![self _et_needsAOP]
        || [[self.et_validTargetActions objectForKey:target] containsObject:NSStringFromSelector(action)]) {
        [self et_tap_addTarget:target action:action];
        return;
    }
    
    SEL handlerAction = @selector(view_action_gestureRecognizerEvent:);
    
    // 1. pre
    [self _et_initPreAndAfterGesHanderIfNeeded];
    if (self.et_validTargetActions.count == 0) {   // 第一个 target+action 被添加的时候，才添加 pre
        [self et_tap_addTarget:self.et_preGesHandler action:handlerAction];
    }
    [self et_tap_removeTarget:self.et_afterGesHandler action:handlerAction];  // 保障 after 是最后一个，所以先行尝试删除一次
    
    // 2. original
    [self et_tap_addTarget:target action:action];
    NSMutableSet *actions = [self.et_validTargetActions objectForKey:target] ?: [NSMutableSet set];
    [actions addObject:NSStringFromSelector(action)];
    [self.et_validTargetActions setObject:actions forKey:target];
    
    // 3. after
    [self et_tap_addTarget:self.et_afterGesHandler action:handlerAction];
}

- (void)et_tap_removeTarget:(id)target action:(SEL)action {
    [self et_tap_removeTarget:target action:action];
    
    NSMutableSet *actions = [self.et_validTargetActions objectForKey:target];
    [actions removeObject:NSStringFromSelector(action)];
    if (actions.count == 0) {
        [self.et_validTargetActions removeObjectForKey:target];
    }
    
    if (self.et_validTargetActions.count > 0) {    // 删除当前 target+action 之后，还有其他的，则不需做任何处理，否则清理掉 pre+after
        return;
    }
    
    SEL handlerAction = @selector(view_action_gestureRecognizerEvent:);
    [self et_tap_removeTarget:self.et_preGesHandler action:handlerAction];
    [self et_tap_removeTarget:self.et_afterGesHandler action:handlerAction];
}

- (BOOL)_et_needsAOP {
    return self.numberOfTapsRequired == 1 && self.numberOfTouchesRequired == 1;
}

- (void)_et_initPreAndAfterGesHanderIfNeeded {
    if (!self.et_preGesHandler) {
        UIViewEventTracingAOPTapGesHandler *preGesHandler = [[UIViewEventTracingAOPTapGesHandler alloc] init];
        preGesHandler.isPre = YES;
        self.et_preGesHandler = preGesHandler;
    }
    if (!self.et_afterGesHandler) {
        self.et_afterGesHandler = [[UIViewEventTracingAOPTapGesHandler alloc] init];
    }
}

/// MARK: getters & setters
- (UIViewEventTracingAOPTapGesHandler *)et_preGesHandler {
    return objc_getAssociatedObject(self, _cmd);
}
- (void)et_setPreGesHandler:(UIViewEventTracingAOPTapGesHandler *)et_preGesHandler {
    objc_setAssociatedObject(self, @selector(et_preGesHandler), et_preGesHandler, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (UIViewEventTracingAOPTapGesHandler *)et_afterGesHandler {
    return objc_getAssociatedObject(self, _cmd);
}
- (void)et_setAfterGesHandler:(UIViewEventTracingAOPTapGesHandler *)et_afterGesHandler {
    objc_setAssociatedObject(self, @selector(et_afterGesHandler), et_afterGesHandler, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSMapTable<id,NSMutableSet<NSString *> *> *)et_validTargetActions {
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
        || gestureRecognizer.et_validTargetActions.count == 0) {
        return;
    }
    
    UIView *view = gestureRecognizer.view;
    
    /// MARK: 是否命中黑名单
    if ([self _shouldFilterdTapGesureForView:view]) {
        return;
    }
    
    void(^eventActionBlock)(EventTracingEventActionConfig * _Nullable) = ^(EventTracingEventActionConfig * _Nullable config) {
        config.useForRefer = YES;
    };
    
    // for: pre
    if (self.isPre) {
        // observers => pre
        [[[EventTracingClickMonitor sharedInstance] observersForView:view] enumerateObjectsUsingBlock:^(id<EventTracingClickObserver>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj respondsToSelector:@selector(clickMonitor:willTapView:)]) {
                [(id<EventTracingClickViewSingleTapObserver>)obj clickMonitor:[EventTracingClickMonitor sharedInstance] willTapView:view];
            }
        }];
        
        [[EventTracingEngine sharedInstance] AOP_preLogWithEvent:ET_EVENT_ID_E_CLCK view:view eventAction:eventActionBlock];
        return;
    }
    
    // for: after
    [[EventTracingEngine sharedInstance] AOP_logWithEvent:ET_EVENT_ID_E_CLCK view:view params:nil eventAction:eventActionBlock];
    
    // observers => after
    [[[EventTracingClickMonitor sharedInstance] observersForView:view] enumerateObjectsUsingBlock:^(id<EventTracingClickObserver>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj respondsToSelector:@selector(clickMonitor:didTapView:)]) {
            [(id<EventTracingClickViewSingleTapObserver>)obj clickMonitor:[EventTracingClickMonitor sharedInstance] didTapView:view];
        }
    }];
}

- (BOOL)_shouldFilterdTapGesureForView:(UIView *)view {
    NSMutableArray<NSString *> *blacklistClassName = @[].mutableCopy;
    /// MARK: WKWebView中，系统默认给添加了一个 TapGesture 到 WKContentView 上
    [blacklistClassName addObject:[NSString stringWithFormat:@"%@%@%@", @"WK", @"Content", @"View"]];
    return [blacklistClassName bk_any:^BOOL(NSString *className) {
        return [NSStringFromClass(view.class) isEqualToString:className];
    }];
}
@end

@implementation UIView (EventTracingAOP)

- (void)et_view_didMoveToSuperview {
    [self et_view_didMoveToSuperview];
    
    [[EventTracingEngine sharedInstance] traverse:self];
}

- (void)et_view_didMoveToWindow {
    [self et_view_didMoveToWindow];
    
    // view即将被从屏幕中移除，需要再次同步下dynamic params
    if (self.window == nil) {
        [self et_tryRefreshDynamicParamsCascadeSubViews];
    }
    
    if (ET_isPageOrElement(self) && self.window == nil) {
        [[EventTracingEngine sharedInstance] traverse];
        return;
    }
    
    [[EventTracingEngine sharedInstance] traverse:self];
}

- (void)et_view_bringSubviewToFront:(UIView *)view {
    [self et_view_bringSubviewToFront:view];
    
    if (view) {
        [[EventTracingEngine sharedInstance] traverse:view];
    }
}

- (void)et_view_sendSubviewToBack:(UIView *)view {
    [self et_view_sendSubviewToBack:view];
    
    if (view) {
        [[EventTracingEngine sharedInstance] traverse:view];
    }
}

- (void)et_view_insertSubview:(UIView *)view aboveSubview:(UIView *)siblingSubview {
    [self et_view_insertSubview:view aboveSubview:siblingSubview];
    
    if (view) {
        [[EventTracingEngine sharedInstance] traverse:view];
    }
}

- (void)et_view_insertSubview:(UIView *)view belowSubview:(UIView *)siblingSubview {
    [self et_view_insertSubview:view belowSubview:siblingSubview];
    
    if (view) {
        [[EventTracingEngine sharedInstance] traverse:view];
    }
}

/// MARK: -[UIView setHidden:] => -[CALayer setHidden:]
/// MARK: 减小 hook 范围, 仅 hook 到 `-[UIView setHidden:]` 层面
- (void)et_view_setHidden:(BOOL)hidden {
    BOOL preHidden = self.hidden;

    //可见性有变化，可能有新元素曝光
    if (preHidden != hidden) {
        [[EventTracingEngine sharedInstance] traverse:self traverseAction:^(EventTracingTraverseAction * _Nonnull action) {
            if (hidden) {
                action.ignoreViewInvisible = YES;
            }
        }];
    }
    [self et_view_setHidden:hidden];
}

/// MARK: -[UIView setAlpha:] => -[CALayer setOpacity:]
/// MARK: 减小 hook 范围, 仅 hook 到 `-[UIView setAlpha:]` 层面
- (void)et_view_setAlpha:(CGFloat)alpha {
    CGFloat preAlpha = self.alpha;

    //透明度有变化，可能有新元素曝光
    CGFloat invisibleAlpha = 0.001f;
    if (((alpha > invisibleAlpha)?1:0) != ((preAlpha > invisibleAlpha)?1:0)) {
        [[EventTracingEngine sharedInstance] traverse:self traverseAction:^(EventTracingTraverseAction * _Nonnull action) {
            if (alpha < invisibleAlpha) {
                action.ignoreViewInvisible = YES;
            }
        }];
    }
    [self et_view_setAlpha:alpha];
}

/// MARK: -[UIView setFrame:] => -[CALayer setFrame:] => -[CALayer setPosition:]
/// MARK: 仅 hook 到 `-[UIView setFrame:]` 层面即可，不适合 hook 太底层的UI变动，太频繁了
- (void)et_view_setFrame:(CGRect)frame {
    CGRect preFrame = self.frame;

    if (!CGRectEqualToRect(preFrame, frame)) {
        [[EventTracingEngine sharedInstance] traverse:self];
    }

    [self et_view_setFrame:frame];
}

@end

@implementation CALayer (EventTracingAOP)

/// MARK: -[UIView setAlpha:] => -[CALayer setOpacity:]
- (void)et_layer_setOpacity:(float)opacity {
    CGFloat preOpacity = self.opacity;
    
    [self et_layer_setOpacity:opacity];
    
    //透明度有变化，可能有新元素曝光
    CGFloat invisibleOpacity = 0.001f;
    if (![self.delegate isKindOfClass:UIView.class]
        || ((opacity > invisibleOpacity) ? 1 : 0) == ((preOpacity > invisibleOpacity) ? 1 : 0)) {
        return;
    }
    
    UIView *view = (UIView *)self.delegate;
    [[EventTracingEngine sharedInstance] traverse:view traverseAction:^(EventTracingTraverseAction * _Nonnull action) {
        if (preOpacity < invisibleOpacity) {
            action.ignoreViewInvisible = YES;
        }
    }];
}

/// MARK: -[UIView setHidden:] => -[CALayer setHidden:]
- (void)et_layer_setHidden:(BOOL)hidden {
    BOOL preHidden = self.hidden;
    [self et_layer_setHidden:hidden];
    
    //可见性有变化，可能有新元素曝光
    if (preHidden == hidden || ![self.delegate isKindOfClass:UIView.class]) {
        return;
    }
    
    UIView *view = (UIView *)self.delegate;
    [[EventTracingEngine sharedInstance] traverse:view traverseAction:^(EventTracingTraverseAction * _Nonnull action) {
        if (hidden) {
            action.ignoreViewInvisible = YES;
        }
    }];
}

/// MARK: -[UIView setAnchorPoint:] => -[CALayer setAnchorPoint:]
- (void)et_layer_setAnchorPoint:(CGPoint)anchorPoint {
    CGPoint preAnchorPoint = self.anchorPoint;
    [self et_layer_setAnchorPoint:anchorPoint];
    
    if (CGPointEqualToPoint(anchorPoint, preAnchorPoint)) {
        return;
    }
    
    [self _et_doTraverseIfNeeded];
}

/// MARK: -[UIView setTransform:] => -[CALayer setAffineTransform:] => -[CALayer setTransform:]
- (void)et_layer_setTransform:(CATransform3D)transform {
    CATransform3D preTransform = self.transform;
    [self et_layer_setTransform:transform];
    
    if (CATransform3DEqualToTransform(transform, preTransform)) {
        return;
    }
    
    [self _et_doTraverseIfNeeded];
}

- (void)_et_doTraverseIfNeeded {
    if (![self.delegate isKindOfClass:UIView.class]) {
        return;
    }
    
    UIView *view = (UIView *)self.delegate;
    [[EventTracingEngine sharedInstance] traverse:view];
}

@end

@implementation EventTracingUIViewAOP

EventTracingAOPInstanceImp

- (void)inject {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [UITapGestureRecognizer jr_swizzleMethod:@selector(initWithTarget:action:) withMethod:@selector(et_tap_initWithTarget:action:) error:nil];
        [UITapGestureRecognizer jr_swizzleMethod:@selector(addTarget:action:) withMethod:@selector(et_tap_addTarget:action:) error:nil];
        [UITapGestureRecognizer jr_swizzleMethod:@selector(removeTarget:action:) withMethod:@selector(et_tap_removeTarget:action:) error:nil];
    });
}

- (void)asyncInject {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [UIView jr_swizzleMethod:@selector(didMoveToSuperview) withMethod:@selector(et_view_didMoveToSuperview) error:nil];
        [UIView jr_swizzleMethod:@selector(didMoveToWindow) withMethod:@selector(et_view_didMoveToWindow) error:nil];
        [UIView jr_swizzleMethod:@selector(bringSubviewToFront:) withMethod:@selector(et_view_bringSubviewToFront:) error:nil];
        [UIView jr_swizzleMethod:@selector(sendSubviewToBack:) withMethod:@selector(et_view_sendSubviewToBack:) error:nil];
        [UIView jr_swizzleMethod:@selector(insertSubview:aboveSubview:) withMethod:@selector(et_view_insertSubview:aboveSubview:) error:nil];
        [UIView jr_swizzleMethod:@selector(insertSubview:belowSubview:) withMethod:@selector(et_view_insertSubview:belowSubview:) error:nil];
        [UIView jr_swizzleMethod:@selector(setHidden:) withMethod:@selector(et_view_setHidden:) error:nil];
        [UIView jr_swizzleMethod:@selector(setAlpha:) withMethod:@selector(et_view_setAlpha:) error:nil];
        [UIView jr_swizzleMethod:@selector(setFrame:) withMethod:@selector(et_view_setFrame:) error:nil];
        
        [CALayer jr_swizzleMethod:@selector(setTransform:) withMethod:@selector(et_layer_setTransform:) error:nil];
    });
}

@end
