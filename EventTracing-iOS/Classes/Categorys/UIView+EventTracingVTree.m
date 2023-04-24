//
//  UIView+EventTracingVTree.m
//  NEEventTracing
//
//  Created by dl on 2021/3/18.
//

#import "UIView+EventTracing.h"
#import "UIView+EventTracingPrivate.h"
#import "NEEventTracingEngine+Private.h"
#import "NEEventTracingContext+Private.h"

#import "NSArray+ETEnumerator.h"
#import <BlocksKit/BlocksKit.h>
#import <objc/runtime.h>

static NSMutableDictionary<NSNumber *, NSHashTable<UIView *> *> *sETAutoMountRootPageViewsContainer = nil;
NSArray<UIView *> *NEEventTracingAutoMountRootPageViews(void) {
    NSArray<NSNumber *> *orderdPrioritys = [sETAutoMountRootPageViewsContainer.keyEnumerator.allObjects sortedArrayUsingComparator:^NSComparisonResult(NSNumber * _Nonnull obj1, NSNumber * _Nonnull obj2) {
        return obj1.unsignedIntegerValue > obj2.unsignedIntegerValue;
    }];
    NSMutableOrderedSet * viewsSet = [NSMutableOrderedSet orderedSet];
    [orderdPrioritys enumerateObjectsUsingBlock:^(NSNumber * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSHashTable<UIView *> *viewsForPriority = [sETAutoMountRootPageViewsContainer objectForKey:obj];
        [viewsSet addObjectsFromArray:viewsForPriority.allObjects];
    }];
    return viewsSet.array.copy;
}
void NEEventTracingPushAutoMountRootPageView(UIView *view, NEETAutoMountRootPageQueuePriority priority) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sETAutoMountRootPageViewsContainer = [@{} mutableCopy];
    });
    
    NSHashTable<UIView *> *views = [sETAutoMountRootPageViewsContainer objectForKey:@(priority)];
    if (!views) {
        views = [NSHashTable hashTableWithOptions:NSPointerFunctionsWeakMemory];
        [sETAutoMountRootPageViewsContainer setObject:views forKey:@(priority)];
    }
    
    [views removeObject:view];
    [views addObject:view];
}

void NEEventTracingRemoveAutoMountRootPageView(UIView *view) {
    [sETAutoMountRootPageViewsContainer enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, NSHashTable<UIView *> * _Nonnull views, BOOL * _Nonnull stop) {
        [views removeObject:view];
    }];
}

static NSHashTable<UIView *> *sNEEventTracingLogicalParentSPMViews = nil;
NSArray<UIView *> *NEEventTracingLogicalParentSPMViews(void) {
    return sNEEventTracingLogicalParentSPMViews.allObjects;
}

void NEEventTracingPushLogicalParentSPMView(UIView *view) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sNEEventTracingLogicalParentSPMViews = [NSHashTable hashTableWithOptions:NSPointerFunctionsWeakMemory];
    });
    [sNEEventTracingLogicalParentSPMViews addObject:view];
}

void NEEventTracingRemoveLogicalParentSPMView(UIView *view) {
    [sNEEventTracingLogicalParentSPMViews removeObject:view];
}

@implementation UIViewController (EventTracingVTree)
#pragma mark - NEEventTracingVTreeNodeExtraConfigProtocol
- (NSArray<NSString *> *)ne_et_validForContainingSubNodeOids { return [self.p_ne_et_view ne_et_validForContainingSubNodeOids]; }

#pragma mark - Others
- (void)ne_et_setLogicalParentViewController:(UIViewController *)ne_et_logicalParentViewController {
    self.p_ne_et_view.ne_et_logicalParentViewController = ne_et_logicalParentViewController;
}
- (UIViewController *)ne_et_logicalParentViewController {
    return self.p_ne_et_view.ne_et_logicalParentViewController;
}

- (void)ne_et_setLogicalParentView:(UIView *)ne_et_logicalParentView {
    self.p_ne_et_view.ne_et_logicalParentView = ne_et_logicalParentView;
}
- (UIView *)ne_et_logicalParentView {
    return self.p_ne_et_view.ne_et_logicalParentView;
}

- (NSString *)ne_et_logicalParentSPM {
    return self.p_ne_et_view.ne_et_logicalParentSPM;
}

- (void)ne_et_setLogicalParentSPM:(NSString *)ne_et_logicalParentSPM {
    self.p_ne_et_view.ne_et_logicalParentSPM = ne_et_logicalParentSPM;
}

- (BOOL)ne_et_logicalVisible {
    return [self.p_ne_et_view ne_et_logicalVisible];
}
- (void)ne_et_setLogicalVisible:(BOOL)ne_et_logicalVisible {
    [self.p_ne_et_view ne_et_setLogicalVisible:ne_et_logicalVisible];
}

- (BOOL)ne_et_isAutoMountOnCurrentRootPageEnable {
    return [self.p_ne_et_view ne_et_isAutoMountOnCurrentRootPageEnable];
}
- (void)ne_et_autoMountOnCurrentRootPage {
    [self.p_ne_et_view ne_et_autoMountOnCurrentRootPage];
}
- (void)ne_et_autoMountOnCurrentRootPageWithPriority:(NEETAutoMountRootPageQueuePriority)priority {
    [self.p_ne_et_view ne_et_autoMountOnCurrentRootPageWithPriority:priority];
}
- (void)ne_et_cancelAutoMountOnCurrentRootPage {
    [self.p_ne_et_view ne_et_cancelAutoMountOnCurrentRootPage];
}
- (void)ne_et_cancelAutoMountOnCuurentRootPage {
    [self ne_et_cancelAutoMountOnCurrentRootPage];
}

- (UIEdgeInsets)ne_et_visibleEdgeInsets {
    return self.p_ne_et_view.ne_et_visibleEdgeInsets;
}
- (void)ne_et_setVisibleEdgeInsets:(UIEdgeInsets)ne_et_visibleEdgeInsets {
    self.p_ne_et_view.ne_et_visibleEdgeInsets = ne_et_visibleEdgeInsets;
}

- (NEETNodeVisibleRectCalculateStrategy)ne_et_visibleRectCalculateStrategy {
    return self.p_ne_et_view.ne_et_visibleRectCalculateStrategy;
}
- (void)ne_et_setVisibleRectCalculateStrategy:(NEETNodeVisibleRectCalculateStrategy)ne_et_visibleRectCalculateStrategy {
    self.p_ne_et_view.ne_et_visibleRectCalculateStrategy = ne_et_visibleRectCalculateStrategy;
    
    [[NEEventTracingEngine sharedInstance] traverse];
}
@end

@implementation UIView (EventTracingVTree)
#pragma mark - NEEventTracingVTreeNodeExtraConfigProtocol
- (NSArray<NSString *> *)ne_et_validForContainingSubNodeOids { return @[]; }

#pragma mark - Others
- (void)ne_et_setLogicalParentViewController:(UIViewController *)ne_et_logicalParentViewController {
    [self ne_et_setLogicalParentView:ne_et_logicalParentViewController.p_ne_et_view];
}
- (UIViewController *)ne_et_logicalParentViewController {
    UIViewController *viewController = (UIViewController *)self.ne_et_logicalParentView.nextResponder;
    return [viewController isKindOfClass:UIViewController.class] ? viewController : nil;
}

- (void)ne_et_setLogicalParentView:(UIView *)ne_et_logicalParentView {
    if (self.ne_et_isAutoMountOnCurrentRootPageEnable) {
        [self ne_et_cancelAutoMountOnCurrentRootPage];
    }
    self.ne_et_logicalParentSPM = nil;
    
    if (ne_et_logicalParentView) {
        if (ne_et_logicalParentView != self.ne_et_logicalParentView
            && !NE_ET_checkIfExistsLogicalMountEndlessLoopAtView(self, ne_et_logicalParentView)) {
            
            // 循环性的检测
            
            NEEventTracingWeakObjectContainer<UIView *> *container = [[NEEventTracingWeakObjectContainer alloc] initWithTarget:self object:ne_et_logicalParentView];
            objc_setAssociatedObject(self, @selector(ne_et_logicalParentView), container, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            
            NSHashTable<NEEventTracingWeakObjectContainer<UIView *> *> *table = ne_et_logicalParentView.ne_et_subLogicalViews;
            if (!table) {
                table = [NSHashTable hashTableWithOptions:NSPointerFunctionsWeakMemory];
                ne_et_logicalParentView.ne_et_subLogicalViews = table;
            }
            [table addObject:container];
            
            [[NEEventTracingEngine sharedInstance] traverse];
        }
        
        return;
    }
    
    if (!ne_et_logicalParentView) {
        objc_setAssociatedObject(self, @selector(ne_et_logicalParentView), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
        [[NEEventTracingEngine sharedInstance] traverse];
    }
}
- (UIView *)ne_et_logicalParentView {
    NEEventTracingWeakObjectContainer<UIView *> *container = [self bk_associatedValueForKey:_cmd];
    return container.object;
}

- (NSString *)ne_et_logicalParentSPM {
    return self.ne_et_props.logicalParentSPM;
}
- (void)ne_et_setLogicalParentSPM:(NSString *)ne_et_logicalParentSPM {
    if (self.ne_et_logicalParentView != nil) {
        return;
    }
    
    self.ne_et_props.logicalParentSPM = ne_et_logicalParentSPM;
    
    if (ne_et_logicalParentSPM != nil) {
        NEEventTracingPushLogicalParentSPMView(self);
    } else {
        NEEventTracingRemoveLogicalParentSPMView(self);
    }
    
    [[NEEventTracingEngine sharedInstance] traverse];
}

- (BOOL)ne_et_logicalVisible {
    return self.ne_et_props.logicalVisible;
}
- (void)ne_et_setLogicalVisible:(BOOL)ne_et_logicalVisible {
    if (self.ne_et_logicalVisible == ne_et_logicalVisible) {
        return;
    }
    
    self.ne_et_props.logicalVisible = ne_et_logicalVisible;
    [[NEEventTracingEngine sharedInstance] traverse];
}

- (BOOL)ne_et_isAutoMountOnCurrentRootPageEnable {
    return self.ne_et_props.isAutoMountRootPage;
}
- (void)ne_et_autoMountOnCurrentRootPage {
    [self ne_et_autoMountOnCurrentRootPageWithPriority:NEETAutoMountRootPageQueuePriorityDefault];
}
- (void)ne_et_autoMountOnCurrentRootPageWithPriority:(NEETAutoMountRootPageQueuePriority)priority {
    if (self.ne_et_logicalParentView != nil || self.ne_et_logicalParentSPM != nil) {
        return;
    }
    self.ne_et_props.autoMountRootPage = YES;
    
    NEEventTracingPushAutoMountRootPageView(self, priority);
    [[NEEventTracingEngine sharedInstance] traverse];
}
- (void)ne_et_cancelAutoMountOnCurrentRootPage {
    self.ne_et_props.autoMountRootPage = NO;
    
    NEEventTracingRemoveAutoMountRootPageView(self);
    [[NEEventTracingEngine sharedInstance] traverse];
}

- (void)ne_et_cancelAutoMountOnCuurentRootPage {
    [self ne_et_cancelAutoMountOnCurrentRootPage];
}

- (UIEdgeInsets)ne_et_visibleEdgeInsets {
    return self.ne_et_props.visibleEdgeInsets;
}
- (void)ne_et_setVisibleEdgeInsets:(UIEdgeInsets)ne_et_visibleEdgeInsets {
    UIEdgeInsets preInsets = [self ne_et_visibleEdgeInsets];
    if (UIEdgeInsetsEqualToEdgeInsets(preInsets, ne_et_visibleEdgeInsets)) {
        return;
    }
    self.ne_et_props.visibleEdgeInsets = ne_et_visibleEdgeInsets;
    
    [[NEEventTracingEngine sharedInstance] traverse];
}

- (NEETNodeVisibleRectCalculateStrategy)ne_et_visibleRectCalculateStrategy {
    return self.ne_et_props.visibleRectCalculateStrategy;
}
- (void)ne_et_setVisibleRectCalculateStrategy:(NEETNodeVisibleRectCalculateStrategy)ne_et_visibleRectCalculateStrategy {
    self.ne_et_props.visibleRectCalculateStrategy = ne_et_visibleRectCalculateStrategy;
}

#pragma mark - NEEventTracingVTreeNodeElementImpressThresholdProtocol
- (CGFloat)ne_et_impressRatioThreshold {
    return 0.f;
}
- (void)ne_et_setImpressRatioThreshold:(CGFloat)ne_et_impressRatioThreshold {}

- (NSTimeInterval)ne_et_impressIntervalThreshold {
    return 0;
}
- (void)ne_et_setImpressIntervalThreshold:(NSTimeInterval)ne_et_impressIntervalThreshold {}

@end

#pragma mark - VTreeNodeImpressObserver
@implementation UIView (EventTracingVTreeObserver)
- (NSArray<id<NEEventTracingVTreeNodeImpressObserver>> *)ne_et_impressObservers {
    NSHashTable<id<NEEventTracingVTreeNodeImpressObserver>> *observers = objc_getAssociatedObject(self, _cmd);
    return observers.allObjects;
}

- (void)ne_et_addImpressObserver:(id<NEEventTracingVTreeNodeImpressObserver>)observer {
    NSHashTable<id<NEEventTracingVTreeNodeImpressObserver>> *observers = objc_getAssociatedObject(self, @selector(ne_et_impressObservers));
    if (!observers) {
        observers = [NSHashTable hashTableWithOptions:NSPointerFunctionsWeakMemory];
        objc_setAssociatedObject(self, @selector(ne_et_impressObservers), observers, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    if ([observers containsObject:observer]) {
        return;
    }
    
    [observers addObject:observer];
}

- (void)ne_et_removeImpressObserver:(id<NEEventTracingVTreeNodeImpressObserver>)observer {
    NSHashTable<id<NEEventTracingVTreeNodeImpressObserver>> *observers = objc_getAssociatedObject(self, @selector(ne_et_impressObservers));
    [observers removeObject:observer];
}

- (void)ne_et_removeallImpressObservers {
    NSHashTable<id<NEEventTracingVTreeNodeImpressObserver>> *observers = objc_getAssociatedObject(self, @selector(ne_et_impressObservers));
    [observers removeAllObjects];
}
@end
