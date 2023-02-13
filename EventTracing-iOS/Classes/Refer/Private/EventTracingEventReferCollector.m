//
//  EventTracingEventReferCollector.m
//  EventTracing
//
//  Created by dl on 2021/4/8.
//

#import "EventTracingEventReferCollector.h"
#import "EventTracingEventReferQueue.h"
#import "EventTracingEventEmitter.h"
#import "EventTracingVTreeNode+Private.h"
#import "EventTracingDefines.h"
#import "EventTracingFormattedReferBuilder.h"
#import "EventTracingInternalLog.h"

#import "EventTracingEngine+Private.h"
#import "EventTracingContext+Private.h"

@interface EventTracingEventReferCollector ()
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *pageNodeIdentifierPsreferMap;
@end

@implementation EventTracingEventReferCollector

- (instancetype)init {
    self = [super init];
    if (self) {
        _pageNodeIdentifierPsreferMap = [@{} mutableCopy];
    }
    return self;
}

- (void)appWillEnterForeground {
    if (![self _checkIfCouldInsertBecomeActiveOrEnterForegroundRefer]) {
        return;
    }
    
    [[EventTracingEventReferQueue queue] pushEventRefer:[EventTracingFormattedEventRefer enterForegroundRefer]];
}

- (void)willImpressNode:(EventTracingVTreeNode *)node inVTree:(EventTracingVTree *)VTree {
    if (!node.isPageNode) {
        return ;
    }
    
    [self _pageNodeWillImpress:node VTree:VTree];
}

- (NSString *)psreferForNodeIdentifier:(NSString *)identifier {
    return [_pageNodeIdentifierPsreferMap objectForKey:identifier];
}

#pragma mark - private methods
- (void)_pageNodeWillImpress:(EventTracingVTreeNode *)node VTree:(EventTracingVTree *)VTree {
    EventTracingVTreeNode *rootPageNode = [node findToppestNode:YES];
    BOOL isRootPagePV = rootPageNode == node;
    
    /// MARK: _hsrefer, 两个时机:
    // _hsrefer 时机1: oids列表中的页面曝光
    NSString *hsrefer = nil;
    NSArray<NSString *> *needStartHsreferOids = [EventTracingEngine sharedInstance].ctx.needStartHsreferOids;
    if ([needStartHsreferOids containsObject:node.oid]) {
        hsrefer = ET_formattedReferForNode(node, NO).value;
    }
    
    // 只有顶层pageNode才设置 pgrefer & psrefer
    EventTracingFormattedEventRefer *refer;
    
    // _hsrefer 时机2: rootPage页面曝光，尝试从队列中取合法的 refer
    if (isRootPagePV) {
        BOOL oidMatched = NO;
        refer = [[EventTracingEventReferQueue queue] findEventReferForOid:node.oid oidMatched:&oidMatched];
        
        EventTracingFormattedEventRefer *preferedRefer = refer;
        BOOL undefinedXpath = NO;

        /// MARK: 1. 如果通过 oid 严格匹配，找到了refer，则直接使用；2. 如果找到的refer是 active refer，则也是直接使用；
        /// MARK: 否则，需要判断是否降级到 rootPage._pv refer
        ///   1. 如果匹配的 `refer -> actionTime` 比 `rootPage -> _pv -> actionTime` 还提前，则降级
        ///   2. 或者 该事件未发生在该 `rootPage` 内，则也降级
        if (!oidMatched) {
            EventTracingFormattedEventRefer *lastestRootPagePVRefer = [[EventTracingEventReferQueue queue] fetchLastestRootPagePVRefer];
            EventTracingUndefinedXpathEventRefer *lastestUndefinedXpathRefer = [[EventTracingEventReferQueue queue] undefinedXpath_fetchLastestEventRefer];
            
            // 判断该次找到的 event refer 非法
            /// MARK: 1. 找到的 event refer 比最近一次的 rootPage 曝光还要早，则此时应该降级到 rootPage 曝光
            BOOL referValid = preferedRefer.eventTime >= lastestRootPagePVRefer.eventTime;
            
            /// MARK: 2. 在一个节点触发事件之后，有一个非节点的view也触发了事件，此时需要降级到 rootPage 曝光
            referValid = referValid && lastestUndefinedXpathRefer.eventTime <= preferedRefer.eventTime;
            
            if (!referValid) {
                preferedRefer = lastestRootPagePVRefer;
                undefinedXpath = YES;
            }
        }
        
        [self _markPageNode:node
                  fromRefer:preferedRefer.formattedRefer
             undefinedXpath:undefinedXpath
                psreferMute:preferedRefer.psreferMute];
        
        /// MARK: 判断找到的该refer是否可以作为 _hsrefer
        if (preferedRefer.shouldStartHsrefer) {
            hsrefer = [preferedRefer.formattedRefer valueWithSessid:NO undefinedXpath:undefinedXpath];
        }
        
        // 每次曝光page，更新队列的曝光的RootPage页面节点
        [[EventTracingEventReferQueue queue] rootPageNodeDidImpress:node inVTree:VTree];
        
        // store psrefer
        [_pageNodeIdentifierPsreferMap setValue:node.psrefer forKey:node.identifier];
    }

    /// MARK: 获取到了合法的 _hsrefer, 则更新
    if (hsrefer.length && ![hsrefer isEqualToString:[EventTracingEventReferQueue queue].hsrefer]) {
        [self _doCallReferObserversForSel:@selector(hsreferNeedsUpdatedTo:) block:^(id<EventTracingReferObserver> observer) {
            [observer hsreferNeedsUpdatedTo:hsrefer];
        }];

        [[EventTracingEventReferQueue queue] hsreferNeedsUpdateTo:hsrefer];
    }
}

- (void)_markPageNode:(EventTracingVTreeNode *)pageNode
            fromRefer:(id<EventTracingFormattedRefer>)formattedRefer
       undefinedXpath:(BOOL)undefinedXpath
          psreferMute:(BOOL)psreferMute {
    if (!formattedRefer) {
        return;
    }

    NSString *pgrefer = [formattedRefer valueWithSessid:NO undefinedXpath:undefinedXpath];
    NSString *psrefer = [self psreferForNodeIdentifier:pageNode.identifier] ?: pgrefer;

    EventTracingVTreeNode *node = pageNode;
    EventTracingVTree *VTree = pageNode.VTree;

    ETReferUpdateOption option = ETReferUpdateOptionNone;
    if (psreferMute) {
        option |= ETReferUpdateOptionPsreferMute;
    }
    /// MARK: pgrefer & psrefer
    [self _doCallReferObserversForSel:@selector(pgreferNeedsUpdatedTo:psrefer:node:inVTree:option:) block:^(id<EventTracingReferObserver> observer) {
        [observer pgreferNeedsUpdatedTo:pgrefer psrefer:psrefer node:node inVTree:VTree option:option];
    }];

    [pageNode pageNodeMarkFromRefer:pgrefer psrefer:psrefer];
}

- (void)_doCallReferObserversForSel:(SEL)sel block:(void(^)(id<EventTracingReferObserver> observer))block {
    [[EventTracingEngine sharedInstance].ctx.allReferObservers enumerateObjectsUsingBlock:^(id<EventTracingReferObserver>  _Nonnull observer, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([observer respondsToSelector:sel]) {
            !block ?: block(observer);
        }
    }];
}

- (BOOL)_checkIfCouldInsertBecomeActiveOrEnterForegroundRefer {
    EventTracingFormattedEventRefer *lastestEventRefer = [[EventTracingEventReferQueue queue] fetchLastestEventRefer];
    
    /// MARK: 表示在此之前，已经有了一个 refer 插入了进来
    // 场景: 业务侧可能插入一个refer，早于 NSApplicationWillEnterForegroundNotionfation 通知
    return lastestEventRefer == nil || lastestEventRefer.appEnterBackgroundSeq < [EventTracingEngine sharedInstance].ctx.appEnterBackgroundSeq;
}

@end
