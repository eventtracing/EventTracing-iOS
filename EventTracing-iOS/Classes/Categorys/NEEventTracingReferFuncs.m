//
//  NEEventTracingReferFuncs.m
//  NEEventTracing
//
//  Created by dl on 2021/7/27.
//

#import "NEEventTracingReferFuncs.h"
#import "NEEventTracingDefines.h"
#import "NEEventTracingEventReferQueue.h"
#import "NEEventTracingEventReferQueue+Query.h"
#import "NEEventTracingTraverser.h"
#import "NEEventTracingEventRefer+Private.h"

#import "UIView+EventTracingPrivate.h"
#import "NEEventTracingVTreeNode+Private.h"
#import "NEEventTracingEngine+Private.h"
#import "UIView+EventTracingPrivate.h"

#import "NSArray+ETEnumerator.h"

#pragma mark - Util methods
void NE_ET_BuildParamsVariableViews(NSDictionary<NSString *, NSString *> *params, UIView *view, ...) {
    NSMutableArray *views = [@[] mutableCopy];
    ETGetArgsArr(views, view, UIView)
    
    NE_ET_BuildParamsMultiViews(views, params);
}

void NE_ET_BuildParamsMultiViews(NSArray<UIView *> *views, NSDictionary<NSString *, NSString *> *params) {
    [views enumerateObjectsUsingBlock:^(UIView * _Nonnull view, NSUInteger idx, BOOL * _Nonnull stop) {
        [view ne_et_addParams:params];
    }];
}

UIView *__ET_FindViewBaseOnViews(NSArray<UIView *> *views, BOOL needOid, NSString *oid, BOOL onlyPage, BOOL up, NEEventTracingEnumeratorType enumeratorType) {
    if (views.count == 0 || (needOid && oid.length == 0)) {
        return nil;
    }
    
    __block UIView *foundedView;
    [views ne_et_enumerateObjectsWithType:enumeratorType usingBlock:^NSArray<UIView *> * _Nonnull(UIView * _Nonnull obj, BOOL * _Nonnull stop) {
        BOOL findNode = onlyPage ? NE_ET_isPage(obj) : NE_ET_isPageOrElement(obj);
        if (findNode) {
            if (!needOid) {
                foundedView = obj;
                
                *stop = YES;
            }
            else if ([obj.ne_et_pageId isEqualToString:oid] || [obj.ne_et_elementId isEqualToString:oid]) {
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

__attribute__((overloadable)) UIView * _Nullable NE_ET_FindAncestorNodeViewAt(UIView *view) {
    return __ET_FindViewBaseOnViews((view ? @[view] : nil), NO, nil, NO, YES, NEEventTracingEnumeratorTypeBFS);
}
__attribute__((overloadable)) UIView * _Nullable NE_ET_FindAncestorNodeViewAt(UIView *view, BOOL onlyPage) {
    return __ET_FindViewBaseOnViews((view ? @[view] : nil), NO, nil, onlyPage, YES, NEEventTracingEnumeratorTypeBFS);
}

UIView * _Nullable NE_ET_FindAncestorNodeViewAt(UIView *view, NSString *oid) {
    return __ET_FindViewBaseOnViews((view ? @[view] : nil), YES, oid, NO, YES, NEEventTracingEnumeratorTypeBFS);
}

__attribute__((overloadable)) UIView * _Nullable NE_ET_FindSubNodeViewAt(UIView *view) {
    return __ET_FindViewBaseOnViews((view ? @[view] : nil), NO, nil, NO, NO, NEEventTracingEnumeratorTypeDFSRight);
}

__attribute__((overloadable)) UIView * _Nullable NE_ET_FindSubNodeViewAt(UIView *view, BOOL onlyPage) {
    return __ET_FindViewBaseOnViews((view ? @[view] : nil), NO, nil, onlyPage, NO, NEEventTracingEnumeratorTypeDFSRight);
}

UIView * _Nullable NE_ET_FindSubNodeViewAt(UIView *view, NSString *oid) {
    return __ET_FindViewBaseOnViews((view ? @[view] : nil), YES, oid, NO, NO, NEEventTracingEnumeratorTypeDFSRight);
}

UIView * _Nullable NE_ET_FindNodeViewGlobally(NSString *oid) {
    NSMutableArray<UIWindow *> *windows = [UIApplication sharedApplication].windows.mutableCopy;
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    if (![windows containsObject:keyWindow]) {
        [windows addObject:keyWindow];
    }

    return __ET_FindViewBaseOnViews(windows, YES, oid, NO, NO, NEEventTracingEnumeratorTypeDFSRight);
}

NSString * _Nullable NE_ET_spmForView(UIView *v) {
    if (!NE_ET_isPageOrElement(v)) {
        return nil;
    }
    
    return v.ne_et_currentVTreeNode.spm;
}

NSString * _Nullable NE_ET_spmForViewController(UIViewController *vc) {
    return NE_ET_spmForView(vc.p_ne_et_view);
}

__attribute__((overloadable)) NSString * _Nullable NE_ET_eventReferForView(UIView *v) {
    return NE_ET_eventReferForView(v, NO);
}

NSString * _Nullable NE_ET_eventReferForView(UIView *v, BOOL useNextActseq) {
    if (!NE_ET_isPageOrElement(v)) {
        return nil;
    }
    
    NEEventTracingVTreeNode *node = v.ne_et_currentVTreeNode;
    UIViewController *vc = v.ne_et_currentViewController;
    if ([vc isKindOfClass:UIAlertController.class]) {
        node = [(UIAlertController *)vc ne_et_VTreeNodeCopy];
    }
    
    return NE_ET_formattedReferForNode(node, useNextActseq).value;
}

id<NEEventTracingEventRefer> _NE_ET_lastestAutoEventReferWithSessidAndUndefinedXpath(BOOL withSessid, NSString *event) {
    NEEventTracingEventReferQueryResult * result =
    [[NEEventTracingEventReferQueue queue] queryWithBuilder:^(NEEventTracingEventReferQueryParams * _Nonnull params) {
        params.event = event;
    }];
    
    NEEventTracingFormattedEventRefer *preferedRefer = result.refer;
    
    if (preferedRefer == nil) {
        return nil;
    }
    if (!result.valid || withSessid) {
        return [NEEventTracingFormattedWithSessidUndefinedXpathEventRefer referFromFormattedEventRefer:preferedRefer
                                                                                            withSessid:withSessid
                                                                                        undefinedXpath:!result.valid];
    }
    return preferedRefer;
}

id<NEEventTracingEventRefer> _Nullable NE_ET_lastestAutoEventRefer(void) {
    return _NE_ET_lastestAutoEventReferWithSessidAndUndefinedXpath(YES, nil);
}

id<NEEventTracingEventRefer> _Nullable NE_ET_lastestAutoEventNoSessidRefer(void) {
    return _NE_ET_lastestAutoEventReferWithSessidAndUndefinedXpath(NO, nil);
}

id<NEEventTracingEventRefer> _Nullable NE_ET_lastestAutoEventReferForEvent(NSString *event) {
    return _NE_ET_lastestAutoEventReferWithSessidAndUndefinedXpath(YES, event);
}

id<NEEventTracingEventRefer> _Nullable NE_ET_lastestAutoEventNoSessidReferForEvent(NSString *event) {
    return _NE_ET_lastestAutoEventReferWithSessidAndUndefinedXpath(NO, event);
}

id<NEEventTracingEventRefer> _Nullable NE_ET_lastestAutoClckEventViewTreeSPMRefer(void) {
    return NE_ET_lastestUndefinedXpathRefer();
}

id<NEEventTracingEventRefer> _Nullable NE_ET_lastestUndefinedXpathRefer(void) {
    return [[NEEventTracingEventReferQueue queue] undefinedXpath_fetchLastestEventRefer];
}

void NE_ET_pushAutoEventReferSubfix(UIView *view, NSString *event, NSString *subfix) {
    /// MARK: 已经废弃
}
