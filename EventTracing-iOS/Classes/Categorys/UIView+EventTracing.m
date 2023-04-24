//
//  UIView+EventTracing.m
//  BlocksKit
//
//  Created by dl on 2021/2/4.
//

#import "UIView+EventTracing.h"
#import "NEEventTracingReferFuncs.h"
#import "NEEventTracingEventReferQueue.h"
#import "NEEventTracingContext+Private.h"
#import "NEEventTracingVTreeNode+Private.h"
#import "NEEventTracingEngine+Private.h"
#import "UIView+EventTracingPipEvent.h"
#import "UIView+EventTracingPrivate.h"

#import "NSArray+ETEnumerator.h"
#import <BlocksKit/BlocksKit.h>
#import <objc/runtime.h>

#define kETUnvisibleAlpha 0.0001
#define kETUnvisibleWH 0.0001

@implementation NEEventTracingEventActionConfig
+ (instancetype)configWithEvent:(NSString *)event {
    NEEventTracingEventActionConfig *config = [[NEEventTracingEventActionConfig alloc] init];
    if ([[NEEventTracingEngine sharedInstance].ctx.needIncreaseActseqLogEvents containsObject:event]) {
        config.increaseActseq = YES;
        config.useForRefer = YES;
    }
    return config;
}
@end

@implementation UIViewController (EventTracingParams_Page)

- (void)ne_et_setPageId:(NSString *)pageId params:(NSDictionary<NSString *,NSString *> *)params {
    [self.p_ne_et_view ne_et_setPageId:pageId params:params];
}
- (void)ne_et_addParams:(NSDictionary<NSString *,NSString *> *)params {
    [self.p_ne_et_view ne_et_addParams:params];
}
- (void)ne_et_setParamValue:(NSString *)value forKey:(NSString *)key {
    [self.p_ne_et_view ne_et_setParamValue:value forKey:key];
}
- (void)ne_et_removeParamForKey:(NSString *)key {
    [self.p_ne_et_view ne_et_removeParamForKey:key];
}
- (void)ne_et_removeAllParams {
    [self.p_ne_et_view ne_et_removeAllParams];
}

- (void)ne_et_addParamsCallback:(NE_ET_AddParamsCallback NS_NOESCAPE)callback {
    [self.p_ne_et_view ne_et_addParamsCallback:callback];
}
- (void)ne_et_addParamsCallback:(NE_ET_AddParamsCallback NS_NOESCAPE)callback forEvent:(NSString *)event {
    [self.p_ne_et_view ne_et_addParamsCallback:callback forEvent:event];
}
- (void)ne_et_addParamsCallback:(NE_ET_AddParamsCallback NS_NOESCAPE)callback forEvents:(NSArray<NSString *> *)events {
    [self.p_ne_et_view ne_et_addParamsCallback:callback forEvents:events];
}
- (void)ne_et_addParamsCarryEventCallback:(NE_ET_AddParamsCarryEventCallback NS_NOESCAPE)callback forEvents:(NSArray<NSString *> *)events {
    [self.p_ne_et_view ne_et_addParamsCarryEventCallback:callback forEvents:events];
}
- (void)ne_et_removeParamsCallback:(NE_ET_AddParamsCallback)callback {}
- (void)ne_et_removeParamsCallback:(NE_ET_AddParamsCallback)callback forEvent:(NSString *)event {}

- (NSUInteger)ne_et_position {
    return self.p_ne_et_view.ne_et_position;
}
- (void)ne_et_setPosition:(NSUInteger)ne_et_position {
    [self.p_ne_et_view ne_et_setPosition:ne_et_position];
}
- (void)ne_et_clear {
    [self.p_ne_et_view ne_et_clear];
}
- (NSDictionary *)ne_et_params {
    return [self.p_ne_et_view ne_et_params];
}

- (NEETNodeBuildinEventLogDisableStrategy)ne_et_buildinEventLogDisableStrategy {
    return [self.p_ne_et_view ne_et_buildinEventLogDisableStrategy];
}
- (void)ne_et_setBuildinEventLogDisableStrategy:(NEETNodeBuildinEventLogDisableStrategy)ne_et_buildinEventLogDisableStrategy {
    [self.p_ne_et_view ne_et_setBuildinEventLogDisableStrategy:ne_et_buildinEventLogDisableStrategy];
}

- (BOOL)ne_et_isRootPage {
    return [self.p_ne_et_view ne_et_isRootPage];
}
- (void)ne_et_setRootPage:(BOOL)ne_et_rootPage {
    [self.p_ne_et_view ne_et_setRootPage:ne_et_rootPage];
}

- (BOOL)ne_et_pageOcclusionEnable {
    return self.p_ne_et_view.ne_et_pageOcclusionEnable;
}
- (void)ne_et_setPageOcclusitionEnable:(BOOL)ne_et_pageOcclusionEnable {
    [self.p_ne_et_view ne_et_setPageOcclusitionEnable:ne_et_pageOcclusionEnable];
}

- (BOOL)ne_et_isIgnoreReferCascade {
    return self.p_ne_et_view.ne_et_ignoreReferCascade;
}
- (void)ne_et_setIgnoreReferCascade:(BOOL)ne_et_ignoreReferCascade {
    self.p_ne_et_view.ne_et_ignoreReferCascade = ne_et_ignoreReferCascade;
}

- (BOOL)ne_et_psreferMute {
    return self.p_ne_et_view.ne_et_psreferMute;
}
- (void)ne_et_setPsreferMute:(BOOL)ne_et_psreferMute {
    self.p_ne_et_view.ne_et_psreferMute = ne_et_psreferMute;
}

- (BOOL)ne_et_subpagePvToReferEnable {
    return self.p_ne_et_view.ne_et_subpagePvToReferEnable;
}
- (void)ne_et_setSubpagePvToReferEnable:(BOOL)ne_et_subpagePvToReferEnable {
    self.p_ne_et_view.ne_et_subpagePvToReferEnable = ne_et_subpagePvToReferEnable;
}
- (NEEventTracingPageReferConsumeOption)ne_et_subpageConsumeOption {
    return self.p_ne_et_view.ne_et_subpageConsumeOption;
}
- (void)ne_et_setSubpageConsumeOption:(NEEventTracingPageReferConsumeOption)ne_et_subpageConsumeOption {
    self.p_ne_et_view.ne_et_subpageConsumeOption = ne_et_subpageConsumeOption;
}
- (void)ne_et_clearSubpageConsumeReferOption {
    [self.p_ne_et_view ne_et_clearSubpageConsumeReferOption];
}
- (void)ne_et_makeSubpageConsumeAllRefer {
    [self.p_ne_et_view ne_et_makeSubpageConsumeAllRefer];
}
- (void)ne_et_makeSubpageConsumeEventRefer {
    [self.p_ne_et_view ne_et_makeSubpageConsumeEventRefer];
}

#pragma mark - setters & getters
- (NSString *)ne_et_pageId {
    return self.p_ne_et_view.ne_et_pageId;
}

- (BOOL)ne_et_isPage {
    return self.p_ne_et_view.ne_et_isPage;
}

- (NEEventTracingVTreeNode *)ne_et_currentVTreeNode {
    return self.p_ne_et_view.ne_et_currentVTreeNode;
}

- (UIView *)p_ne_et_view {
    /// MARK: alert不做卡点
    if ([self isKindOfClass:[UIAlertController class]]) {
        return self.view;
    }
    
    NSString *vcClassName = NSStringFromClass(self.class);
    NSString *message = [NSString stringWithFormat:@"[%@]\n view not loaded when call `self.view` in NEEvnetTracing", vcClassName];
    
    if ([NEEventTracingEngine sharedInstance].ctx.viewControllerDidNotLoadViewExceptionTip == NEETViewControllerDidNotLoadViewExceptionTipAssert) {
        NSAssert(self.isViewLoaded, message);
    } else if (!self.isViewLoaded && [NEEventTracingEngine sharedInstance].ctx.viewControllerDidNotLoadViewExceptionTip == NEETViewControllerDidNotLoadViewExceptionTipCostom) {
        if ([[NEEventTracingEngine sharedInstance].ctx.exceptionInterface respondsToSelector:@selector(viewControllerDidNotLoadView:message:)]) {
            [[NEEventTracingEngine sharedInstance].ctx.exceptionInterface viewControllerDidNotLoadView:self message:message];
        }
    }
    
    return self.view;
}

- (BOOL)ne_et_isTransitioning {
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)ne_et_setTransitioning:(BOOL)ne_et_transitioning {
    objc_setAssociatedObject(self, @selector(ne_et_isTransitioning), @(ne_et_transitioning), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end


@implementation UIView (EventTracingParams_Page_Element)
- (void)ne_et_setPageId:(NSString *)pageId params:(NSDictionary<NSString *,NSString *> *)params {
    [self _et_setIdStr:pageId isPage:YES params:params];
}
- (void)ne_et_setElementId:(NSString *)elementId params:(NSDictionary<NSString *,NSString *> *)params {
    [self _et_setIdStr:elementId isPage:NO params:params];
}

- (void)ne_et_addParams:(NSDictionary<NSString *,NSString *> *)params {
    if (![params isKindOfClass:NSDictionary.class] || params.count == 0) {
        return;
    }
    
    [self.ne_et_props.params addEntriesFromDictionary:params];
    [self _et_doSyncStaticParamsToNodeIfNeeded];
    [self _et_checkUserParamsKeyValidIfNeeded:params.allKeys];
}
- (void)ne_et_setParamValue:(NSString *)value forKey:(NSString *)key {
    if (!key.length) {
        return;
    }
    
    [self.ne_et_props.params setObject:value forKey:key];
    [self _et_doSyncStaticParamsToNodeIfNeeded];
    [self _et_checkUserParamsKeyValidIfNeeded:@[key]];
}
- (void)ne_et_removeParamForKey:(NSString *)key {
    [self.ne_et_props.params removeObjectForKey:key];
    [self _et_doSyncStaticParamsToNodeIfNeeded];
    [self.ne_et_props.checkedGuardParamKeys removeObject:key];
}
- (void)ne_et_removeAllParams {
    [self.ne_et_props.params removeAllObjects];
    [self _et_doSyncStaticParamsToNodeIfNeeded];
    [self.ne_et_props.checkedGuardParamKeys removeAllObjects];
}

- (void)ne_et_addParamsCallback:(NE_ET_AddParamsCallback NS_NOESCAPE)callback {
    [self.ne_et_props addParamsCallback:callback forEvent:kNEETAddParamCallbackObjectkey];
}
- (void)ne_et_addParamsCallback:(NE_ET_AddParamsCallback NS_NOESCAPE)callback forEvent:(NSString *)event {
    [self.ne_et_props addParamsCallback:callback forEvent:event];
}
- (void)ne_et_addParamsCallback:(NE_ET_AddParamsCallback NS_NOESCAPE)callback forEvents:(NSArray<NSString *> *)events {
    [events enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self.ne_et_props addParamsCallback:callback forEvent:obj];
    }];
}
- (void)ne_et_addParamsCarryEventCallback:(NE_ET_AddParamsCarryEventCallback NS_NOESCAPE)callback forEvents:(NSArray<NSString *> *)events {
    [self.ne_et_props addParamsCarryEventCallback:callback forEvents:events];
}

- (void)ne_et_removeParamsCallback:(NE_ET_AddParamsCallback)callback {}
- (void)ne_et_removeParamsCallback:(NE_ET_AddParamsCallback)callback forEvent:(NSString *)event {}

- (NSUInteger)ne_et_position {
    return [self.ne_et_props position];
}

- (void)ne_et_setPosition:(NSUInteger)ne_et_position {
    self.ne_et_props.position = ne_et_position;
    
    NEEventTracingVTreeNode *VTreeNode = self.ne_et_currentVTreeNode;
    // cell复用场景
    if ([self.ne_et_reuseIdentifier isEqualToString:VTreeNode.identifier]) {
        [VTreeNode updatePosition:ne_et_position];
    }
}

- (void)ne_et_clear {
    BOOL needsTraversel = self.ne_et_isPage || self.ne_et_isElement;
    
    self.ne_et_props = nil;
    self.ne_et_logicalParentView = nil;
    self.ne_et_ignoreReferCascade = NO;

    if (needsTraversel) {
        [[NEEventTracingEngine sharedInstance] traverse];
    }
}

- (void)_et_setIdStr:(NSString *)idStr isPage:(BOOL)isPage params:(NSDictionary<NSString *,NSString *> *)params {
    if (![idStr isKindOfClass:NSString.class] || !idStr.length) {
        return;
    }
    
    self.ne_et_props = [NEEventTracingAssociatedPros associatedProsWithView:self];
    [self.ne_et_props setupOid:idStr isPage:isPage params:params];

    [self ne_et_cancelPipEvent];
    [[NEEventTracingEngine sharedInstance] traverse];
}

- (void)_et_doSyncStaticParamsToNodeIfNeeded {
    NEEventTracingVTreeNode *VTreeNode = self.ne_et_currentVTreeNode;
    // cell复用场景
    if ([self.ne_et_reuseIdentifier isEqualToString:VTreeNode.identifier]) {
        [VTreeNode updateStaticParams:self.ne_et_params];
    }
}

- (void)_et_checkUserParamsKeyValidIfNeeded:(NSArray<NSString *> *)keys {
    NSArray<NSString *> *filteredKeys = [keys bk_reject:^BOOL(NSString *obj) {
        return [self.ne_et_props.checkedGuardParamKeys containsObject:obj];
    }];
    [[NEEventTracingEngine sharedInstance].ctx.paramGuardExector asyncDoDispatchCheckTask:^{
        [filteredKeys enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NE_ET_CheckUserParamKeyValid(obj);
        }];
    }];
    [self.ne_et_props.checkedGuardParamKeys addObjectsFromArray:filteredKeys];
}

#pragma mark - setters & getters
- (NSString *)ne_et_pageId {
    return self.ne_et_props.pageId;
}
- (NSString *)ne_et_elementId {
    return self.ne_et_props.elementId;
}

- (BOOL)ne_et_isPage {
    return self.ne_et_props.isPage;
}

- (BOOL)ne_et_isElement {
    return self.ne_et_props.isElement;
}

- (NSDictionary *)ne_et_params {
    return self.ne_et_props.params;
}

- (NEETNodeBuildinEventLogDisableStrategy)ne_et_buildinEventLogDisableStrategy {
    return self.ne_et_props.buildinEventLogDisableStrategy;
}
- (void)ne_et_setBuildinEventLogDisableStrategy:(NEETNodeBuildinEventLogDisableStrategy)ne_et_buildinEventLogDisableStrategy {
    self.ne_et_props.buildinEventLogDisableStrategy = ne_et_buildinEventLogDisableStrategy;
}

- (BOOL)ne_et_isRootPage {
    return self.ne_et_props.isRootPage;
}
- (void)ne_et_setRootPage:(BOOL)ne_et_rootPage {
    self.ne_et_props.rootPage = ne_et_rootPage;
}

- (BOOL)ne_et_pageOcclusionEnable {
    return self.ne_et_props.isPageOcclusionEnable;
}
- (void)ne_et_setPageOcclusitionEnable:(BOOL)ne_et_pageOcclusionEnable {
    self.ne_et_props.pageOcclusionEnable = ne_et_pageOcclusionEnable;
}

- (BOOL)ne_et_isIgnoreReferCascade {
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}
- (void)ne_et_setIgnoreReferCascade:(BOOL)ne_et_ignoreReferCascade {
    objc_setAssociatedObject(self, @selector(ne_et_isIgnoreReferCascade), @(ne_et_ignoreReferCascade), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)ne_et_psreferMute {
    return self.ne_et_props.isPsreferMuted;
}
- (void)ne_et_setPsreferMute:(BOOL)ne_et_psreferMute {
    self.ne_et_props.psreferMute = ne_et_psreferMute;
}

- (BOOL)ne_et_subpagePvToReferEnable {
    return self.ne_et_props.isSubpagePvToReferEnable;
}
- (void)ne_et_setSubpagePvToReferEnable:(BOOL)ne_et_subpagePvToReferEnable {
    self.ne_et_props.subpagePvToReferEnable = ne_et_subpagePvToReferEnable;
}
- (void)ne_et_setSubpageConsumeOption:(NEEventTracingPageReferConsumeOption)option {
    self.ne_et_props.pageReferConsumeOption = option;
}
- (NEEventTracingPageReferConsumeOption)ne_et_subpageConsumeOption {
    return self.ne_et_props.pageReferConsumeOption;
}
- (void)ne_et_clearSubpageConsumeReferOption {
    self.ne_et_props.pageReferConsumeOption = NEEventTracingPageReferConsumeOptionNone;
}
- (void)ne_et_makeSubpageConsumeAllRefer {
    self.ne_et_props.pageReferConsumeOption = NEEventTracingPageReferConsumeOptionAll;
}
- (void)ne_et_makeSubpageConsumeEventRefer {
    self.ne_et_props.pageReferConsumeOption = NEEventTracingPageReferConsumeOptionExceptSubPagePV;
}

- (NEEventTracingVTreeNode *)ne_et_currentVTreeNode {
    return objc_getAssociatedObject(self, _cmd);
}
- (void)ne_et_setCurrentVTreeNode:(NEEventTracingVTreeNode *)ne_et_currentVTreeNode {
    objc_setAssociatedObject(self, @selector(ne_et_currentVTreeNode), ne_et_currentVTreeNode, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end


@implementation UIView (EventTracingVTreeVirtualParentNode)
- (BOOL)ne_et_virtualParentIsPage {
    return self.ne_et_virtualParentProps.virtualParentNodePageId.length > 0;
}
- (NSString *)ne_et_virtualParentOid {
    return self.ne_et_virtualParentIsPage ?
    self.ne_et_virtualParentProps.virtualParentNodePageId :
    self.ne_et_virtualParentProps.virtualParentNodeElementId;
}
- (NSString *)ne_et_virtualParentElementId {
    return self.ne_et_virtualParentProps.virtualParentNodeElementId;
}
- (NSString *)ne_et_virtualParentPageId {
    return self.ne_et_virtualParentProps.virtualParentNodePageId;
}
- (NSString *)ne_et_virtualParentelEmentId {
    return self.ne_et_virtualParentElementId;
}
- (void)ne_et_setVirtualParentElementId:(NSString *)elementId
                         nodeIdentifier:(id)nodeIdentifier
                                 params:(NSDictionary<NSString *,NSString *> *)params {
    NEETNodeBuildinEventLogDisableStrategy buildinEventLogDisableStrategy = [NEEventTracingEngine sharedInstance].ctx.isElementAutoImpressendEnable ? NEETNodeBuildinEventLogDisableStrategyNone : NEETNodeBuildinEventLogDisableStrategyImpressend;
    [self ne_et_setVirtualParentOid:elementId
                             isPage:NO
                     nodeIdentifier:nodeIdentifier
                           position:0
     buildinEventLogDisableStrategy:buildinEventLogDisableStrategy
                             params:params];
}

- (void)ne_et_setVirtualParentPageId:(NSString *)pageId
                      nodeIdentifier:(id)nodeIdentifier
                              params:(NSDictionary<NSString *,NSString *> *)params {
    [self ne_et_setVirtualParentOid:pageId
                             isPage:YES
                     nodeIdentifier:nodeIdentifier
                           position:0
     buildinEventLogDisableStrategy:NEETNodeBuildinEventLogDisableStrategyNone
                             params:params];
}

- (void)ne_et_setVirtualParentOid:(NSString *)oid
                           isPage:(BOOL)isPage
                   nodeIdentifier:(id)nodeIdentifier
                         position:(NSUInteger)position
   buildinEventLogDisableStrategy:(NEETNodeBuildinEventLogDisableStrategy)buildinEventLogDisableStrategy
                           params:(NSDictionary<NSString *, NSString *> * _Nullable)params {
    if (![oid isKindOfClass:NSString.class] || !oid.length) {
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

    self.ne_et_virtualParentProps = [NEEventTracingVirtualParentAssociatedPros associatedProsWithView:self];
    if (isPage) {
        [self.ne_et_virtualParentProps setupVirtualParentPageId:oid nodeIdentifier:identifierString params:params];
    } else {
        [self.ne_et_virtualParentProps setupVirtualParentElementId:oid nodeIdentifier:identifierString params:params];
    }
    self.ne_et_virtualParentProps.position = position;
    self.ne_et_virtualParentProps.buildinEventLogDisableStrategy = buildinEventLogDisableStrategy;

    [[NEEventTracingEngine sharedInstance] traverse];
}

- (void)ne_et_setVirtualParentElementId:(NSString *)elementId
                         nodeIdentifier:(id)nodeIdentifier
                               position:(NSUInteger)position
         buildinEventLogDisableStrategy:(NEETNodeBuildinEventLogDisableStrategy)buildinEventLogDisableStrategy
                                 params:(NSDictionary<NSString *, NSString *> * _Nullable)params
{
    [self ne_et_setVirtualParentOid:elementId isPage:NO nodeIdentifier:nodeIdentifier position:position buildinEventLogDisableStrategy:buildinEventLogDisableStrategy params:params];
}

@end

@implementation UIView (EventTracingPrivate_Direct)

void *objc_key_ne_et_props = &objc_key_ne_et_props;
- (NEEventTracingAssociatedPros *)ne_et_props {
    return objc_getAssociatedObject(self, objc_key_ne_et_props);
}
- (void)ne_et_setProps:(NEEventTracingAssociatedPros *)ne_et_props {
    objc_setAssociatedObject(self, objc_key_ne_et_props, ne_et_props, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

void *objc_key_ne_et_virtualParentProps = &objc_key_ne_et_virtualParentProps;
- (NEEventTracingVirtualParentAssociatedPros *)ne_et_virtualParentProps {
    return objc_getAssociatedObject(self, objc_key_ne_et_virtualParentProps);
}
- (void)ne_et_setVirtualParentProps:(NEEventTracingVirtualParentAssociatedPros *)ne_et_virtualParentProps {
    objc_setAssociatedObject(self, objc_key_ne_et_virtualParentProps, ne_et_virtualParentProps, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)ne_et_isSimpleVisible {
    //当前是主window，自身没有window和superVie，但其应该要被判定为可见的。
    if (self == [UIApplication sharedApplication].delegate.window) { return YES; }
    if (self == [UIApplication sharedApplication].keyWindow) { return YES; }
    
    //主window自身没有window，但是普通视图没有window，可以确定其是不可见的。
    if (!self.window) { return NO; }
    if (self.hidden) { return NO; }
    if (self.alpha <= CGFLOAT_MIN) { return NO; }
    
    return YES;
}

void *objc_key_ne_et_subLogicalViews = &objc_key_ne_et_subLogicalViews;
- (NSHashTable<NEEventTracingWeakObjectContainer<UIView *> *> *)ne_et_subLogicalViews {
    return objc_getAssociatedObject(self, objc_key_ne_et_subLogicalViews);
}
- (void)ne_et_setSubLogicalViews:(NSHashTable<NEEventTracingWeakObjectContainer<UIView *> *> *)ne_et_subLogicalViews {
    objc_setAssociatedObject(self, objc_key_ne_et_subLogicalViews, ne_et_subLogicalViews, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)ne_et_hasSubNodes {
    return NE_ET_isHasSubNodes(self);
}

- (UIViewController *)ne_et_currentViewController {
    UIViewController *vc = (UIViewController *)self.nextResponder;
    if ([vc isKindOfClass:UIViewController.class]) {
        return vc;
    }
    return nil;
}

- (void)ne_et_tryRefreshDynamicParamsCascadeSubViews {
    [@[self] ne_et_enumerateObjectsUsingBlock:^NSArray<UIView *> * _Nonnull(UIView * _Nonnull view, BOOL * _Nonnull stop) {
        if (NE_ET_isPageOrElement(view)) {
            [view.ne_et_currentVTreeNode refreshDynsmicParamsIfNeeded];
        }
        return view.subviews;
    }];
}

@end
