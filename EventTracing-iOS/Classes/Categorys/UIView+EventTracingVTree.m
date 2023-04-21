//
//  UIView+EventTracingVTree.m
//  EventTracing
//
//  Created by dl on 2021/3/18.
//

#import "UIView+EventTracing.h"
#import "UIView+EventTracingPrivate.h"
#import "EventTracingEngine+Private.h"
#import "EventTracingContext+Private.h"

#import "NSArray+ETEnumerator.h"
#import <BlocksKit/BlocksKit.h>
#import <objc/runtime.h>

static NSMutableDictionary<NSNumber *, NSHashTable<UIView *> *> *sETAutoMountRootPageViewsContainer = nil;
NSArray<UIView *> *EventTracingAutoMountRootPageViews(void) {
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
void EventTracingPushAutoMountRootPageView(UIView *view, ETAutoMountRootPageQueuePriority priority) {
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

void EventTracingRemoveAutoMountRootPageView(UIView *view) {
    [sETAutoMountRootPageViewsContainer enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, NSHashTable<UIView *> * _Nonnull views, BOOL * _Nonnull stop) {
        [views removeObject:view];
    }];
}

static NSHashTable<UIView *> *sEventTracingLogicalParentSPMViews = nil;
NSArray<UIView *> *EventTracingLogicalParentSPMViews(void) {
    return sEventTracingLogicalParentSPMViews.allObjects;
}

void EventTracingPushLogicalParentSPMView(UIView *view) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sEventTracingLogicalParentSPMViews = [NSHashTable hashTableWithOptions:NSPointerFunctionsWeakMemory];
    });
    [sEventTracingLogicalParentSPMViews addObject:view];
}

void EventTracingRemoveLogicalParentSPMView(UIView *view) {
    [sEventTracingLogicalParentSPMViews removeObject:view];
}

@implementation UIViewController (EventTracingVTree)
#pragma mark - EventTracingVTreeNodeExtraConfigProtocol
- (NSArray<NSString *> *)et_validForContainingSubNodeOids { return [self.p_et_view et_validForContainingSubNodeOids]; }

#pragma mark - Others
- (void)et_setLogicalParentViewController:(UIViewController *)et_logicalParentViewController {
    self.p_et_view.et_logicalParentViewController = et_logicalParentViewController;
}
- (UIViewController *)et_logicalParentViewController {
    return self.p_et_view.et_logicalParentViewController;
}

- (void)et_setLogicalParentView:(UIView *)et_logicalParentView {
    self.p_et_view.et_logicalParentView = et_logicalParentView;
}
- (UIView *)et_logicalParentView {
    return self.p_et_view.et_logicalParentView;
}

- (NSString *)et_logicalParentSPM {
    return self.p_et_view.et_logicalParentSPM;
}

- (void)et_setLogicalParentSPM:(NSString *)et_logicalParentSPM {
    self.p_et_view.et_logicalParentSPM = et_logicalParentSPM;
}

- (BOOL)et_logicalVisible {
    return [self.p_et_view et_logicalVisible];
}
- (void)et_setLogicalVisible:(BOOL)et_logicalVisible {
    [self.p_et_view et_setLogicalVisible:et_logicalVisible];
}

- (BOOL)et_isAutoMountOnCurrentRootPageEnable {
    return [self.p_et_view et_isAutoMountOnCurrentRootPageEnable];
}
- (void)et_autoMountOnCurrentRootPage {
    [self.p_et_view et_autoMountOnCurrentRootPage];
}
- (void)et_autoMountOnCurrentRootPageWithPriority:(ETAutoMountRootPageQueuePriority)priority {
    [self.p_et_view et_autoMountOnCurrentRootPageWithPriority:priority];
}
- (void)et_cancelAutoMountOnCurrentRootPage {
    [self.p_et_view et_cancelAutoMountOnCurrentRootPage];
}
- (UIEdgeInsets)et_visibleEdgeInsets {
    return self.p_et_view.et_visibleEdgeInsets;
}
- (void)et_setVisibleEdgeInsets:(UIEdgeInsets)et_visibleEdgeInsets {
    self.p_et_view.et_visibleEdgeInsets = et_visibleEdgeInsets;
}

- (ETNodeVisibleRectCalculateStrategy)et_visibleRectCalculateStrategy {
    return self.p_et_view.et_visibleRectCalculateStrategy;
}
- (void)et_setVisibleRectCalculateStrategy:(ETNodeVisibleRectCalculateStrategy)et_visibleRectCalculateStrategy {
    self.p_et_view.et_visibleRectCalculateStrategy = et_visibleRectCalculateStrategy;
    
    [[EventTracingEngine sharedInstance] traverse];
}
@end

@implementation UIView (EventTracingVTree)
#pragma mark - EventTracingVTreeNodeExtraConfigProtocol
- (NSArray<NSString *> *)et_validForContainingSubNodeOids { return @[]; }

#pragma mark - Others
- (void)et_setLogicalParentViewController:(UIViewController *)et_logicalParentViewController {
    [self et_setLogicalParentView:et_logicalParentViewController.p_et_view];
}
- (UIViewController *)et_logicalParentViewController {
    UIViewController *viewController = (UIViewController *)self.et_logicalParentView.nextResponder;
    return [viewController isKindOfClass:UIViewController.class] ? viewController : nil;
}

- (void)et_setLogicalParentView:(UIView *)et_logicalParentView {
    if (self.et_isAutoMountOnCurrentRootPageEnable) {
        [self et_cancelAutoMountOnCurrentRootPage];
    }
    self.et_logicalParentSPM = nil;
    
    if (et_logicalParentView) {
        if (et_logicalParentView != self.et_logicalParentView
            && !ET_checkIfExistsLogicalMountEndlessLoopAtView(self, et_logicalParentView)) {
            
            // 循环性的检测
            
            EventTracingWeakObjectContainer<UIView *> *container = [[EventTracingWeakObjectContainer alloc] initWithTarget:self object:et_logicalParentView];
            objc_setAssociatedObject(self, @selector(et_logicalParentView), container, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            
            NSHashTable<EventTracingWeakObjectContainer<UIView *> *> *table = et_logicalParentView.et_subLogicalViews;
            if (!table) {
                table = [NSHashTable hashTableWithOptions:NSPointerFunctionsWeakMemory];
                et_logicalParentView.et_subLogicalViews = table;
            }
            [table addObject:container];
            
            [[EventTracingEngine sharedInstance] traverse];
        }
        
        return;
    }
    
    if (!et_logicalParentView) {
        objc_setAssociatedObject(self, @selector(et_logicalParentView), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
        [[EventTracingEngine sharedInstance] traverse];
    }
}
- (UIView *)et_logicalParentView {
    EventTracingWeakObjectContainer<UIView *> *container = [self bk_associatedValueForKey:_cmd];
    return container.object;
}

- (NSString *)et_logicalParentSPM {
    return self.et_props.logicalParentSPM;
}
- (void)et_setLogicalParentSPM:(NSString *)et_logicalParentSPM {
    if (self.et_logicalParentView != nil) {
        return;
    }
    
    self.et_props.logicalParentSPM = et_logicalParentSPM;
    
    if (et_logicalParentSPM != nil) {
        EventTracingPushLogicalParentSPMView(self);
    } else {
        EventTracingRemoveLogicalParentSPMView(self);
    }
    
    [[EventTracingEngine sharedInstance] traverse];
}

- (BOOL)et_logicalVisible {
    return self.et_props.logicalVisible;
}
- (void)et_setLogicalVisible:(BOOL)et_logicalVisible {
    if (self.et_logicalVisible == et_logicalVisible) {
        return;
    }
    
    self.et_props.logicalVisible = et_logicalVisible;
    [[EventTracingEngine sharedInstance] traverse];
}

- (BOOL)et_isAutoMountOnCurrentRootPageEnable {
    return self.et_props.isAutoMountRootPage;
}
- (void)et_autoMountOnCurrentRootPage {
    [self et_autoMountOnCurrentRootPageWithPriority:ETAutoMountRootPageQueuePriorityDefault];
}
- (void)et_autoMountOnCurrentRootPageWithPriority:(ETAutoMountRootPageQueuePriority)priority {
    if (self.et_logicalParentView != nil || self.et_logicalParentSPM != nil) {
        return;
    }
    self.et_props.autoMountRootPage = YES;
    
    EventTracingPushAutoMountRootPageView(self, priority);
    [[EventTracingEngine sharedInstance] traverse];
}
- (void)et_cancelAutoMountOnCurrentRootPage {
    self.et_props.autoMountRootPage = NO;
    
    EventTracingRemoveAutoMountRootPageView(self);
    [[EventTracingEngine sharedInstance] traverse];
}

- (UIEdgeInsets)et_visibleEdgeInsets {
    return self.et_props.visibleEdgeInsets;
}
- (void)et_setVisibleEdgeInsets:(UIEdgeInsets)et_visibleEdgeInsets {
    UIEdgeInsets preInsets = [self et_visibleEdgeInsets];
    if (UIEdgeInsetsEqualToEdgeInsets(preInsets, et_visibleEdgeInsets)) {
        return;
    }
    self.et_props.visibleEdgeInsets = et_visibleEdgeInsets;
    
    [[EventTracingEngine sharedInstance] traverse];
}

- (ETNodeVisibleRectCalculateStrategy)et_visibleRectCalculateStrategy {
    return self.et_props.visibleRectCalculateStrategy;
}
- (void)et_setVisibleRectCalculateStrategy:(ETNodeVisibleRectCalculateStrategy)et_visibleRectCalculateStrategy {
    self.et_props.visibleRectCalculateStrategy = et_visibleRectCalculateStrategy;
}

@end

#pragma mark - VTreeNodeImpressObserver
@implementation UIView (EventTracingVTreeObserver)
- (NSArray<id<EventTracingVTreeNodeImpressObserver>> *)et_impressObservers {
    NSHashTable<id<EventTracingVTreeNodeImpressObserver>> *observers = objc_getAssociatedObject(self, _cmd);
    return observers.allObjects;
}

- (void)et_addImpressObserver:(id<EventTracingVTreeNodeImpressObserver>)observer {
    NSHashTable<id<EventTracingVTreeNodeImpressObserver>> *observers = objc_getAssociatedObject(self, @selector(et_impressObservers));
    if (!observers) {
        observers = [NSHashTable hashTableWithOptions:NSPointerFunctionsWeakMemory];
        objc_setAssociatedObject(self, @selector(et_impressObservers), observers, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    if ([observers containsObject:observer]) {
        return;
    }
    
    [observers addObject:observer];
}

- (void)et_removeImpressObserver:(id<EventTracingVTreeNodeImpressObserver>)observer {
    NSHashTable<id<EventTracingVTreeNodeImpressObserver>> *observers = objc_getAssociatedObject(self, @selector(et_impressObservers));
    [observers removeObject:observer];
}

- (void)et_removeallImpressObservers {
    NSHashTable<id<EventTracingVTreeNodeImpressObserver>> *observers = objc_getAssociatedObject(self, @selector(et_impressObservers));
    [observers removeAllObjects];
}
@end
