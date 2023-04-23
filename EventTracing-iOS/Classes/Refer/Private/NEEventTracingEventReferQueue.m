//
//  EventTracingEventReferQueue.m
//  EventTracing
//
//  Created by dl on 2021/4/1.
//

#import "EventTracingEventReferQueue.h"
#import "EventTracingEventReferQueue+Query.h"
#import "EventTracingDefines.h"
#import "EventTracingVTree+Private.h"
#import "EventTracingVTreeNode+Private.h"
#import "EventTracingEventRefer+Private.h"
#import "EventTracingFormattedReferBuilder.h"
#import "EventTracingTraverser.h"
#import "UIView+EventTracingPrivate.h"
#import "EventTracingEngine+Private.h"
#import "NSArray+ETEnumerator.h"

#import <BlocksKit/BlocksKit.h>

#define LOCK        dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
#define UNLOCK      dispatch_semaphore_signal(_lock);

@interface EventTracingEventReferQueue () {
    dispatch_semaphore_t _lock;
    
    NSMutableArray<EventTracingFormattedEventRefer *> *_innerRefers;
    EventTracingUndefinedXpathEventRefer *_lastestUndefinedXPathRefer;
    NSMutableArray<EventTracingUndefinedXpathEventRefer *> *_innerUndefinedXpathRefers;
    NSString *_hsrefer;
}
@end

@implementation EventTracingEventReferQueue

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
    static EventTracingEventReferQueue *_queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _queue = [[EventTracingEventReferQueue alloc] init];
    });
    return _queue;
}

- (void)pushEventRefer:(EventTracingFormattedEventRefer *)refer {
    LOCK {
        [_innerRefers addObject:refer];
    } UNLOCK
}

- (void)pushEventRefer:(EventTracingFormattedEventRefer *)refer
                  node:(EventTracingVTreeNode * _Nullable)node
             isSubPage:(BOOL)isSubPage {
    if (!node) {
        if (!isSubPage) {
            [self pushEventRefer:refer];
        }
        return;
    }
    
    EventTracingFormattedEventRefer *rootPagePVRefer = [[EventTracingEventReferQueue queue] fetchLastestRootPagePVRefer];
    EventTracingVTreeNode *rootPageNode = [node findToppestNode:YES];
    if ([rootPageNode.rootPagePVFormattedRefer.value isEqualToString:rootPagePVRefer.formattedRefer.value]) {
        [rootPagePVRefer addSubRefer:refer];
    }
    else if (!isSubPage) {
        [self pushEventRefer:refer];
    }
}

- (void)removeEventRefer:(EventTracingFormattedEventRefer *)refer {
    LOCK {
        [_innerRefers removeObject:refer];
    } UNLOCK
}

- (void)clear {
    LOCK {
        [_innerRefers removeAllObjects];
    } UNLOCK
}

- (NSArray<EventTracingFormattedEventRefer *> *)allRefers {
    NSArray<EventTracingFormattedEventRefer *> *allRefers = nil;
    LOCK {
        allRefers = _innerRefers.copy;
    } UNLOCK
    
    return allRefers;
}

@end

@implementation EventTracingEventReferQueue (EventRefer)

- (BOOL)pushEventReferForEvent:(NSString *)event
                          view:(UIView *)view
                          node:(EventTracingVTreeNode * _Nullable)node
                   useForRefer:(BOOL)useForRefer
                 useNextActseq:(BOOL)useNextActseq {
    if (!ET_isPageOrElement(view)) {
        if (!ET_isIgnoreRefer(view)) {
            [self undefinedXpath_pushEventReferForEvent:event view:view];
        }
        
        return NO;
    }
    
    if (!node) {
        /// MARK: 这里能出现，都是因为 `[view et_isSimpleVisible] == NO`
        /// MARK: 仅可能发生在自定义事件埋点；因为AOP埋点可以执行，该view一定可见
        return NO;
    }
    
    return [self _doPushEventReferForEvent:event node:node useForRefer:useForRefer useNextActseq:useNextActseq];
}
- (BOOL)_doPushEventReferForEvent:(NSString *)event
                             node:(EventTracingVTreeNode *)node
                      useForRefer:(BOOL)useForRefer
                    useNextActseq:(BOOL)useNextActseq {
    return [self _doPushEventReferForEvent:event node:node useForRefer:useForRefer useNextActseq:useNextActseq isSubPage:NO];
}

- (BOOL)_doPushEventReferForEvent:(NSString *)event
                             node:(EventTracingVTreeNode *)node
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
    
    id<EventTracingFormattedRefer> formattedRefer = ET_formattedReferForNode(node, NO);
    EventTracingVTreeNode *rootPageNode = [node findToppestNode:YES];
    BOOL rootPagePV = rootPageNode == node;
    
    __block BOOL shouldStartHsrefer = NO;
    NSArray<NSString *> *needStartHsreferOids = [EventTracingEngine sharedInstance].ctx.needStartHsreferOids;
    [node enumerateAncestorNodeWithBlock:^(EventTracingVTreeNode * _Nonnull ancestorNode, BOOL * _Nonnull stop) {
        if ([needStartHsreferOids containsObject:ancestorNode.oid]) {
            shouldStartHsrefer = YES;
            *stop = YES;
        }
    }];
    
    EventTracingFormattedEventRefer *refer = [EventTracingFormattedEventRefer referWithEvent:event
                                                                              formattedRefer:formattedRefer
                                                                                  rootPagePV:rootPagePV
                                                                          shouldStartHsrefer:shouldStartHsrefer
                                                                          isNodePsreferMuted:node.psreferMute];
    
    [self pushEventRefer:refer node:node isSubPage:isSubPage];
    
    return YES;
}

- (void)rootPageNodeDidImpress:(EventTracingVTreeNode * _Nullable)node
                       inVTree:(EventTracingVTree * _Nullable)VTree {
    if (!node.isPageNode || !VTree) {
        return;
    }

    [self _doPushEventReferForEvent:ET_EVENT_ID_P_VIEW node:node useForRefer:YES useNextActseq:NO];
}

- (void)subPageNodeDidImpress:(EventTracingVTreeNode * _Nullable)node
                      inVTree:(EventTracingVTree * _Nullable)VTree {
    if (!node.isPageNode || !VTree) {
        return;
    }
    [self _doPushEventReferForEvent:ET_EVENT_ID_P_VIEW node:node useForRefer:YES useNextActseq:YES isSubPage:YES];
}

- (EventTracingFormattedEventRefer *)fetchLastestRootPagePVRefer {
    NSArray<EventTracingFormattedEventRefer *> *innerRefers = nil;
    
    LOCK {
        innerRefers = _innerRefers.copy;
    } UNLOCK
    
    return [innerRefers.reverseObjectEnumerator.allObjects bk_match:^BOOL(EventTracingFormattedEventRefer *obj) {
        return obj.isRootPagePV;
    }];
}

@end

@implementation EventTracingEventReferQueue (UndefinedXpathEventRefer)

- (void)undefinedXpath_pushEventReferForEvent:(NSString *)event view:(UIView *)view {
    EventTracingUndefinedXpathEventRefer *undefinedXpathRefer =
    [EventTracingUndefinedXpathEventRefer referWithEvent:event
                                     undefinedXpathRefer:ET_undefinedXpathReferForView(view)];
    
    LOCK {
        [_innerUndefinedXpathRefers addObject:undefinedXpathRefer];
    } UNLOCK
}

- (EventTracingUndefinedXpathEventRefer * _Nullable)undefinedXpath_fetchLastestEventRefer {
    NSArray<EventTracingUndefinedXpathEventRefer *> *innerUndefinedXpathRefers = nil;
    
    LOCK {
        innerUndefinedXpathRefers = _innerUndefinedXpathRefers;
    } UNLOCK
    
    return innerUndefinedXpathRefers.lastObject;
}

- (EventTracingUndefinedXpathEventRefer * _Nullable)undefinedXpath_fetchLastestEventReferForEvent:(NSString *)event {
    NSArray<EventTracingUndefinedXpathEventRefer *> *innerUndefinedXpathRefers = nil;
    
    LOCK {
        innerUndefinedXpathRefers = _innerUndefinedXpathRefers;
    } UNLOCK
    
    return [innerUndefinedXpathRefers.reverseObjectEnumerator.allObjects bk_match:^BOOL(EventTracingUndefinedXpathEventRefer *obj) {
        return [obj.event isEqualToString:event];
    }];
}

@end

@implementation EventTracingEventReferQueue (FormattedHsrefer)

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
