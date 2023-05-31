//
//  NEEventTracingEventReferCollector.m
//  NEEventTracing
//
//  Created by dl on 2021/4/8.
//

#import "NEEventTracingEventReferCollector.h"
#import "NEEventTracingEventReferQueue.h"
#import "NEEventTracingEventReferQueue+Query.h"
#import "NEEventTracingEventEmitter.h"
#import "NEEventTracingVTreeNode+Private.h"
#import "NEEventTracingDefines.h"
#import "NEEventTracingFormattedReferBuilder.h"
#import "NEEventTracingInternalLog.h"

#import "NEEventTracingEngine+Private.h"
#import "NEEventTracingContext+Private.h"

@interface NEEventTracingEventReferCollector ()
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *pageNodeIdentifierPsreferMap;
@end

@implementation NEEventTracingEventReferCollector

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
    
    [[NEEventTracingEventReferQueue queue] pushEventRefer:[NEEventTracingFormattedEventRefer enterForegroundRefer]];
}

- (void)willImpressNode:(NEEventTracingVTreeNode *)node inVTree:(NEEventTracingVTree *)VTree {
    if (!node.isPageNode) {
        return ;
    }
    
    [self _pageNodeWillImpress:node VTree:VTree];
}

- (NSString *)psreferForNodeIdentifier:(NSString *)identifier {
    return [_pageNodeIdentifierPsreferMap objectForKey:identifier];
}

#pragma mark - private methods
- (void)_pageNodeWillImpress:(NEEventTracingVTreeNode *)node VTree:(NEEventTracingVTree *)VTree {
    NEEventTracingVTreeNode *rootPageNode = [node findToppestNode:YES];
    BOOL isRootPagePV = rootPageNode == node;
    
    /// MARK: _hsrefer, 两个时机:
    // _hsrefer 时机1: oids列表中的页面曝光
    NSString *hsrefer = nil;
    NSArray<NSString *> *needStartHsreferOids = [NEEventTracingEngine sharedInstance].ctx.needStartHsreferOids;
    if ([needStartHsreferOids containsObject:node.oid]) {
        hsrefer = NE_ET_formattedReferForNode(node, NO).value;
    }
    
    // 只有顶层pageNode才设置 pgrefer & psrefer
    
    NEEventTracingPageReferConsumeOption referOption = node.pageReferConsumeOption;
    if (isRootPagePV && referOption == NEEventTracingPageReferConsumeOptionNone) {
        referOption = NEEventTracingPageReferConsumeOptionEventEc | NEEventTracingPageReferConsumeOptionCustom;
    }
    // _hsrefer 时机2: rootPage页面曝光，尝试从队列中取合法的 refer
    if (referOption != NEEventTracingPageReferConsumeOptionNone) {
        
        NEEventTracingEventReferQueryResult *result =
        [[NEEventTracingEventReferQueue queue] queryWithBuilder:^(NEEventTracingEventReferQueryParams * _Nonnull params) {
            params.referConsumeOption = referOption;
            params.rootPageNode = rootPageNode;
        }];
        
        NEEventTracingFormattedEventRefer *preferedRefer = result.refer;
        
        [self _markPageNode:node
                  fromRefer:preferedRefer.formattedRefer
             undefinedXpath:!result.valid
                psreferMute:preferedRefer.psreferMute];
        
        /// MARK: 判断找到的该refer是否可以作为 _hsrefer
        if (preferedRefer.shouldStartHsrefer) {
            hsrefer = [preferedRefer.formattedRefer valueWithSessid:NO undefinedXpath:!result.valid];
        }
    }
    /// MARK: 生产 psrefer
    if (isRootPagePV) {
        [[NEEventTracingEventReferQueue queue] rootPageNodeDidImpress:node inVTree:VTree];
        // store psrefer
        [_pageNodeIdentifierPsreferMap setValue:node.psrefer forKey:node.identifier];
        
    } else if (node.subpagePvToReferEnable) {
        [[NEEventTracingEventReferQueue queue] subPageNodeDidImpress:node inVTree:VTree];
        // store psrefer
        [_pageNodeIdentifierPsreferMap setValue:node.psrefer forKey:node.identifier];
    }

    /// MARK: 获取到了合法的 _hsrefer, 则更新
    if (hsrefer.length && ![hsrefer isEqualToString:[NEEventTracingEventReferQueue queue].hsrefer]) {
        [self _doCallReferObserversForSel:@selector(hsreferNeedsUpdatedTo:) block:^(id<NEEventTracingReferObserver> observer) {
            [observer hsreferNeedsUpdatedTo:hsrefer];
        }];

        [[NEEventTracingEventReferQueue queue] hsreferNeedsUpdateTo:hsrefer];
    }
}

- (void)_markPageNode:(NEEventTracingVTreeNode *)pageNode
            fromRefer:(id<NEEventTracingFormattedRefer>)formattedRefer
       undefinedXpath:(BOOL)undefinedXpath
          psreferMute:(BOOL)psreferMute {
    if (!formattedRefer) {
        return;
    }

    NSString *pgrefer = [formattedRefer valueWithSessid:NO undefinedXpath:undefinedXpath];
    NSString *psrefer = [self psreferForNodeIdentifier:pageNode.identifier] ?: pgrefer;

    NEEventTracingVTreeNode *node = pageNode;
    NEEventTracingVTree *VTree = pageNode.VTree;

    NEETReferUpdateOption option = NEETReferUpdateOptionNone;
    if (psreferMute) {
        option |= NEETReferUpdateOptionPsreferMute;
    }
    /// MARK: pgrefer & psrefer
    [self _doCallReferObserversForSel:@selector(pgreferNeedsUpdatedTo:psrefer:node:inVTree:option:) block:^(id<NEEventTracingReferObserver> observer) {
        [observer pgreferNeedsUpdatedTo:pgrefer psrefer:psrefer node:node inVTree:VTree option:option];
    }];

    [pageNode pageNodeMarkFromRefer:pgrefer psrefer:psrefer];
}

- (void)_doCallReferObserversForSel:(SEL)sel block:(void(^)(id<NEEventTracingReferObserver> observer))block {
    [[NEEventTracingEngine sharedInstance].ctx.allReferObservers enumerateObjectsUsingBlock:^(id<NEEventTracingReferObserver>  _Nonnull observer, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([observer respondsToSelector:sel]) {
            !block ?: block(observer);
        }
    }];
}

- (BOOL)_checkIfCouldInsertBecomeActiveOrEnterForegroundRefer {
    NEEventTracingFormattedEventRefer *lastestRefer =
    [[NEEventTracingEventReferQueue queue] queryWithBuilder:^(NEEventTracingEventReferQueryParams * _Nonnull params) {
        params.referConsumeOption = NEEventTracingPageReferConsumeOptionExceptSubPagePV;
    }].refer;
    
    /// MARK: 表示在此之前，已经有了一个 refer 插入了进来
    // 场景: 业务侧可能插入一个refer，早于 NSApplicationWillEnterForegroundNotionfation 通知
    return lastestRefer == nil || lastestRefer.appEnterBackgroundSeq < [NEEventTracingEngine sharedInstance].ctx.appEnterBackgroundSeq;
}

@end
