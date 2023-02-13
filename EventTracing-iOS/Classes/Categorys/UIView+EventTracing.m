//
//  UIView+EventTracing.m
//  BlocksKit
//
//  Created by dl on 2021/2/4.
//

#import "UIView+EventTracing.h"
#import "EventTracingReferFuncs.h"
#import "EventTracingEventReferQueue.h"
#import "EventTracingContext+Private.h"
#import "EventTracingVTreeNode+Private.h"
#import "EventTracingEngine+Private.h"
#import "UIView+EventTracingPipEvent.h"
#import "UIView+EventTracingPrivate.h"

#import "NSArray+ETEnumerator.h"
#import <BlocksKit/BlocksKit.h>
#import <objc/runtime.h>

#define kETUnvisibleAlpha 0.0001
#define kETUnvisibleWH 0.0001

@implementation EventTracingEventActionConfig
+ (instancetype)configWithEvent:(NSString *)event {
    EventTracingEventActionConfig *config = [[EventTracingEventActionConfig alloc] init];
    if ([[EventTracingEngine sharedInstance].ctx.needIncreaseActseqLogEvents containsObject:event]) {
        config.increaseActseq = YES;
        config.useForRefer = YES;
    }
    return config;
}
@end

@implementation UIViewController (EventTracingParams_Page)

- (void)et_setPageId:(NSString *)pageId params:(NSDictionary<NSString *,NSString *> *)params {
    [self.p_et_view et_setPageId:pageId params:params];
}
- (void)et_addParams:(NSDictionary<NSString *,NSString *> *)params {
    [self.p_et_view et_addParams:params];
}
- (void)et_setParamValue:(NSString *)value forKey:(NSString *)key {
    [self.p_et_view et_setParamValue:value forKey:key];
}
- (void)et_removeParamForKey:(NSString *)key {
    [self.p_et_view et_removeParamForKey:key];
}
- (void)et_removeAllParams {
    [self.p_et_view et_removeAllParams];
}

- (void)et_addParamsCallback:(ET_AddParamsCallback NS_NOESCAPE)callback {
    [self.p_et_view et_addParamsCallback:callback];
}
- (void)et_addParamsCallback:(ET_AddParamsCallback NS_NOESCAPE)callback forEvent:(NSString *)event {
    [self.p_et_view et_addParamsCallback:callback forEvent:event];
}
- (void)et_addParamsCallback:(ET_AddParamsCallback NS_NOESCAPE)callback forEvents:(NSArray<NSString *> *)events {
    [self.p_et_view et_addParamsCallback:callback forEvents:events];
}
- (void)et_addParamsCarryEventCallback:(ET_AddParamsCarryEventCallback NS_NOESCAPE)callback forEvents:(NSArray<NSString *> *)events {
    [self.p_et_view et_addParamsCarryEventCallback:callback forEvents:events];
}

- (NSUInteger)et_position {
    return self.p_et_view.et_position;
}
- (void)et_setPosition:(NSUInteger)et_position {
    [self.p_et_view et_setPosition:et_position];
}
- (void)et_clear {
    [self.p_et_view et_clear];
}
- (NSDictionary *)et_params {
    return [self.p_et_view et_params];
}

- (ETNodeBuildinEventLogDisableStrategy)et_buildinEventLogDisableStrategy {
    return [self.p_et_view et_buildinEventLogDisableStrategy];
}
- (void)et_setBuildinEventLogDisableStrategy:(ETNodeBuildinEventLogDisableStrategy)et_buildinEventLogDisableStrategy {
    [self.p_et_view et_setBuildinEventLogDisableStrategy:et_buildinEventLogDisableStrategy];
}

- (BOOL)et_isRootPage {
    return [self.p_et_view et_isRootPage];
}
- (void)et_setRootPage:(BOOL)et_rootPage {
    [self.p_et_view et_setRootPage:et_rootPage];
}

- (BOOL)et_pageOcclusionEnable {
    return self.p_et_view.et_pageOcclusionEnable;
}
- (void)et_setPageOcclusitionEnable:(BOOL)et_pageOcclusionEnable {
    [self.p_et_view et_setPageOcclusitionEnable:et_pageOcclusionEnable];
}

- (BOOL)et_isIgnoreReferCascade {
    return self.p_et_view.et_ignoreReferCascade;
}
- (void)et_setIgnoreReferCascade:(BOOL)et_ignoreReferCascade {
    self.p_et_view.et_ignoreReferCascade = et_ignoreReferCascade;
}

- (BOOL)et_psreferMute {
    return self.p_et_view.et_psreferMute;
}
- (void)et_setPsreferMute:(BOOL)et_psreferMute {
    self.p_et_view.et_psreferMute = et_psreferMute;
}

#pragma mark - setters & getters
- (NSString *)et_pageId {
    return self.p_et_view.et_pageId;
}

- (BOOL)et_isPage {
    return self.p_et_view.et_isPage;
}

- (EventTracingVTreeNode *)et_currentVTreeNode {
    return self.p_et_view.et_currentVTreeNode;
}

- (UIView *)p_et_view {
    /// MARK: alert不做卡点
    if ([self isKindOfClass:[UIAlertController class]]) {
        return self.view;
    }
    
    NSString *vcClassName = NSStringFromClass(self.class);
    NSString *message = [NSString stringWithFormat:@"[%@]\n view not loaded when call `self.view` in NEEvnetTracing", vcClassName];
    
    if ([EventTracingEngine sharedInstance].ctx.viewControllerDidNotLoadViewExceptionTip == ETViewControllerDidNotLoadViewExceptionTipAssert) {
        NSAssert(self.isViewLoaded, message);
    } else if (!self.isViewLoaded && [EventTracingEngine sharedInstance].ctx.viewControllerDidNotLoadViewExceptionTip == ETViewControllerDidNotLoadViewExceptionTipCostom) {
        if ([[EventTracingEngine sharedInstance].ctx.exceptionInterface respondsToSelector:@selector(viewControllerDidNotLoadView:message:)]) {
            [[EventTracingEngine sharedInstance].ctx.exceptionInterface viewControllerDidNotLoadView:self message:message];
        }
    }
    
    return self.view;
}

- (BOOL)et_isTransitioning {
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)et_setTransitioning:(BOOL)et_transitioning {
    objc_setAssociatedObject(self, @selector(et_isTransitioning), @(et_transitioning), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end


@implementation UIView (EventTracingParams_Page_Element)
- (void)et_setPageId:(NSString *)pageId params:(NSDictionary<NSString *,NSString *> *)params {
    [self _et_setIdStr:pageId isPage:YES params:params];
}
- (void)et_setElementId:(NSString *)elementId params:(NSDictionary<NSString *,NSString *> *)params {
    [self _et_setIdStr:elementId isPage:NO params:params];
}

- (void)et_addParams:(NSDictionary<NSString *,NSString *> *)params {
    if (![params isKindOfClass:NSDictionary.class] || params.count == 0) {
        return;
    }
    
    [self.et_props.params addEntriesFromDictionary:params];
    [self _et_doSyncStaticParamsToNodeIfNeeded];
    [self _et_checkUserParamsKeyValidIfNeeded:params.allKeys];
}
- (void)et_setParamValue:(NSString *)value forKey:(NSString *)key {
    if (!key.length) {
        return;
    }
    
    [self.et_props.params setObject:value forKey:key];
    [self _et_doSyncStaticParamsToNodeIfNeeded];
    [self _et_checkUserParamsKeyValidIfNeeded:@[key]];
}
- (void)et_removeParamForKey:(NSString *)key {
    [self.et_props.params removeObjectForKey:key];
    [self _et_doSyncStaticParamsToNodeIfNeeded];
    [self.et_props.checkedGuardParamKeys removeObject:key];
}
- (void)et_removeAllParams {
    [self.et_props.params removeAllObjects];
    [self _et_doSyncStaticParamsToNodeIfNeeded];
    [self.et_props.checkedGuardParamKeys removeAllObjects];
}

- (void)et_addParamsCallback:(ET_AddParamsCallback NS_NOESCAPE)callback {
    [self.et_props addParamsCallback:callback forEvent:kETAddParamCallbackObjectkey];
}
- (void)et_addParamsCallback:(ET_AddParamsCallback NS_NOESCAPE)callback forEvent:(NSString *)event {
    [self.et_props addParamsCallback:callback forEvent:event];
}
- (void)et_addParamsCallback:(ET_AddParamsCallback NS_NOESCAPE)callback forEvents:(NSArray<NSString *> *)events {
    [events enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self.et_props addParamsCallback:callback forEvent:obj];
    }];
}
- (void)et_addParamsCarryEventCallback:(ET_AddParamsCarryEventCallback NS_NOESCAPE)callback forEvents:(NSArray<NSString *> *)events {
    [self.et_props addParamsCarryEventCallback:callback forEvents:events];
}

- (NSUInteger)et_position {
    return [self.et_props position];
}

- (void)et_setPosition:(NSUInteger)et_position {
    self.et_props.position = et_position;
    
    EventTracingVTreeNode *VTreeNode = self.et_currentVTreeNode;
    // cell复用场景
    if ([self.et_reuseIdentifier isEqualToString:VTreeNode.identifier]) {
        [VTreeNode updatePosition:et_position];
    }
}

- (void)et_clear {
    BOOL needsTraversel = self.et_isPage || self.et_isElement;
    
    self.et_props = nil;
    self.et_logicalParentView = nil;
    self.et_ignoreReferCascade = NO;

    if (needsTraversel) {
        [[EventTracingEngine sharedInstance] traverse];
    }
}

- (void)_et_setIdStr:(NSString *)idStr isPage:(BOOL)isPage params:(NSDictionary<NSString *,NSString *> *)params {
    if (![idStr isKindOfClass:NSString.class] || !idStr.length) {
        return;
    }
    
    self.et_props = [EventTracingAssociatedPros associatedProsWithView:self];
    [self.et_props setupOid:idStr isPage:isPage params:params];

    [self et_cancelPipEvent];
    [[EventTracingEngine sharedInstance] traverse];
}

- (void)_et_doSyncStaticParamsToNodeIfNeeded {
    EventTracingVTreeNode *VTreeNode = self.et_currentVTreeNode;
    // cell复用场景
    if ([self.et_reuseIdentifier isEqualToString:VTreeNode.identifier]) {
        [VTreeNode updateStaticParams:self.et_params];
    }
}

- (void)_et_checkUserParamsKeyValidIfNeeded:(NSArray<NSString *> *)keys {
    NSArray<NSString *> *filteredKeys = [keys bk_reject:^BOOL(NSString *obj) {
        return [self.et_props.checkedGuardParamKeys containsObject:obj];
    }];
    [[EventTracingEngine sharedInstance].ctx.paramGuardExector asyncDoDispatchCheckTask:^{
        [filteredKeys enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            ET_CheckUserParamKeyValid(obj);
        }];
    }];
    [self.et_props.checkedGuardParamKeys addObjectsFromArray:filteredKeys];
}

#pragma mark - setters & getters
- (NSString *)et_pageId {
    return self.et_props.pageId;
}
- (NSString *)et_elementId {
    return self.et_props.elementId;
}

- (BOOL)et_isPage {
    return self.et_props.isPage;
}

- (BOOL)et_isElement {
    return self.et_props.isElement;
}

- (NSDictionary *)et_params {
    return self.et_props.params;
}

- (ETNodeBuildinEventLogDisableStrategy)et_buildinEventLogDisableStrategy {
    return self.et_props.buildinEventLogDisableStrategy;
}
- (void)et_setBuildinEventLogDisableStrategy:(ETNodeBuildinEventLogDisableStrategy)et_buildinEventLogDisableStrategy {
    self.et_props.buildinEventLogDisableStrategy = et_buildinEventLogDisableStrategy;
}

- (BOOL)et_isRootPage {
    return self.et_props.isRootPage;
}
- (void)et_setRootPage:(BOOL)et_rootPage {
    self.et_props.rootPage = et_rootPage;
}

- (BOOL)et_pageOcclusionEnable {
    return self.et_props.isPageOcclusionEnable;
}
- (void)et_setPageOcclusitionEnable:(BOOL)et_pageOcclusionEnable {
    self.et_props.pageOcclusionEnable = et_pageOcclusionEnable;
}

- (BOOL)et_isIgnoreReferCascade {
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}
- (void)et_setIgnoreReferCascade:(BOOL)et_ignoreReferCascade {
    objc_setAssociatedObject(self, @selector(et_isIgnoreReferCascade), @(et_ignoreReferCascade), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)et_psreferMute {
    return self.et_props.isPsreferMuted;
}
- (void)et_setPsreferMute:(BOOL)et_psreferMute {
    self.et_props.psreferMute = et_psreferMute;
}

- (EventTracingVTreeNode *)et_currentVTreeNode {
    return objc_getAssociatedObject(self, _cmd);
}
- (void)et_setCurrentVTreeNode:(EventTracingVTreeNode *)et_currentVTreeNode {
    objc_setAssociatedObject(self, @selector(et_currentVTreeNode), et_currentVTreeNode, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end


@implementation UIView (EventTracingVTreeVirtualParentNode)
- (NSString *)et_virtualParentElementId {
    return self.et_virtualParentProps.virtualParentNodeElementId;
}
- (void)et_setVirtualParentElementId:(NSString *)elementId
                      nodeIdentifier:(id)nodeIdentifier
                              params:(NSDictionary<NSString *,NSString *> *)params {
    ETNodeBuildinEventLogDisableStrategy buildinEventLogDisableStrategy = [EventTracingEngine sharedInstance].ctx.isElementAutoImpressendEnable ? ETNodeBuildinEventLogDisableStrategyNone : ETNodeBuildinEventLogDisableStrategyImpressend;
    [self et_setVirtualParentElementId:elementId
                           nodeIdentifier:nodeIdentifier
                                 position:0
           buildinEventLogDisableStrategy:buildinEventLogDisableStrategy
                                   params:params];
}

- (void)et_setVirtualParentElementId:(NSString *)elementId
                         nodeIdentifier:(id)nodeIdentifier
                               position:(NSUInteger)position
         buildinEventLogDisableStrategy:(ETNodeBuildinEventLogDisableStrategy)buildinEventLogDisableStrategy
                                 params:(NSDictionary<NSString *, NSString *> * _Nullable)params {
    if (![elementId isKindOfClass:NSString.class] || !elementId.length) {
        return;
    }

    NSString *identifierString = nil;
    if ([nodeIdentifier isKindOfClass:NSString.class]) {
        identifierString = nodeIdentifier;
    } else {
        identifierString = [NSString stringWithFormat:@"%p", nodeIdentifier];
    }

    if (![identifierString isKindOfClass:NSString.class] || !identifierString.length) {
        return;
    }

    self.et_virtualParentProps = [EventTracingVirtualParentAssociatedPros associatedProsWithView:self];
    [self.et_virtualParentProps setupVirtualParentElementId:elementId nodeIdentifier:identifierString params:params];
    self.et_virtualParentProps.position = position;
    self.et_virtualParentProps.buildinEventLogDisableStrategy = buildinEventLogDisableStrategy;

    [[EventTracingEngine sharedInstance] traverse];
}

@end

@implementation UIView (EventTracingPrivate_Direct)

void *objc_key_et_props = &objc_key_et_props;
- (EventTracingAssociatedPros *)et_props {
    return objc_getAssociatedObject(self, objc_key_et_props);
}
- (void)et_setProps:(EventTracingAssociatedPros *)et_props {
    objc_setAssociatedObject(self, objc_key_et_props, et_props, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

void *objc_key_et_virtualParentProps = &objc_key_et_virtualParentProps;
- (EventTracingVirtualParentAssociatedPros *)et_virtualParentProps {
    return objc_getAssociatedObject(self, objc_key_et_virtualParentProps);
}
- (void)et_setVirtualParentProps:(EventTracingVirtualParentAssociatedPros *)et_virtualParentProps {
    objc_setAssociatedObject(self, objc_key_et_virtualParentProps, et_virtualParentProps, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)et_isSimpleVisible {
    //当前是主window，自身没有window和superVie，但其应该要被判定为可见的。
    if (self == [UIApplication sharedApplication].delegate.window) { return YES; }
    if (self == [UIApplication sharedApplication].keyWindow) { return YES; }
    
    //主window自身没有window，但是普通视图没有window，可以确定其是不可见的。
    if (!self.window) { return NO; }
    if (self.hidden) { return NO; }
    if (self.alpha <= CGFLOAT_MIN) { return NO; }
    
    return YES;
}

void *objc_key_et_subLogicalViews = &objc_key_et_subLogicalViews;
- (NSHashTable<EventTracingWeakObjectContainer<UIView *> *> *)et_subLogicalViews {
    return objc_getAssociatedObject(self, objc_key_et_subLogicalViews);
}
- (void)et_setSubLogicalViews:(NSHashTable<EventTracingWeakObjectContainer<UIView *> *> *)et_subLogicalViews {
    objc_setAssociatedObject(self, objc_key_et_subLogicalViews, et_subLogicalViews, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)et_hasSubNodes {
    return ET_isHasSubNodes(self);
}

- (UIViewController *)et_currentViewController {
    UIViewController *vc = (UIViewController *)self.nextResponder;
    if ([vc isKindOfClass:UIViewController.class]) {
        return vc;
    }
    return nil;
}

- (void)et_tryRefreshDynamicParamsCascadeSubViews {
    [@[self] et_enumerateObjectsUsingBlock:^NSArray<UIView *> * _Nonnull(UIView * _Nonnull view, BOOL * _Nonnull stop) {
        if (ET_isPageOrElement(view)) {
            [view.et_currentVTreeNode refreshDynsmicParamsIfNeeded];
        }
        return view.subviews;
    }];
}

@end
