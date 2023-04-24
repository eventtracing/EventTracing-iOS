//
//  NEEventTracingEventReferQueue.m
//  NEEventTracing
//
//  Created by dl on 2021/4/1.
//

#import "NEEventTracingEventReferQueue.h"
#import "NEEventTracingEventReferQueue+Query.h"
#import "NEEventTracingDefines.h"
#import "NEEventTracingVTree+Private.h"
#import "NEEventTracingVTreeNode+Private.h"
#import "NEEventTracingEventRefer+Private.h"
#import "NEEventTracingFormattedReferBuilder.h"
#import "NEEventTracingTraverser.h"
#import "UIView+EventTracingPrivate.h"
#import "NEEventTracingEngine+Private.h"
#import "NSArray+ETEnumerator.h"

#import <BlocksKit/BlocksKit.h>

#define LOCK        dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
#define UNLOCK      dispatch_semaphore_signal(_lock);

@interface NEEventTracingEventReferQueue () {
    dispatch_semaphore_t _lock;
    
    NSMutableArray<NEEventTracingFormattedEventRefer *> *_innerRefers;
    NEEventTracingUndefinedXpathEventRefer *_lastestUndefinedXPathRefer;
    NSMutableArray<NEEventTracingUndefinedXpathEventRefer *> *_innerUndefinedXpathRefers;
    NSString *_hsrefer;
}
@end

@implementation NEEventTracingEventReferQueue

- (instancetype)init {
    self = [super init];
    if (self) {
        _innerRefers = @[].mutableCopy;
        _innerUndefinedXpathRefers = @[].mutableCopy;
        _lock = dispatch_semaphore_create(1);
    }
    return self;
}

+ (instancetype)queue {
    static NEEventTracingEventReferQueue *_queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _queue = [[NEEventTracingEventReferQueue alloc] init];
    });
    return _queue;
}

- (void)pushEventRefer:(NEEventTracingFormattedEventRefer *)refer {
    LOCK {
        [_innerRefers addObject:refer];
    } UNLOCK
}

- (void)pushEventRefer:(NEEventTracingFormattedEventRefer *)refer
                  node:(NEEventTracingVTreeNode * _Nullable)node
             isSubPage:(BOOL)isSubPage {
    if (!node) {
        if (!isSubPage) {
            [self pushEventRefer:refer];
        }
        return;
    }
    
    NEEventTracingFormattedEventRefer *rootPagePVRefer = [[NEEventTracingEventReferQueue queue] fetchLastestRootPagePVRefer];
    NEEventTracingVTreeNode *rootPageNode = [node findToppestNode:YES];
    if ([rootPageNode.rootPagePVFormattedRefer.value isEqualToString:rootPagePVRefer.formattedRefer.value]) {
        [rootPagePVRefer addSubRefer:refer];
    }
    else if (!isSubPage) {
        [self pushEventRefer:refer];
    }
}

- (void)removeEventRefer:(NEEventTracingFormattedEventRefer *)refer {
    LOCK {
        [_innerRefers removeObject:refer];
    } UNLOCK
}

- (void)clear {
    LOCK {
        [_innerRefers removeAllObjects];
    } UNLOCK
}

- (NSArray<NEEventTracingFormattedEventRefer *> *)allRefers {
    NSArray<NEEventTracingFormattedEventRefer *> *allRefers = nil;
    LOCK {
        allRefers = _innerRefers.copy;
    } UNLOCK
    
    return allRefers;
}

@end

@implementation NEEventTracingEventReferQueue (EventRefer)

- (BOOL)pushEventReferForEvent:(NSString *)event
                          view:(UIView *)view
                          node:(NEEventTracingVTreeNode * _Nullable)node
                   useForRefer:(BOOL)useForRefer
                 useNextActseq:(BOOL)useNextActseq {
    if (!NE_ET_isPageOrElement(view)) {
        if (!NE_ET_isIgnoreRefer(view)) {
            [self undefinedXpath_pushEventReferForEvent:event view:view];
        }
        
        return NO;
    }
    
    if (!node) {
        /// MARK: 这里能出现，都是因为 `[view ne_et_isSimpleVisible] == NO`
        /// MARK: 仅可能发生在自定义事件埋点；因为AOP埋点可以执行，该view一定可见
        return NO;
    }
    
    return [self _doPushEventReferForEvent:event node:node useForRefer:useForRefer useNextActseq:useNextActseq];
}
- (BOOL)_doPushEventReferForEvent:(NSString *)event
                             node:(NEEventTracingVTreeNode *)node
                      useForRefer:(BOOL)useForRefer
                    useNextActseq:(BOOL)useNextActseq {
    return [self _doPushEventReferForEvent:event node:node useForRefer:useForRefer useNextActseq:useNextActseq isSubPage:NO];
}

- (BOOL)_doPushEventReferForEvent:(NSString *)event
                             node:(NEEventTracingVTreeNode *)node
                      useForRefer:(BOOL)useForRefer
                    useNextActseq:(BOOL)useNextActseq
                        isSubPage:(BOOL)isSubPage {
    /// MARK: 1. 如果向上找不到页面节点，则不会埋点，也不会参与链路追踪相关的事情, 也不做actseq自增
    if (![node firstAncestorPageNode]) {
        return NO;
    }
    
    /// MARK: 该事件生成refer，如果需要 _actseq 自增
    if (useNextActseq) {
        [node doIncreaseActseq];
    }
    
    /// MARK: 2. 如果该节点忽略链路追踪，则直接返回
    if (!useForRefer || node.ignoreRefer) {
        return NO;
    }
    /// MARK: 3. 如果该节点psrefer不参与链路，则直接返回
    if (node.psreferMute) {
        return NO;
    }
    
    id<NEEventTracingFormattedRefer> formattedRefer = NE_ET_formattedReferForNode(node, NO);
    NEEventTracingVTreeNode *rootPageNode = [node findToppestNode:YES];
    BOOL rootPagePV = rootPageNode == node;
    
    __block BOOL shouldStartHsrefer = NO;
    NSArray<NSString *> *needStartHsreferOids = [NEEventTracingEngine sharedInstance].ctx.needStartHsreferOids;
    [node enumerateAncestorNodeWithBlock:^(NEEventTracingVTreeNode * _Nonnull ancestorNode, BOOL * _Nonnull stop) {
        if ([needStartHsreferOids containsObject:ancestorNode.oid]) {
            shouldStartHsrefer = YES;
            *stop = YES;
        }
    }];
    
    NEEventTracingFormattedEventRefer *refer = [NEEventTracingFormattedEventRefer referWithEvent:event
                                                                                  formattedRefer:formattedRefer
                                                                                      rootPagePV:rootPagePV
                                                                              shouldStartHsrefer:shouldStartHsrefer
                                                                              isNodePsreferMuted:node.psreferMute];
    
    [self pushEventRefer:refer node:node isSubPage:isSubPage];
    
    return YES;
}

- (void)rootPageNodeDidImpress:(NEEventTracingVTreeNode * _Nullable)node
                       inVTree:(NEEventTracingVTree * _Nullable)VTree {
    if (!node.isPageNode || !VTree) {
        return;
    }

    [self _doPushEventReferForEvent:NE_ET_EVENT_ID_P_VIEW node:node useForRefer:YES useNextActseq:NO];
}

- (void)subPageNodeDidImpress:(NEEventTracingVTreeNode * _Nullable)node
                      inVTree:(NEEventTracingVTree * _Nullable)VTree {
    if (!node.isPageNode || !VTree) {
        return;
    }
    [self _doPushEventReferForEvent:NE_ET_EVENT_ID_P_VIEW node:node useForRefer:YES useNextActseq:YES isSubPage:YES];
}

- (NEEventTracingFormattedEventRefer *)fetchLastestRootPagePVRefer {
    NSArray<NEEventTracingFormattedEventRefer *> *innerRefers = nil;
    
    LOCK {
        innerRefers = _innerRefers.copy;
    } UNLOCK
    
    return [innerRefers.reverseObjectEnumerator.allObjects bk_match:^BOOL(NEEventTracingFormattedEventRefer *obj) {
        return obj.isRootPagePV;
    }];
}

@end

@implementation NEEventTracingEventReferQueue (UndefinedXpathEventRefer)

- (void)undefinedXpath_pushEventReferForEvent:(NSString *)event view:(UIView *)view {
    NEEventTracingUndefinedXpathEventRefer *undefinedXpathRefer =
    [NEEventTracingUndefinedXpathEventRefer referWithEvent:event
                                       undefinedXpathRefer:NE_ET_undefinedXpathReferForView(view)];

    LOCK {
        [_innerUndefinedXpathRefers addObject:undefinedXpathRefer];
    } UNLOCK
}

- (NEEventTracingUndefinedXpathEventRefer * _Nullable)undefinedXpath_fetchLastestEventRefer {
    NSArray<NEEventTracingUndefinedXpathEventRefer *> *innerUndefinedXpathRefers = nil;
    
    LOCK {
        innerUndefinedXpathRefers = _innerUndefinedXpathRefers;
    } UNLOCK
    
    return innerUndefinedXpathRefers.lastObject;
}

- (NEEventTracingUndefinedXpathEventRefer * _Nullable)undefinedXpath_fetchLastestEventReferForEvent:(NSString *)event {
    NSArray<NEEventTracingUndefinedXpathEventRefer *> *innerUndefinedXpathRefers = nil;
    
    LOCK {
        innerUndefinedXpathRefers = _innerUndefinedXpathRefers;
    } UNLOCK
    
    return [innerUndefinedXpathRefers.reverseObjectEnumerator.allObjects bk_match:^BOOL(NEEventTracingUndefinedXpathEventRefer *obj) {
        return [obj.event isEqualToString:event];
    }];
}

@end

@implementation NEEventTracingEventReferQueue (FormattedHsrefer)

- (NSString * _Nullable)hsrefer {
    NSString *hsrefer = nil;
    LOCK {
        hsrefer = _hsrefer;
    } UNLOCK
    
    return hsrefer;
}

- (void)hsreferNeedsUpdateTo:(NSString *)hsrefer {
    LOCK {
        _hsrefer = hsrefer;
    } UNLOCK
}

@end
