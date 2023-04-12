//
//  EventTracingEngine.m
//  BlocksKit
//
//  Created by dl on 2021/2/4.
//

#import "EventTracingEngine.h"
#import "EventTracingEngine+Private.h"
#import "EventTracingDefines.h"
#import "EventTracingContext+Private.h"
#import "UIView+EventTracingPrivate.h"

#import "EventTracingAOPManager.h"
#import "EventTracingAppLicycleAOP.h"
#import "EventTracingUIControlAOP.h"
#import "EventTracingUIScrollViewAOP.h"
#import "EventTracingUITabbarAOP.h"
#import "EventTracingUIViewAOP.h"
#import "EventTracingUIViewControllerAOP.h"
#import "EventTracingUIAlertControllerAOP.h"

#import <BlocksKit/BlocksKit.h>
#import "NSArray+ETEnumerator.h"
#import "EventTracingVTree+Private.h"
#import "EventTracingOutputFlattenFormatter.h"
#import "EventTracingContext+Private.h"
#import "EventTracingEventOutput+Private.h"
#import "EventTracingVTreeNode+Private.h"
#import "EventTracingInternalLog.h"

@implementation EventTracingEngine
@synthesize incrementalVTreeWhenScrollEnable = _incrementalVTreeWhenScrollEnable;

#pragma mark - Public: init & lifecycle methods
+ (instancetype)sharedInstance {
    static EventTracingEngine *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[EventTracingEngine alloc] init];
    });
    return instance;
}

- (void) startWithContextBuilder:(void(^NS_NOESCAPE)(id<EventTracingContextBuilder> builder))block {
    EventTracingContext *context = [[EventTracingContext alloc] init];
    _ctx = context;
    _ctx.engine = self;
    
    [_ctx registeFormatter:EventTracingOutputFlattenFormatter.new];
    
    [context.eventOutput configStaticPublicParams:@{
        ET_REFER_KEY_SESSID: (_ctx.sessid ?: @""),
        ET_REFER_KEY_SIDREFER: (_ctx.sidrefer ?: @"")
    } withParamGuard:NO];
    
    !block ?: block(context);
    
    context.eventEmitter.delegate = self;
    context.traversalRunner.delegate = self;
    [context.traversalRunner runWithRunloopMode:NSDefaultRunLoopMode];
    
    if ([context.extraConfigurationProvider respondsToSelector:@selector(needIncreaseActseqLogEvents)]) {
        context.needIncreaseActseqLogEvents = [context.extraConfigurationProvider needIncreaseActseqLogEvents];
    }
    
    if ([context.extraConfigurationProvider respondsToSelector:@selector(needStartHsreferOids)]) {
        context.needStartHsreferOids = [context.extraConfigurationProvider needStartHsreferOids];
    }
    
    [context markRunState:YES];
    [self _doAOP];
}

- (void)stop {
    [_ctx.traverser cleanAssociationForPreVTree:_ctx.eventEmitter.lastVTree.copy];
    
    [_ctx.traversalRunner stop];
    [_ctx.eventEmitter flush];
    [_ctx markRunState:NO];
}

#pragma mark - Traverse
- (void)traverse {
    [self traverse:nil];
}

- (void)enableIncrementalVTreeWhenScroll {
    _incrementalVTreeWhenScrollEnable = YES;
}

- (void)disableIncrementalVTreeWhenScroll {
    _incrementalVTreeWhenScrollEnable = NO;
}

#pragma mark - Params
- (void)addCurrentActivePublicParams:(NSDictionary<NSString *,NSString *> *)publicParams {
    [_ctx.eventOutput configCurrentActivePublicParams:publicParams withParamGuard:YES];
}

- (void)addCurrentActiveDeeplinkReferPublicParam:(NSString *)value {
    if (value.length == 0) {
        return;
    }
    
    [self addCurrentActivePublicParams:@{ @"g_dprefer": value }];
}

- (NSDictionary *)publicParamsForViewController:(UIViewController * _Nullable)viewController {
    return [self publicParamsForView:viewController.p_et_view];
}
- (NSDictionary *)publicParamsForView:(UIView * _Nullable)view {
    return [_ctx.eventOutput publicParamsForEvent:nil node:view.et_currentVTreeNode inVTree:view.et_currentVTreeNode.VTree];
}

- (NSDictionary *)fulllyParamsForViewController:(UIViewController * _Nullable)viewController {
    return [self fulllyParamsForView:viewController.p_et_view];
}
- (NSDictionary *)fulllyParamsForView:(UIView * _Nullable)view {
    return [_ctx.eventOutput fulllyParamsForEvent:nil contextParams:nil logActionParams:nil node:view.et_currentVTreeNode inVTree:view.et_currentVTreeNode.VTree];
}

#pragma mark - EventTracingAppLifecycleProcotol
- (void)appViewController:(UIViewController *)controller changedToAppear:(BOOL)appear {
    [_ctx appViewController:controller changedToAppear:appear];
    
    if (!controller.et_isPage) {
        return;
    }
    
    [self traverse];
}

- (void)appDidBecomeActive {
    BOOL isAppInActive = _ctx.isAppInActive;
    [_ctx appDidBecomeActive];
    
    if (!isAppInActive) {
        [self _doOutputAppInLog];
    }
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self->_ctx.eventOutput outputEventWithoutNode:ET_EVENT_ID_APP_ACTIVE contextParams:nil];
    });
    
    [self _doTraverse];
}

- (void)appWillEnterForeground {
    BOOL isAppInActive = _ctx.isAppInActive;
    
    [_ctx appWillEnterForeground];
    [_ctx.traversalRunner resume];
    
    if (!isAppInActive) {
        [self _doOutputAppInLog];
    }
    
    [self _doTraverse];
}

- (void)appDidEnterBackground {
    BOOL isAppInActive = _ctx.isAppInActive;
    
    [_ctx appDidEnterBackground];
    [_ctx.traversalRunner pause];
    [_ctx.eventOutput removeCurrentActivePublicParmas];
    
    if (isAppInActive) {
        [self _doOutputAppOutLog];
    }
    
    [self _doTraverse];
}

- (void)appDidTerminate {
    [_ctx appDidTerminate];
    [_ctx.eventEmitter flush];
}

#pragma mark - Private Category Methods
- (NSUInteger)pgstepIncreased {
    return [self->_ctx pgstepIncreased];
}

- (NSUInteger)actseqIncreased {
    return [self->_ctx actseqIncreased];
}

- (void)refreshAppInActiveState {
    [self->_ctx refreshAppInActiveState];
}

#pragma mark - EventTracingTraversalRunnerDelegate
- (void)traversalRunner:(EventTracingTraversalRunner *)runner runWithRunModeMatched:(BOOL)runModeMatched {
    if (![self _couldRunTraverse]) {
        return;
    }
    
    // 全量生成VTree
    if (runModeMatched) {
        [self traverseImmediatelyIfNeeded];
    }
    // 列表滚动模式，增量生成VTree
    else {
        [self _doTraverseForCommonRunloopModes];
    }
}

#pragma mark - traversal
- (BOOL)_couldRunTraverse {
    if (!_ctx.started) {
        return NO;
    }
    
    return !_ctx.isAppInActive || _ctx.isAppInActive;
}

- (void)_doTraverseForCommonRunloopModes {
    if (!self.incrementalVTreeWhenScrollEnable) {
        return;
    }
    
    NSArray<UIScrollView *> *scrollViews = self.stockedTraverseScrollViews.allObjects;
    [self.stockedTraverseScrollViews removeAllObjects];
    
    if (scrollViews.count == 0) {
        return;
    }
    
    [self _doTaskWithCollectPerforanceData:@"IncrementalVTree" task:^EventTracingVTree *{
        EventTracingVTree *lastVTree = _ctx.eventEmitter.lastVTree;
        EventTracingVTree *VTree = [_ctx.traverser incrementalGenerateVTreeFrom:lastVTree
                                                                          views:scrollViews];
        
        // 没有真正生成新的VTree
        if (VTree == lastVTree) {
            return VTree;
        }
        
        [_ctx.traverser cleanAssociationForPreVTree:lastVTree];
        [_ctx.traverser associateNodeToViewForVTree:VTree];
        
        [VTree markVTreeVisible:_ctx.isAppInActive];
        [_ctx.eventEmitter consumeVTree:VTree];
        [self flushStockedActionsIfNeeded:VTree];
        
        return VTree;
    }];
}

- (void)traverseImmediatelyIfNeeded {
    // 1. 穿透
    if (self.stockedTraverseActionRecord.passthrough) {
        [self.stockedTraverseActionRecord reset];
        
        // 全量生成 VTree 后，清空待处理的滚动action
        [self.stockedTraverseScrollViews removeAllObjects];
        
        [self _doTraverse];
        return;
    }

    // 逆着遍历
    NSArray<EventTracingTraverseAction *> *stockedTraverseActions = [[self.stockedTraverseActionRecord.actions reverseObjectEnumerator] allObjects];
    [self.stockedTraverseActionRecord reset];

    // 全量生成 VTree 后，清空待处理的滚动action
    [self.stockedTraverseScrollViews removeAllObjects];
    
    if (stockedTraverseActions.count == 0) {
        return;
    }
    
    BOOL needTraverse = [stockedTraverseActions bk_any:^BOOL(EventTracingTraverseAction *obj) {
        if (obj.view == nil) {
            return NO;
        }
        
        UIView *view = obj.view;
        
        BOOL needsRunTraversal = YES;
        
        if (obj.ignoreViewInvisible) {
            needsRunTraversal = ET_isPageOrElement(view) || ET_isHasSubNodes(view);
        } else {
            needsRunTraversal = [view et_isSimpleVisible] && [view et_logicalVisible] && (ET_isPageOrElement(view) || ET_isHasSubNodes(view));
        }
        
        return needsRunTraversal;
    }];
    
    if (!needTraverse) {
        return;
    }
    
    [self _doTraverse];
}

- (void)_doTraverse {
    [self _doTaskWithCollectPerforanceData:@"TotalVTree" task:^EventTracingVTree *{
        EventTracingVTree *VTree = [_ctx.traverser totalGenerateVTreeFromWindows];
        [_ctx.traverser cleanAssociationForPreVTree:_ctx.eventEmitter.lastVTree];
        [_ctx.traverser associateNodeToViewForVTree:VTree];
        
        [VTree markVTreeVisible:_ctx.isAppInActive];
        [_ctx.eventEmitter consumeVTree:VTree];
        [self flushStockedActionsIfNeeded:VTree];
        
        return VTree;
    }];
}

- (void)_doTaskWithCollectPerforanceData:(NSString *)tag task:(EventTracingVTree *(^ NS_NOESCAPE)(void))block {
    if (![self.context.VTreePerformanceObserver respondsToSelector:@selector(didGenerateVTree:tag:idx:cost:ave:min:max:)]) {
        EventTracingVTree *VTree = block();
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [self _doCheckExceptionsInVTree:VTree];
        });
        
        return;
    }
    
    static NSMutableDictionary<NSString *, NSDictionary<NSString *, NSNumber *> *> *recordInfoMap;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        recordInfoMap = [@{} mutableCopy];
    });
    
    NSDictionary<NSString *, NSNumber *> *recordInfo = [recordInfoMap objectForKey:tag];
        
    NSInteger count = [[recordInfo objectForKey:@"count"] integerValue];
    CGFloat max = [[recordInfo objectForKey:@"max"] floatValue];
    CGFloat min = [[recordInfo objectForKey:@"min"] floatValue];
    CGFloat sum = [[recordInfo objectForKey:@"sum"] floatValue];
    
    CFTimeInterval begin = CACurrentMediaTime() * 1000.f;
    EventTracingVTree *VTree = block();
    CFTimeInterval cost = CACurrentMediaTime() * 1000.f - begin;
    
    count ++;
    max = MAX(max, cost);
    min = min > 0 ? MIN(min, cost) : cost;
    sum += cost;
    CGFloat ave = sum / count;
    
    [self.context.VTreePerformanceObserver didGenerateVTree:VTree tag:tag idx:count cost:cost ave:ave min:min max:max];
    
    recordInfo = @{ @"count": @(count), @"max": @(max), @"min": @(min), @"sum": @(sum) };
    [recordInfoMap setObject:recordInfo forKey:tag];
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self _doCheckExceptionsInVTree:VTree];
    });
}

// Check Exceptions in VTree
- (void)_doCheckExceptionsInVTree:(EventTracingVTree *)VTree {
    id<EventTracingExceptionDelegate> exceptionDelegate = [EventTracingEngine sharedInstance].context.exceptionInterface;
    BOOL needCheckNodeUnique = [exceptionDelegate respondsToSelector:@selector(internalExceptionKey:code:message:node:shouldNotEqualToOther:)];
    BOOL needCheckNodeSPMUnique = [exceptionDelegate respondsToSelector:@selector(internalExceptionKey:code:message:node:spmShouldNotEqualToOther:)];
    if (!needCheckNodeUnique && !needCheckNodeSPMUnique) {
        return;
    }
    
    NSMutableDictionary<NSString *, EventTracingVTreeNode *> *allNodes = @{}.mutableCopy;
    NSMutableDictionary<NSString *, EventTracingVTreeNode *> *allSpms = @{}.mutableCopy;
    NSMutableArray<NSString *> *checkedKeys = @[].mutableCopy;
    [VTree.rootNode.subNodes et_enumerateObjectsUsingBlock:^NSArray<EventTracingVTreeNode *> * _Nonnull(EventTracingVTreeNode * _Nonnull node, BOOL * _Nonnull stop) {
        
        // identifier unique
        if (needCheckNodeUnique) {
            NSString *diffIdentifier = (NSString *)[node et_diffIdentifier];
            EventTracingVTreeNode *otherNode = [allNodes objectForKey:diffIdentifier];
            if (![checkedKeys containsObject:diffIdentifier] && otherNode != nil) {
                NSString *errmsg = [NSString stringWithFormat:@"VTreeNode is not unique, NodeDiffIdentifier: %@", diffIdentifier];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [exceptionDelegate internalExceptionKey:@"NodeNotUnique"
                                                       code:EventTracingExceptionCodeNodeNotUnique
                                                    message:errmsg
                                                       node:node
                                      shouldNotEqualToOther:otherNode];
                });
                ETLogE(@"VTreeNode", errmsg);
                
                [checkedKeys addObject:diffIdentifier];
            }
            [allNodes setObject:node forKey:diffIdentifier];
        }
        
        // spm unique
        if (needCheckNodeSPMUnique) {
            NSString *spm = [node spm];
            EventTracingVTreeNode *otherNode = [allSpms objectForKey:spm];
            if (![checkedKeys containsObject:spm] && otherNode != nil) {
                NSString *errmsg = [NSString stringWithFormat:@"VTreeNode _spm is not unique, _spm: %@", spm];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [exceptionDelegate internalExceptionKey:@"SPMNotUnique"
                                                       code:EventTracingExceptionCodeNodeSPMNotUnique
                                                    message:errmsg
                                                       node:node
                                   spmShouldNotEqualToOther:otherNode];
                });
                ETLogE(@"VTreeNode", errmsg);
                
                [checkedKeys addObject:spm];
            }
            [allSpms setObject:node forKey:spm];
        }
        
        return node.subNodes;
    }];
}

- (void)_doOutputAppInLog {
    [_ctx.eventOutput outputEventWithoutNode:ET_EVENT_ID_APP_IN contextParams:nil];
}

- (void)_doOutputAppOutLog {
    NSInteger duration = ([[NSDate date] timeIntervalSince1970] - _ctx.appLastAtForegroundTime) * 1000;
    [_ctx.eventOutput outputEventWithoutNode:ET_EVENT_ID_APP_OUT contextParams:@{
        @"_duration": @(duration).stringValue
    }];
}

#pragma mark - Other Private Methods
- (void)_doAOP {
    // AOP
    [@[
        EventTracingAppLicycleAOP.class,
        EventTracingUIControlAOP.class,
        EventTracingUIScrollViewAOP.class,
        EventTracingUITabbarAOP.class,
        EventTracingUIViewAOP.class,
        EventTracingUIViewControllerAOP.class,
        EventTracingUIAlertControllerAOP.class
    ] enumerateObjectsUsingBlock:^(Class _Nonnull clz, NSUInteger idx, BOOL * _Nonnull stop) {
        [[EventTracingAOPManager defaultManager] registeAOPCls:clz];
    }];
    
    [[EventTracingAOPManager defaultManager] fire];
}

#pragma mark - getters & setters
- (BOOL)started {
    return self.context.started;
}

- (id<EventTracingContext>)context {
    return _ctx;
}

@end

@implementation EventTracingEngine (VTreeObserver)
- (void)addVTreeObserver:(id<EventTracingVTreeObserver>)observer {
    [self.ctx addVTreeObserver:observer];
}

- (void)removeVTreeObserver:(id<EventTracingVTreeObserver>)observer {
    [self.ctx removeVTreeObserver:observer];
}
@end
