//
//  NEEventTracingUIScrollViewAOP.m
//  BlocksKit
//
//  Created by dl on 2021/2/24.
//

#import "NEEventTracingUIScrollViewAOP.h"

#import "NEEventTracingTraversalRunnerDurationThrottle.h"
#import "NEEventTracingTraversalRunnerScrollViewOffsetThrottle.h"

#import "NEEventTracingDelegateChain.h"
#import "NEEventTracingEngine+Private.h"
#import "UIView+EventTracingPrivate.h"
#import "UIScrollView+EventTracingES.h"
#import "NEEventTracingInternalLog.h"
#import "NEEventTracingClickMonitor.h"
#import "EventTracingConfuseMacro.h"

#import <BlocksKit/BlocksKit.h>
#import <JRSwizzle/JRSwizzle.h>
#import <objc/runtime.h>

/// MARK: 特殊声明 => 针对 UITableViewCell & UICollectionViewCell 的点击事件
/// `AOP.pre` & `AOP.after`
/// `AOP.pre`时，临时存储node.identifier, `AOP.after`时，取出来跟关联的node对比 => 1. 如果 !equal，则表明 `AOP.handler` 时，view进行了复用，或者view重新绑定了logical_identifier; 2. 如果eaual，则可直接使用view关联的node;
/// 典型case => 1. `AOP.handler`中，做了UITableView/UICollectionView的reload，引发了cell复用; 2. `AOP.handler`中，做了向前插入了一个cell;

@interface UIScrollView (EventTracingAOPInner) <NEEventTracingTraversalRunnerThrottleCallback>
@property(nonatomic, strong, setter=ne_et_setDelegateChain:) NEEventTracingDelegateChain *ne_et_delegateChain;

@property(nonatomic, strong, setter=ne_et_setThrottles:) NSArray<id<NEEventTracingTraversalRunnerThrottle>> *ne_et_throttles;
@end

@implementation UIScrollView (EventTracingAOP)

#define PreSelectorNames @[NSStringFromSelector(@selector(collectionView:didSelectItemAtIndexPath:)), NSStringFromSelector(@selector(tableView:didSelectRowAtIndexPath:))]
#define HockProtocols @[@protocol(UIScrollViewDelegate), @protocol(UITableViewDelegate), @protocol(UICollectionViewDelegateFlowLayout)]
#define Blacklist @[@"UITextView", ET_MANGLED(W,K,S,c,r,o,l,l,V,i,e,w), ET_MANGLED(_,U,I,W,e,b,V,i,e,w,S,c,r,o,l,l,V,i,e,w)]

NE_ET_DelegateChainHockBlacklist(scrollView,
                                 UICollectionViewDelegateFlowLayout,
                                 ne_et_delegateChain,
                                 NEEventTracingUIScrollViewAOP,
                                 PreSelectorNames,
                                 HockProtocols,
                                 Blacklist)

- (void)ne_et_didScrollWithContentOffset:(CGPoint)contentOffset {
    if (!self.ne_et_throttles) {
        self.ne_et_throttles = @[
            ({
                NEEventTracingTraversalRunnerDurationThrottle *durationThrottle = [[NEEventTracingTraversalRunnerDurationThrottle alloc] init];
                durationThrottle.tolerentDuration = [[[NEEventTracingEngine sharedInstance] context] throttleTolerentDuration];
                durationThrottle.callback = self;
                durationThrottle;
            }),
            ({
                NEEventTracingTraversalRunnerScrollViewOffsetThrottle *offsetThrottle = [[NEEventTracingTraversalRunnerScrollViewOffsetThrottle alloc] init];
                offsetThrottle.tolerentOffset = [[[NEEventTracingEngine sharedInstance] context] throttleTolerentOffset];
                offsetThrottle.callback = self;
                offsetThrottle;
            })
        ];
    }
    
    [self.ne_et_throttles enumerateObjectsUsingBlock:^(id<NEEventTracingTraversalRunnerThrottle>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj pushValue:[NSValue valueWithCGPoint:contentOffset]];
    }];
}

- (void)ne_et_resetThrottle {
    [self.ne_et_throttles enumerateObjectsUsingBlock:^(id<NEEventTracingTraversalRunnerThrottle>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj reset];
    }];
}

#pragma mark - NEEventTracingTraversalRunnerThrottleCallback
- (void)throttle:(id<NEEventTracingTraversalRunnerThrottle>)throttle throttleDidFinished:(BOOL)throttled {
    if (throttled) {
        return;
    }
    
    [throttle pause];
//    NSLog(@"### throttle ###, type: %@", throttle.name);
    
    BOOL hasUnpaused = [self.ne_et_throttles bk_any:^BOOL(id<NEEventTracingTraversalRunnerThrottle> obj) {
        return !obj.isPaused;
    }];
    
    if (!hasUnpaused) {
        [self ne_et_resetThrottle];
        
//        NSLog(@"### throttle ###, ready to traverse");
        [[NEEventTracingEngine sharedInstance] traverseForScrollView:self];
    }
}

#pragma mark - getters & setters
- (void)ne_et_setDelegateChain:(NEEventTracingDelegateChain *)ne_et_delegateChain {
    objc_setAssociatedObject(self, @selector(ne_et_delegateChain), ne_et_delegateChain, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (NEEventTracingDelegateChain *)ne_et_delegateChain {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)ne_et_setThrottles:(NSArray<id<NEEventTracingTraversalRunnerThrottle>> *)ne_et_throttles {
    objc_setAssociatedObject(self, @selector(ne_et_throttles), ne_et_throttles, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (NSArray<id<NEEventTracingTraversalRunnerThrottle>> *)ne_et_throttles {
    return objc_getAssociatedObject(self, _cmd);
}

@end

@interface UITableView (EventTracingAOP)
@property(nonatomic, weak, setter=ne_et_AOP_pre_setCell:) UITableViewCell *ne_et_AOP_pre_cell;
@end
@implementation UITableView (EventTracingAOP)

- (void)ne_et_tableView_reloadData {
    [[NEEventTracingEngine sharedInstance] traverse:self];
    [self ne_et_tableView_reloadData];
}
- (void)ne_et_tableView_insertSections:(NSIndexSet *)sections withRowAnimation:(UITableViewRowAnimation)animation {
    [[NEEventTracingEngine sharedInstance] traverse:self];
    [self ne_et_tableView_insertSections:sections withRowAnimation:animation];
}
- (void)ne_et_tableView_deleteSections:(NSIndexSet *)sections withRowAnimation:(UITableViewRowAnimation)animation {
    [[NEEventTracingEngine sharedInstance] traverse:self];
    [self ne_et_tableView_deleteSections:sections withRowAnimation:animation];
}
- (void)ne_et_tableView_reloadSections:(NSIndexSet *)sections withRowAnimation:(UITableViewRowAnimation)animation {
    [[NEEventTracingEngine sharedInstance] traverse:self];
    [self ne_et_tableView_reloadSections:sections withRowAnimation:animation];
}
- (void)ne_et_tableView_insertRowsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths withRowAnimation:(UITableViewRowAnimation)animation {
    [[NEEventTracingEngine sharedInstance] traverse:self];
    [self ne_et_tableView_insertRowsAtIndexPaths:indexPaths withRowAnimation:animation];
}
- (void)ne_et_tableView_deleteRowsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths withRowAnimation:(UITableViewRowAnimation)animation {
    [[NEEventTracingEngine sharedInstance] traverse:self];
    [self ne_et_tableView_deleteRowsAtIndexPaths:indexPaths withRowAnimation:animation];
}
- (void)ne_et_tableView_reloadRowsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths withRowAnimation:(UITableViewRowAnimation)animation {
    [[NEEventTracingEngine sharedInstance] traverse:self];
    [self ne_et_tableView_reloadRowsAtIndexPaths:indexPaths withRowAnimation:animation];
}

- (void)ne_et_AOP_pre_setCell:(UITableViewCell *)ne_et_AOP_pre_cell {
    [self bk_weaklyAssociateValue:ne_et_AOP_pre_cell withKey:@selector(ne_et_AOP_pre_cell)];
}
- (UITableViewCell *)ne_et_AOP_pre_cell {
    return [self bk_associatedValueForKey:_cmd];
}
@end

@interface UICollectionView (EventTracingAOP)
@property(nonatomic, weak, setter=ne_et_AOP_pre_setCell:) UICollectionViewCell *ne_et_AOP_pre_cell;
@end
@implementation UICollectionView (EventTracingAOP)

- (void)ne_et_collectionView_reloadData {
    [[NEEventTracingEngine sharedInstance] traverse:self];
    [self ne_et_collectionView_reloadData];
}
- (void)ne_et_collectionView_insertSections:(NSIndexSet *)sections {
    [[NEEventTracingEngine sharedInstance] traverse:self];
    [self ne_et_collectionView_insertSections:sections];
}
- (void)ne_et_collectionView_deleteSections:(NSIndexSet *)sections {
    [[NEEventTracingEngine sharedInstance] traverse:self];
    [self ne_et_collectionView_deleteSections:sections];
}
- (void)ne_et_collectionView_reloadSections:(NSIndexSet *)sections {
    [[NEEventTracingEngine sharedInstance] traverse:self];
    [self ne_et_collectionView_reloadSections:sections];
}
- (void)ne_et_collectionView_insertItemsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths {
    [[NEEventTracingEngine sharedInstance] traverse:self];
    [self ne_et_collectionView_insertItemsAtIndexPaths:indexPaths];
}
- (void)ne_et_collectionView_deleteItemsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths {
    [[NEEventTracingEngine sharedInstance] traverse:self];
    [self ne_et_collectionView_deleteItemsAtIndexPaths:indexPaths];
}
- (void)ne_et_collectionView_reloadItemsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths {
    [[NEEventTracingEngine sharedInstance] traverse:self];
    [self ne_et_collectionView_reloadItemsAtIndexPaths:indexPaths];
}

- (void)ne_et_AOP_pre_setCell:(UITableViewCell *)ne_et_AOP_pre_cell {
    [self bk_weaklyAssociateValue:ne_et_AOP_pre_cell withKey:@selector(ne_et_AOP_pre_cell)];
}
- (UICollectionViewCell *)ne_et_AOP_pre_cell {
    return [self bk_associatedValueForKey:_cmd];
}
@end

@interface NEEventTracingUIScrollViewAOP ()
<
UIScrollViewDelegate,
UITableViewDelegate,
UICollectionViewDelegate
>

@property(nonatomic, strong) NSMapTable<UIScrollView *, NSDictionary *> *esEventEnableScrollViews;
@end
#pragma mark - AOP
@implementation NEEventTracingUIScrollViewAOP

NEEventTracingAOPInstanceImp

- (instancetype)init {
    self = [super init];
    if (self) {
        _esEventEnableScrollViews = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsWeakMemory valueOptions:NSPointerFunctionsCopyIn];
    }
    return self;
}

- (void)inject {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // UIScrollView
        [UIScrollView jr_swizzleMethod:@selector(setDelegate:) withMethod:@selector(ne_et_scrollView_setDelegate:) error:nil];
    });
}

- (void)asyncInject {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // UITableView
        [UITableView jr_swizzleMethod:@selector(reloadData) withMethod:@selector(ne_et_tableView_reloadData) error:nil];
        [UITableView jr_swizzleMethod:@selector(insertSections:withRowAnimation:) withMethod:@selector(ne_et_tableView_insertSections:withRowAnimation:) error:nil];
        [UITableView jr_swizzleMethod:@selector(deleteSections:withRowAnimation:) withMethod:@selector(ne_et_tableView_deleteSections:withRowAnimation:) error:nil];
        [UITableView jr_swizzleMethod:@selector(reloadSections:withRowAnimation:) withMethod:@selector(ne_et_tableView_reloadSections:withRowAnimation:) error:nil];
        [UITableView jr_swizzleMethod:@selector(insertRowsAtIndexPaths:withRowAnimation:) withMethod:@selector(ne_et_tableView_insertRowsAtIndexPaths:withRowAnimation:) error:nil];
        [UITableView jr_swizzleMethod:@selector(deleteRowsAtIndexPaths:withRowAnimation:) withMethod:@selector(ne_et_tableView_deleteRowsAtIndexPaths:withRowAnimation:) error:nil];
        [UITableView jr_swizzleMethod:@selector(reloadRowsAtIndexPaths:withRowAnimation:) withMethod:@selector(ne_et_tableView_reloadRowsAtIndexPaths:withRowAnimation:) error:nil];
        
        // UICollectionView
        [UICollectionView jr_swizzleMethod:@selector(reloadData) withMethod:@selector(ne_et_collectionView_reloadData) error:nil];
        [UICollectionView jr_swizzleMethod:@selector(insertSections:) withMethod:@selector(ne_et_collectionView_insertSections:) error:nil];
        [UICollectionView jr_swizzleMethod:@selector(deleteSections:) withMethod:@selector(ne_et_collectionView_deleteSections:) error:nil];
        [UICollectionView jr_swizzleMethod:@selector(reloadSections:) withMethod:@selector(ne_et_collectionView_reloadSections:) error:nil];
        [UICollectionView jr_swizzleMethod:@selector(insertItemsAtIndexPaths:) withMethod:@selector(ne_et_collectionView_insertItemsAtIndexPaths:) error:nil];
        [UICollectionView jr_swizzleMethod:@selector(deleteItemsAtIndexPaths:) withMethod:@selector(ne_et_collectionView_deleteItemsAtIndexPaths:) error:nil];
        [UICollectionView jr_swizzleMethod:@selector(reloadItemsAtIndexPaths:) withMethod:@selector(ne_et_collectionView_reloadItemsAtIndexPaths:) error:nil];
    });
}

#pragma mark - NEEventTracingVTreeNodeImpressObserver
- (void)view:(UIView *)view didImpressendWithEvent:(NSString *)event duration:(NSTimeInterval)duration node:(NEEventTracingVTreeNode *)node inVTree:(NEEventTracingVTree *)VTree {
    NSArray<UIScrollView *> *scrollViews = nil;
    if ([view isKindOfClass:UIScrollView.class]) {
        scrollViews = @[(UIScrollView *)view];
    } else {
        scrollViews = (NSArray<UIScrollView *> *)[[[view.ne_et_pipEventViews objectForKey:NE_ET_EVENT_ID_E_SLIDE] allObjects] bk_select:^BOOL(UIView *obj) {
            return [obj isKindOfClass:UIScrollView.class];
        }];
    }
    
    [scrollViews enumerateObjectsUsingBlock:^(UIScrollView * _Nonnull scrollView, NSUInteger idx, BOOL * _Nonnull stop) {
        if (![[self.esEventEnableScrollViews objectForKey:scrollView] objectForKey:@"beginOffset"]) {
            return;
        }
        
        [self.esEventEnableScrollViews setObject:@{} forKey:scrollView];
        
        NEEventTracingEventAction *action = [NEEventTracingEventAction actionWithEvent:NE_ET_EVENT_ID_E_SLIDE view:scrollView];
        action.params = [self _paramsForESEventWithScrollView:scrollView].copy;
        [action setupNode:node VTree:VTree];
        
        [[(NEEventTracingContext *)[NEEventTracingEngine sharedInstance].context eventEmitter] consumeEventAction:action forceInCurrentVTree:YES];
    }];
}

#pragma mark - UIScrollViewDelegate AOP Methods
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
//    if (!NE_ET_isPageOrElement(scrollView) && !NE_ET_isHasSubNodes(scrollView)) {
//        return;
//    }
//
    [scrollView ne_et_didScrollWithContentOffset:scrollView.contentOffset];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if (![self.esEventEnableScrollViews.keyEnumerator.allObjects containsObject:scrollView]) {
        return;
    }
    
    [self.esEventEnableScrollViews setObject:@{
        @"beginOffset": [NSValue valueWithCGPoint:scrollView.contentOffset]
    } forKey:scrollView];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    [scrollView ne_et_resetThrottle];
    [[NEEventTracingEngine sharedInstance] traverse:scrollView];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        [scrollView ne_et_resetThrottle];
        [[NEEventTracingEngine sharedInstance] traverse:scrollView];
        
        [self _doEmitESEventIfNeededForScrollView:scrollView];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [scrollView ne_et_resetThrottle];
    [[NEEventTracingEngine sharedInstance] traverse:scrollView];
    
    [self _doEmitESEventIfNeededForScrollView:scrollView];
}

- (void)scrollViewDidScrollToTop:(UIScrollView *)scrollView {
    [scrollView ne_et_resetThrottle];
    [[NEEventTracingEngine sharedInstance] traverse:scrollView];
}

#pragma mark - UITableViewDelegate AOP Methods
- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    [[NEEventTracingEngine sharedInstance] traverse:cell];
}
- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    [cell ne_et_tryRefreshDynamicParamsCascadeSubViews];
    [[NEEventTracingEngine sharedInstance] traverse:cell];
}

// pre
- (void)preCallTableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // observers => pre
    [[[NEEventTracingClickMonitor sharedInstance] observersForView:tableView] enumerateObjectsUsingBlock:^(id<NEEventTracingClickObserver>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj respondsToSelector:@selector(clickMonitor:tableView:willSelectedRowAtIndexPath:)]) {
            [(id<NEEventTracingClickTableCellDidSelectedObserver>)obj clickMonitor:[NEEventTracingClickMonitor sharedInstance] tableView:tableView willSelectedRowAtIndexPath:indexPath];
        }
    }];
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    tableView.ne_et_AOP_pre_cell = cell;
    
    [[NEEventTracingEngine sharedInstance] AOP_preLogWithEvent:NE_ET_EVENT_ID_E_CLCK view:cell eventAction:^(NEEventTracingEventActionConfig * _Nonnull config) {
        config.useForRefer = YES;
    }];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    UITableViewCell *AOP_pre_cell = tableView.ne_et_AOP_pre_cell;
    tableView.ne_et_AOP_pre_cell = nil;
    
    if (AOP_pre_cell == nil) {
        ETLogE(@"AOP.after", @"在AOP.after 时机 AOP_pre_cell 不应该为空");
    } else if(AOP_pre_cell != cell) {
        ETLogW(@"AOP.after", @"在AOP.after 时机 AOP_pre_cell 跟 `[tableView cellForRowAtIndexPath:indexPath]` 获取的cell不一致，业务方在AOP.handler中向前插入/删除，或者reload导致");
    }
    
    [[NEEventTracingEngine sharedInstance] AOP_logWithEvent:NE_ET_EVENT_ID_E_CLCK view:(AOP_pre_cell ?: cell) params:nil eventAction:^(NEEventTracingEventActionConfig * _Nonnull config) {
        config.useForRefer = YES;
    }];
    
    // observers => after
    [[[NEEventTracingClickMonitor sharedInstance] observersForView:tableView] enumerateObjectsUsingBlock:^(id<NEEventTracingClickObserver>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj respondsToSelector:@selector(clickMonitor:tableView:didSelectedRowAtIndexPath:)]) {
            [(id<NEEventTracingClickTableCellDidSelectedObserver>)obj clickMonitor:[NEEventTracingClickMonitor sharedInstance] tableView:tableView didSelectedRowAtIndexPath:indexPath];
        }
    }];
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    [[NEEventTracingEngine sharedInstance] AOP_logWithEvent:NE_ET_EVENT_ID_E_CLCK view:[tableView cellForRowAtIndexPath:indexPath] params:nil eventAction:^(NEEventTracingEventActionConfig * _Nonnull config) {
        config.useForRefer = YES;
    }];
}

#pragma mark - UICollectionViewDelegate AOP Methods
- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    [[NEEventTracingEngine sharedInstance] traverse:cell];
}
- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    [cell ne_et_tryRefreshDynamicParamsCascadeSubViews];
    [[NEEventTracingEngine sharedInstance] traverse:cell];
}

// pre
- (void)preCallCollectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    // observers => pre
    [[[NEEventTracingClickMonitor sharedInstance] observersForView:collectionView] enumerateObjectsUsingBlock:^(id<NEEventTracingClickObserver>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj respondsToSelector:@selector(clickMonitor:collectionView:willSelectedItemAtIndexPath:)]) {
            [(id<NEEventTracingClickCollectionCellDidSelectedObserver>)obj clickMonitor:[NEEventTracingClickMonitor sharedInstance] collectionView:collectionView willSelectedItemAtIndexPath:indexPath];
        }
    }];
    
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    collectionView.ne_et_AOP_pre_cell = cell;
    
    [[NEEventTracingEngine sharedInstance] AOP_preLogWithEvent:NE_ET_EVENT_ID_E_CLCK view:cell eventAction:^(NEEventTracingEventActionConfig * _Nonnull config) {
        config.useForRefer = YES;
    }];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    UICollectionViewCell *AOP_pre_cell = collectionView.ne_et_AOP_pre_cell;
    collectionView.ne_et_AOP_pre_cell = nil;
    
    if (AOP_pre_cell == nil) {
        ETLogE(@"AOP.after", @"在AOP.after 时机 AOP_pre_cell 不应该为空");
    } else if(AOP_pre_cell != cell) {
        ETLogW(@"AOP.after", @"在AOP.after 时机 AOP_pre_cell 跟 `[tableView cellForRowAtIndexPath:indexPath]` 获取的cell不一致，业务方在AOP.handler中向前插入/删除，或者reload导致");
    }
    
    [[NEEventTracingEngine sharedInstance] AOP_logWithEvent:NE_ET_EVENT_ID_E_CLCK view:(AOP_pre_cell ?: cell) params:nil eventAction:^(NEEventTracingEventActionConfig * _Nonnull config) {
        config.useForRefer = YES;
    }];
    
    // observers => after
    [[[NEEventTracingClickMonitor sharedInstance] observersForView:collectionView] enumerateObjectsUsingBlock:^(id<NEEventTracingClickObserver>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj respondsToSelector:@selector(clickMonitor:collectionView:didSelectedItemAtIndexPath:)]) {
            [(id<NEEventTracingClickCollectionCellDidSelectedObserver>)obj clickMonitor:[NEEventTracingClickMonitor sharedInstance] collectionView:collectionView didSelectedItemAtIndexPath:indexPath];
        }
    }];
}

#pragma mark - Private methods
- (void)_doEmitESEventIfNeededForScrollView:(UIScrollView *)scrollView {
    if ([[self.esEventEnableScrollViews objectForKey:scrollView] objectForKey:@"beginOffset"] != nil) {
        [self _doESEventForScrollView:scrollView];
        
        [self.esEventEnableScrollViews setObject:@{} forKey:scrollView];
    }
}

- (void)_doESEventForScrollView:(UIScrollView *)scrollView {
    NSDictionary<NSString *,NSString *> *params = [self _paramsForESEventWithScrollView:scrollView];
    
    UIView *pipFixedView = [scrollView.ne_et_pipEventToView objectForKey:NE_ET_EVENT_ID_E_SLIDE] ?: scrollView;
    [[NEEventTracingEngine sharedInstance] AOP_logWithEvent:NE_ET_EVENT_ID_E_SLIDE
                                                       view:pipFixedView
                                                     params:params];
}

- (NSDictionary<NSString *,NSString *> *)_paramsForESEventWithScrollView:(UIScrollView *)scrollView {
    CGPoint dragBeginOffset = [[[self.esEventEnableScrollViews objectForKey:scrollView] objectForKey:@"beginOffset"] CGPointValue];
    CGPoint currentOffset = scrollView.contentOffset;
    UIEdgeInsets insets = scrollView.contentInset;
    UIEdgeInsets adjustedContentInset = UIEdgeInsetsZero;
    if (@available(iOS 11, *)) {
        adjustedContentInset = scrollView.adjustedContentInset;
    }
    
    NSDictionary *paramsValue = @{
        @"offset": @{
            @"x": @(currentOffset.x - dragBeginOffset.x),
            @"y": @(currentOffset.y - dragBeginOffset.y)
        },
        @"destination": @{
            @"x": @(currentOffset.x + insets.left + adjustedContentInset.left),
            @"y": @(currentOffset.y + insets.top + adjustedContentInset.top)
        },
        @"size": @{
            @"width": @(scrollView.frame.size.width),
            @"height": @(scrollView.frame.size.height)
        }
    };
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:paramsValue options:kNilOptions error:nil];
    NSString *paramsValueString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    return @{ @"es_params": paramsValueString ?: @"" };
}

@end

/// MARK: _es event enable
@implementation UIScrollView (EventTracingES)

- (BOOL)ne_et_isESEventEnable {
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}
- (void)ne_et_setESEventEnable:(BOOL)ne_et_esEventEnable {
    objc_setAssociatedObject(self, @selector(ne_et_isESEventEnable), @(ne_et_esEventEnable), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    if (ne_et_esEventEnable) {
        [[NEEventTracingUIScrollViewAOP AOPInstance].esEventEnableScrollViews setObject:@{} forKey:self];
        [self ne_et_addImpressObserver:[NEEventTracingUIScrollViewAOP AOPInstance]];
        [[self.ne_et_pipEventToView objectForKey:NE_ET_EVENT_ID_E_SLIDE] ne_et_addImpressObserver:[NEEventTracingUIScrollViewAOP AOPInstance]];
    } else {
        [[NEEventTracingUIScrollViewAOP AOPInstance].esEventEnableScrollViews removeObjectForKey:self];
        [self ne_et_removeImpressObserver:[NEEventTracingUIScrollViewAOP AOPInstance]];
        [[self.ne_et_pipEventToView objectForKey:NE_ET_EVENT_ID_E_SLIDE] ne_et_removeImpressObserver:[NEEventTracingUIScrollViewAOP AOPInstance]];
    }
}

@end
