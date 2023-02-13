//
//  EventTracingReferFuncs.m
//  EventTracing
//
//  Created by dl on 2021/7/27.
//

#import "EventTracingReferFuncs.h"
#import "EventTracingDefines.h"
#import "EventTracingEventReferQueue.h"
#import "EventTracingTraverser.h"
#import "EventTracingEventRefer+Private.h"

#import "UIView+EventTracingPrivate.h"
#import "EventTracingVTreeNode+Private.h"
#import "EventTracingEngine+Private.h"
#import "UIView+EventTracingPrivate.h"

#import "NSArray+ETEnumerator.h"

#pragma mark - Util methods
void ET_BuildParamsVariableViews(NSDictionary<NSString *, NSString *> *params, UIView *view, ...) {
    NSMutableArray *views = [@[] mutableCopy];
    ETGetArgsArr(views, view, UIView)
    
    ET_BuildParamsMultiViews(views, params);
}

void ET_BuildParamsMultiViews(NSArray<UIView *> *views, NSDictionary<NSString *, NSString *> *params) {
    [views enumerateObjectsUsingBlock:^(UIView * _Nonnull view, NSUInteger idx, BOOL * _Nonnull stop) {
        [view et_addParams:params];
    }];
}

UIView *__ET_FindViewBaseOnViews(NSArray<UIView *> *views, BOOL needOid, NSString *oid, BOOL onlyPage, BOOL up, EventTracingEnumeratorType enumeratorType) {
    if (views.count == 0 || (needOid && oid.length == 0)) {
        return nil;
    }
    
    __block UIView *foundedView;
    [views et_enumerateObjectsWithType:enumeratorType usingBlock:^NSArray<UIView *> * _Nonnull(UIView * _Nonnull obj, BOOL * _Nonnull stop) {
        BOOL findNode = onlyPage ? ET_isPage(obj) : ET_isPageOrElement(obj);
        if (findNode) {
            if (!needOid) {
                foundedView = obj;
                
                *stop = YES;
            }
            else if ([obj.et_pageId isEqualToString:oid] || [obj.et_elementId isEqualToString:oid]) {
                foundedView = obj;
                
                *stop = YES;
            }
        }
        
        if (up) {
            return obj.superview ? @[obj.superview] : nil;
        }
        return obj.subviews;
    }];
    
    return foundedView;
}

__attribute__((overloadable)) UIView * _Nullable ET_FindAncestorNodeViewAt(UIView *view) {
    return __ET_FindViewBaseOnViews((view ? @[view] : nil), NO, nil, NO, YES, EventTracingEnumeratorTypeBFS);
}
__attribute__((overloadable)) UIView * _Nullable ET_FindAncestorNodeViewAt(UIView *view, BOOL onlyPage) {
    return __ET_FindViewBaseOnViews((view ? @[view] : nil), NO, nil, onlyPage, YES, EventTracingEnumeratorTypeBFS);
}

UIView * _Nullable ET_FindAncestorNodeViewAt(UIView *view, NSString *oid) {
    return __ET_FindViewBaseOnViews((view ? @[view] : nil), YES, oid, NO, YES, EventTracingEnumeratorTypeBFS);
}

__attribute__((overloadable)) UIView * _Nullable ET_FindSubNodeViewAt(UIView *view) {
    return __ET_FindViewBaseOnViews((view ? @[view] : nil), NO, nil, NO, NO, EventTracingEnumeratorTypeDFSRight);
}

__attribute__((overloadable)) UIView * _Nullable ET_FindSubNodeViewAt(UIView *view, BOOL onlyPage) {
    return __ET_FindViewBaseOnViews((view ? @[view] : nil), NO, nil, onlyPage, NO, EventTracingEnumeratorTypeDFSRight);
}

UIView * _Nullable ET_FindSubNodeViewAt(UIView *view, NSString *oid) {
    return __ET_FindViewBaseOnViews((view ? @[view] : nil), YES, oid, NO, NO, EventTracingEnumeratorTypeDFSRight);
}

UIView * _Nullable ET_FindNodeViewGlobally(NSString *oid) {
    NSMutableArray<UIWindow *> *windows = [UIApplication sharedApplication].windows.mutableCopy;
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    if (![windows containsObject:keyWindow]) {
        [windows addObject:keyWindow];
    }

    return __ET_FindViewBaseOnViews(windows, YES, oid, NO, NO, EventTracingEnumeratorTypeDFSRight);
}

NSString * _Nullable ET_spmForView(UIView *v) {
    if (!ET_isPageOrElement(v)) {
        return nil;
    }
    
    return v.et_currentVTreeNode.spm;
}

NSString * _Nullable ET_spmForViewController(UIViewController *vc) {
    return ET_spmForView(vc.p_et_view);
}

__attribute__((overloadable)) NSString * _Nullable ET_eventReferForView(UIView *v) {
    return ET_eventReferForView(v, NO);
}

NSString * _Nullable ET_eventReferForView(UIView *v, BOOL useNextActseq) {
    if (!ET_isPageOrElement(v)) {
        return nil;
    }
    
    EventTracingVTreeNode *node = v.et_currentVTreeNode;
    UIViewController *vc = v.et_currentViewController;
    if ([vc isKindOfClass:UIAlertController.class]) {
        node = [(UIAlertController *)vc et_VTreeNodeCopy];
    }
    
    return ET_formattedReferForNode(node, useNextActseq).value;
}

id<EventTracingEventRefer> _ET_lastestAutoEventReferWithSessidAndUndefinedXpath(BOOL withSessid, NSString *event) {
    EventTracingFormattedEventRefer *preferedRefer = nil;
    if (!event) {
        preferedRefer = [[EventTracingEventReferQueue queue] fetchLastestEventRefer];
    } else {
        preferedRefer = [[EventTracingEventReferQueue queue] fetchLastestEventReferForEvent:event];
    }
    
    EventTracingFormattedEventRefer *lastestRootPagePVRefer = [[EventTracingEventReferQueue queue] fetchLastestRootPagePVRefer];
    EventTracingUndefinedXpathEventRefer *lastestUndefinedXpathRefer = nil;
    if (!event) {
        lastestUndefinedXpathRefer = [[EventTracingEventReferQueue queue] undefinedXpath_fetchLastestEventRefer];
    } else {
        lastestUndefinedXpathRefer = [[EventTracingEventReferQueue queue] undefinedXpath_fetchLastestEventReferForEvent:event];
    }
    
    // 判断该次找到的 event refer 非法
    /// MARK: 1. 找到的 event refer 比最近一次的 rootPage 曝光还要早，则此时应该降级到 rootPage 曝光
    BOOL referValid = preferedRefer.eventTime >= lastestRootPagePVRefer.eventTime;
    
    /// MARK: 2. 在一个节点触发事件之后，有一个非节点的view也触发了事件，此时需要降级到 rootPage 曝光
    referValid = referValid && lastestUndefinedXpathRefer.eventTime <= preferedRefer.eventTime;
    
    BOOL undefinedXpath = NO;
    if (!referValid && lastestRootPagePVRefer) {
        preferedRefer = lastestRootPagePVRefer;
        undefinedXpath = YES;
    }

    if (preferedRefer == nil) {
        return nil;
    }
    
    if (undefinedXpath || withSessid) {
        return [EventTracingFormattedWithSessidUndefinedXpathEventRefer referFromFormattedEventRefer:preferedRefer
                                                                                            withSessid:withSessid
                                                                                        undefinedXpath:undefinedXpath];
    }
    
    return preferedRefer;
}

id<EventTracingEventRefer> _Nullable ET_lastestAutoEventRefer(void) {
    return _ET_lastestAutoEventReferWithSessidAndUndefinedXpath(YES, nil);
}

id<EventTracingEventRefer> _Nullable ET_lastestAutoEventNoSessidRefer(void) {
    return _ET_lastestAutoEventReferWithSessidAndUndefinedXpath(NO, nil);
}

id<EventTracingEventRefer> _Nullable ET_lastestAutoEventReferForEvent(NSString *event) {
    return _ET_lastestAutoEventReferWithSessidAndUndefinedXpath(YES, event);
}

id<EventTracingEventRefer> _Nullable ET_lastestAutoEventNoSessidReferForEvent(NSString *event) {
    return _ET_lastestAutoEventReferWithSessidAndUndefinedXpath(NO, event);
}

id<EventTracingEventRefer> _Nullable ET_lastestUndefinedXpathRefer(void) {
    return [[EventTracingEventReferQueue queue] undefinedXpath_fetchLastestEventRefer];
}
