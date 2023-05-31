//
//  NEEventTracingEventEmitter.m
//  NEEventTracing
//
//  Created by dl on 2021/3/16.
//

#import "NEEventTracingEventEmitter.h"
#import <BlocksKit/BlocksKit.h>

#import "NEEventTracingDefines.h"
#import "NEEventTracingDiff.h"
#import "NSArray+ETEnumerator.h"

#import "NEEventTracingVTree.h"
#import "NEEventTracingVTree+Sync.h"
#import "NEEventTracingVTree+Visible.h"
#import "NEEventTracingVTreeNode+Private.h"
#import "NEEventTracingEngine+Private.h"

#import "UIView+EventTracingNodeImpressObserver.h"
#import "NEEventTracingEventActionConfig+Private.h"

#define LOCK        dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
#define UNLOCK      dispatch_semaphore_signal(_lock);

@interface NEEventTracingEventEmitter () {
    NEEventTracingVTree * _Nullable _lastVTree;
}
@property(nonnull, strong) dispatch_semaphore_t lock;
@property(nonatomic, strong) NSHashTable<id<NEEventTracingVTreeObserver>> *VTreeObservers;
@end

@implementation NEEventTracingEventEmitter

- (instancetype)init {
    self = [super init];
    if (self) {
        _lock = dispatch_semaphore_create(1);
        _VTreeObservers = [NSHashTable hashTableWithOptions:NSPointerFunctionsWeakMemory];
        _referCollector = [[NEEventTracingEventReferCollector alloc] init];
    }
    return self;
}

- (void) consumeVTree:(NEEventTracingVTree *)VTree {
    [self _doConsumeVTreeIfNeeded:VTree];
}

- (void)flush {
    [self consumeVTree:[NEEventTracingVTree emptyVTree]];
}

- (void)consumeEventAction:(NEEventTracingEventAction *)action {
    [self consumeEventAction:action forceInCurrentVTree:NO];
}

- (void)consumeEventAction:(NEEventTracingEventAction *)action forceInCurrentVTree:(BOOL)forceInCurrentVTree {
    [self _doConsumeAction:action];
    
    if (action.VTree != _lastVTree && forceInCurrentVTree) {
        NEEventTracingVTree *VTree = action.VTree;
        NEEventTracingVTreeNode *node = action.node;
        [_lastVTree increaseActseqFromOtherTree:VTree node:node];
    }
}

#pragma mark - NEEventTracingContextVTreeObserverBuilder
- (void)addVTreeObserver:(id<NEEventTracingVTreeObserver>)observer {
    [_VTreeObservers addObject:observer];
}

- (void)removeVTreeObserver:(id<NEEventTracingVTreeObserver>)observer {
    [_VTreeObservers removeObject:observer];
}

- (void)removeAllVTreeObservers {
    [_VTreeObservers removeAllObjects];
}

#pragma mark - private: consume VTree
- (void)_doConsumeVTreeIfNeeded:(NEEventTracingVTree *)VTree {
    NEEventTracingVTree *lastVTree = self.lastVTree;
    if (!VTree || VTree.stable || VTree == lastVTree) {
        return;
    }
    
    // 1. VTree 遮挡
    [self _doApplySubpageOcclusionForVTree:VTree];
    
    // 2. 曝光前，先迁移VTree关键属性 _pgrefer, _psrefer, _actseq, _pgstep
    if (lastVTree.isVisible && VTree.isVisible) {
        [lastVTree syncToVTree:VTree];
    }
    
    // 3. 回调出去，VTree已经完了遮挡
    [self _doCallObserversSel:@selector(didGenerateVTree:lastVTree:hasChanges:) block:^(id<NEEventTracingVTreeObserver>  _Nonnull obj) {
        BOOL equal = VTree == lastVTree;
        [obj didGenerateVTree:VTree lastVTree:lastVTree hasChanges:!equal];
    }];
    
    // 4. VTree 执行曝光
    NEEventTracingDiffResults *diffResults = [self _fetchDiffFromVTree:lastVTree toVTree:VTree];
    [self _doImpressWorkWithDiffResults:diffResults VTree:VTree lastVTree:lastVTree];
    
    // 5. become stable
    [VTree VTreeDidBecomeStable];
    
    // 6. 切换 lastVTree 指针
    LOCK {
        _lastVTree = VTree;
    } UNLOCK
}

#pragma mark - private: diff
- (NEEventTracingDiffResults *)_fetchDiffFromVTree:(NEEventTracingVTree *)fromVTree toVTree:(NEEventTracingVTree *)toVTree {
    BOOL(^rejectBlock)(NEEventTracingVTreeNode *) = ^BOOL(NEEventTracingVTreeNode *obj) {
        return !obj.visible;
    };
    NSArray<NEEventTracingVTreeNode *> *newArray = [toVTree.flattenNodes bk_reject:rejectBlock];
    NSArray<NEEventTracingVTreeNode *> *oldArray = [fromVTree.flattenNodes bk_reject:rejectBlock];
    NEEventTracingDiffResults *diffResults = NE_ET_DiffBetweenArray(toVTree.isVisible ? newArray : @[],
                                                               fromVTree.isVisible ? oldArray : @[]);
    return diffResults;
}

#pragma mark - private: impress & impressend
- (void)_doImpressWorkWithDiffResults:(NEEventTracingDiffResults *)diffResults
                                VTree:(NEEventTracingVTree *)VTree
                            lastVTree:(NEEventTracingVTree *)lastVTree {
    if (diffResults.hasDiffs) {
        // 曝光开始 & 曝光结束，这俩是逆着来的顺序
        NSArray<NEEventTracingVTreeNode *> *impressendNodes = [(NSArray<NEEventTracingVTreeNode *> *)diffResults.deletes reverseObjectEnumerator].allObjects;
        NSArray<NEEventTracingVTreeNode *> *impressNodes = (NSArray<NEEventTracingVTreeNode *> *)diffResults.inserts;
        
        [impressendNodes enumerateObjectsUsingBlock:^(NEEventTracingVTreeNode * _Nonnull node, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *event = node.isPageNode ? NE_ET_EVENT_ID_P_VIEW_END : NE_ET_EVENT_ID_E_VIEW_END;
            [self _doImpressendWithEvent:event node:node inVTree:lastVTree];
        }];
        
        [impressNodes enumerateObjectsUsingBlock:^(NEEventTracingVTreeNode * _Nonnull node, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *event = node.isPageNode ? NE_ET_EVENT_ID_P_VIEW : NE_ET_EVENT_ID_E_VIEW;
            [self _doImressWithEvent:event node:node inVTree:VTree];
        }];
    }
}

- (void)_doImpressendWithEvent:(NSString *)event
                          node:(NEEventTracingVTreeNode *)node
                       inVTree:(NEEventTracingVTree *)VTree {
    NSTimeInterval now = [NSDate date].timeIntervalSince1970;
    unsigned long long time = (now - node.beginTime) * 1000;
    NSDictionary *contextParams = @{ NE_ET_REFER_KEY_DURATION: @(time) };
    
    [self _doCallNodeImpressObservers:node sel:@selector(view:didImpressendWithEvent:duration:node:inVTree:) block:^(id<NEEventTracingVTreeNodeImpressObserver>  _Nonnull obj) {
        [obj view:node.view didImpressendWithEvent:event duration:time node:node inVTree:VTree];
    }];
    
    if (node.buildinEventLogDisableStrategy & NEETNodeBuildinEventLogDisableStrategyImpress
        || node.buildinEventLogDisableStrategy & NEETNodeBuildinEventLogDisableStrategyImpressend) {
        return;
    }
    
    [node refreshDynsmicParamsIfNeededForEvent:event];
    
    // go => impressend
    [self _doCallObserversSel:@selector(VTree:willImpressendNode:) block:^(id<NEEventTracingVTreeObserver>  _Nonnull obj) {
        [obj VTree:VTree willImpressendNode:node];
    }];
    
    [self _doEmitEvent:event contextParams:contextParams logActionParams:nil node:node VTree:VTree];
    
    [self _doCallObserversSel:@selector(VTree:didImpressendNode:) block:^(id<NEEventTracingVTreeObserver>  _Nonnull obj) {
        [obj VTree:VTree didImpressendNode:node];
    }];
}

- (void)_doImressWithEvent:(NSString *)event
                      node:(NEEventTracingVTreeNode *)node
                   inVTree:(NEEventTracingVTree *)VTree {
    [self _doCallNodeImpressObservers:node sel:@selector(view:willImpressWithEvent:node:inVTree:) block:^(id<NEEventTracingVTreeNodeImpressObserver>  _Nonnull obj) {
        [obj view:node.view willImpressWithEvent:event node:node inVTree:VTree];
    }];
    
    void(^didImpressBlock)(void) = ^(void) {
        [self _doCallNodeImpressObservers:node sel:@selector(view:didImpressWithEvent:node:inVTree:) block:^(id<NEEventTracingVTreeNodeImpressObserver>  _Nonnull obj) {
            [obj view:node.view didImpressWithEvent:event node:node inVTree:VTree];
        }];
    };
    if (node.buildinEventLogDisableStrategy & NEETNodeBuildinEventLogDisableStrategyImpress) {
        didImpressBlock();
        return;
    }
    
    [node refreshDynsmicParamsIfNeededForEvent:event];
    [node nodeWillImpress];
    
    // 页面曝光，需要带_actseq
    NSMutableDictionary *contextParams = [@{} mutableCopy];
    if (node.isPageNode) {
        [contextParams setObject:@(node.actseq) forKey:NE_ET_REFER_KEY_ACTSEQ];
    }
    
    // _actseq 自增后，再收集 refer action
    [_referCollector willImpressNode:node inVTree:VTree];
    
    // go => impress
    [self _doCallObserversSel:@selector(VTree:willImpressNode:) block:^(id<NEEventTracingVTreeObserver>  _Nonnull obj) {
        [obj VTree:VTree willImpressNode:node];
    }];
    
    [self _doEmitEvent:event contextParams:contextParams logActionParams:nil node:node VTree:VTree];
    
    didImpressBlock();
    [self _doCallObserversSel:@selector(VTree:didImpressNode:) block:^(id<NEEventTracingVTreeObserver>  _Nonnull obj) {
        [obj VTree:VTree didImpressNode:node];
    }];
}

#pragma mark - private: 消费 action
- (void)_doConsumeAction:(NEEventTracingEventAction *)action {
    NEEventTracingVTree *VTree = action.VTree;
    NSMutableDictionary *contextParams = [@{} mutableCopy];
    // 如果该 evnet 需要影响 actseq 自增，则需要做自增(主线程做的自增)，并且在本次打点需要带上 _actseq 埋点
    if (action.increaseActseq || action.useForRefer) {
        [contextParams setObject:@(action.node.actseq) forKey:NE_ET_REFER_KEY_ACTSEQ];
    }
    
    NEEventTracingEventActionConfig *actionConfig = [NEEventTracingEventActionConfig configWithEvent:action.event];
    actionConfig.useForRefer = action.useForRefer;
    actionConfig.increaseActseq = action.increaseActseq;
    
    [self _doCallObserversSel:@selector(VTree:willEmitEvent:onNode:actionConfig:) block:^(id<NEEventTracingVTreeObserver>  _Nonnull obj) {
        [obj VTree:VTree willEmitEvent:action.event onNode:action.node actionConfig:actionConfig];
    }];
    
    [self _doEmitEvent:action.event contextParams:contextParams logActionParams:action.params node:action.node VTree:VTree];
    
    [self _doCallObserversSel:@selector(VTree:didEmitEvent:onNode:actionConfig:) block:^(id<NEEventTracingVTreeObserver>  _Nonnull obj) {
        [obj VTree:VTree didEmitEvent:action.event onNode:action.node actionConfig:actionConfig];
    }];
}

- (void)_doEmitEvent:(NSString *)event
       contextParams:(NSDictionary * _Nullable)contextParams
     logActionParams:(NSDictionary * _Nullable)logActionParams
                node:(NEEventTracingVTreeNode *)node
               VTree:(NEEventTracingVTree *)VTree {
    if (!node) {
        return;
    }
    
    /// MARK: _hsrefer => 业务侧设置的优先级高，不覆盖
    NSMutableDictionary *mutableContextParams = [(contextParams ?: @{}) mutableCopy];
    if (![contextParams.allKeys containsObject:NE_ET_REFER_KEY_HSREFER]
        && ![logActionParams.allKeys containsObject:NE_ET_REFER_KEY_HSREFER]) {
        NSString *hsrefer = [NEEventTracingEngine sharedInstance].context.hsrefer;
        if (hsrefer.length) {
            [mutableContextParams setObject:hsrefer forKey:NE_ET_REFER_KEY_HSREFER];
        }
    }

    if ([NEEventTracingEngine sharedInstance].ctx.isNoneventOutputWithoutPageNodeEnable) {
        // 该节点向上未找到 page 节点，则该节点不会打任何埋点
        if ([node firstAncestorPageNode] == nil) {
            return;
        }
    }
    
    if ([self.delegate respondsToSelector:@selector(eventEmitter:emitEvent:contextParams:logActionParams:node:inVTree:)]) {
        [self.delegate eventEmitter:self emitEvent:event contextParams:mutableContextParams.copy logActionParams:logActionParams node:node inVTree:VTree];
    }
}

- (void)_doCallObserversSel:(SEL)sel block:(void(^)(id<NEEventTracingVTreeObserver> _Nonnull obj))block {
    [self.allVTreeObservers enumerateObjectsUsingBlock:^(id<NEEventTracingVTreeObserver>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj respondsToSelector:sel]) {
            !block ?: block(obj);
        }
    }];
}

- (void)_doCallNodeImpressObservers:(NEEventTracingVTreeNode *)node sel:(SEL)sel block:(void(^)(id<NEEventTracingVTreeNodeImpressObserver> _Nonnull obj))block {
    NSArray<id<NEEventTracingVTreeNodeImpressObserver>> *observers = [node.view ne_et_impressObservers];
    [observers enumerateObjectsUsingBlock:^(id<NEEventTracingVTreeNodeImpressObserver>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj respondsToSelector:sel]) {
            !block ?: block(obj);
        }
    }];
}

/// MARK: 子page遮挡，将被遮挡的元素剔除
- (void)_doApplySubpageOcclusionForVTree:(NEEventTracingVTree *)VTree {
    [VTree applySubpageOcclusionIfNeeded];
}

#pragma mark - getters
- (NEEventTracingVTree *)lastVTree {
    NEEventTracingVTree *VTree;
    LOCK {
        VTree = _lastVTree;
    } UNLOCK
    return VTree;
}

- (NSArray<id<NEEventTracingVTreeObserver>> *)allVTreeObservers {
    return _VTreeObservers.allObjects;
}

@end
