//
//  EventTracingEngine+Action.m
//  BlocksKit
//
//  Created by dl on 2021/3/23.
//

#import "EventTracingEngine+Action.h"
#import "EventTracingEngine+Private.h"
#import "UIView+EventTracingPrivate.h"
#import "EventTracingContext+Private.h"
#import "EventTracingEventOutput+Private.h"
#import "EventTracingVTree+Sync.h"
#import "EventTracingVTreeNode+Private.h"
#import "EventTracingEventActionConfig+Private.h"
#import "EventTracingParamGuardConfiguration.h"
#import "EventTracingEventReferQueue.h"
#import "NSArray+ETEnumerator.h"
#import "EventTracingFormattedReferBuilder.h"
#import "EventTracingEventRefer+Private.h"
#import <BlocksKit/BlocksKit.h>
#import "NSString+EventTracingUtil.h"

@implementation EventTracingEngine (Action)

#pragma mark - Log
- (void)logSimplyWithEvent:(NSString *)event
                    params:(NSDictionary *)params {
    if (![event isKindOfClass:[NSString class]] || event.length == 0) {
        return;
    }
    
    NSMutableDictionary *mutableParams = [(params ?: @{}) mutableCopy];
    if (![params.allKeys containsObject:ET_REFER_KEY_HSREFER]) {
        NSString *hsrefer = [EventTracingEngine sharedInstance].context.hsrefer;
        if (hsrefer.length) {
            [mutableParams setObject:hsrefer forKey:ET_REFER_KEY_HSREFER];
        }
    }
    
    [self.ctx.eventOutput outputEventWithoutNode:event contextParams:mutableParams.copy];
}

- (void)logReferEvent:(NSString *)event
            referType:(NSString *)referType
               params:(NSDictionary *)params {
    [self logReferEvent:event referType:referType referSPM:nil referSCM:nil params:params];
}

- (void)logReferEvent:(NSString *)event
            referType:(NSString *)referType
             referSPM:(NSString *)spm
             referSCM:(NSString *)scm
               params:(NSDictionary *)params {
    if (![event isKindOfClass:[NSString class]] || event.length == 0
        || ![referType isKindOfClass:[NSString class]] || referType.length == 0) {
        return;
    }
    
    [self.ctx actseqIncreased];
    
    NSMutableDictionary *mutableParams = @{}.mutableCopy;
    if (params.count) {
        [mutableParams addEntriesFromDictionary:params];
    }
    [mutableParams setObject:referType forKey:@"_refer_type"];
    
    if (spm.length) {
        [mutableParams setObject:spm forKey:@"_refer_spm"];
    }
    
    if (scm.length) {
        [mutableParams setObject:scm forKey:@"_refer_scm"];
    }
    
    [mutableParams setObject:@(self.context.actseq).stringValue forKey:ET_REFER_KEY_ACTSEQ];
    
    [self logSimplyWithEvent:event params:mutableParams.copy];
    
    /// MARK: refer => queue
    id<EventTracingFormattedRefer> formattedRefer = [EventTracingFormattedReferBuilder build:^(id<EventTracingFormattedReferComponentBuilder>  _Nonnull builder) {
        builder
        .type(referType)
        .actseq(self.context.actseq)
        .pgstep(self.context.pgstep);
        
        if (spm.length) {
            builder.spm(spm);
        }
        
        if (scm.length) {
            builder.scm(scm);
        }
        
        if ([scm et_hasBeenUrlEncoded]) {
            builder.er();
        }
    }].generateRefer;
    
    EventTracingFormattedEventRefer *refer = [EventTracingFormattedEventRefer referWithEvent:event
                                                                                  formattedRefer:formattedRefer
                                                                                      rootPagePV:NO
                                                                                           toids:nil
                                                                              shouldStartHsrefer:NO
                                                                              isNodePsreferMuted:NO];
    [[EventTracingEventReferQueue queue] pushEventRefer:refer];
}

- (void)logWithEvent:(NSString *)event view:(UIView *)view {
    [self logWithEvent:event view:view params:nil];
}

- (void)logWithEvent:(NSString *)event
                view:(UIView *)view
              params:(NSDictionary<NSString *,NSString *> *)params {
    [self logWithEvent:event view:view params:params eventAction:nil];
}

- (void)logWithEvent:(NSString *)event
                view:(UIView *)view
              params:(NSDictionary<NSString *,NSString *> *)params
         eventAction:(void(^ NS_NOESCAPE _Nullable)(EventTracingEventActionConfig *config))block {
    /// MARK: 1. do pre (ignore buildin disable click)
    EventTracingEventActionConfig *config = [EventTracingEventActionConfig configWithEvent:event];
    !block ?: block(config);
    
    UIView *pipFixedView = [view.et_pipEventToView objectForKey:event] ?: view;
    [self _preLogPushReferWithEvent:event view:pipFixedView useForRefer:config.useForRefer useNextActseq:config.increaseActseq];
    
    /// MARK: 2. do after (ignore buildin disable click)
    [self _afterLogWithEvent:event view:pipFixedView params:params eventAction:block];
}

- (void)AOP_preLogWithEvent:(NSString *)event view:(UIView *)view {
    [self AOP_preLogWithEvent:event view:view eventAction:nil];
}

- (void)AOP_preLogWithEvent:(NSString *)event
                       view:(UIView *)view
                eventAction:(void(^ NS_NOESCAPE _Nullable)(EventTracingEventActionConfig *config))block {
    UIView *pipFixedView = [view.et_pipEventToView objectForKey:event] ?: view;

    if ([event isEqualToString:ET_EVENT_ID_E_CLCK]
        && pipFixedView.et_buildinEventLogDisableStrategy & ETNodeBuildinEventLogDisableStrategyClick) {
        return;
    }
    
    EventTracingEventActionConfig *config = [EventTracingEventActionConfig configWithEvent:event];
    !block ?: block(config);
    
    [self _preLogPushReferWithEvent:event view:pipFixedView useForRefer:config.useForRefer useNextActseq:config.increaseActseq];
}

- (void)AOP_logWithEvent:(NSString *)event
                    view:(UIView *)view
                  params:(NSDictionary<NSString *,NSString *> *)params {
    [self AOP_logWithEvent:event view:view params:params eventAction:nil];
}

- (void)AOP_logWithEvent:(NSString *)event
                    view:(UIView *)view
                  params:(NSDictionary<NSString *,NSString *> *)params
             eventAction:(void(^ NS_NOESCAPE _Nullable)(EventTracingEventActionConfig *config))block {
    
    UIView *pipFixedView = [view.et_pipEventToView objectForKey:event] ?: view;
    if ([event isEqualToString:ET_EVENT_ID_E_CLCK]
        && pipFixedView.et_buildinEventLogDisableStrategy & ETNodeBuildinEventLogDisableStrategyClick) {
        return;
    }
    
    [self _afterLogWithEvent:event view:pipFixedView params:params eventAction:block];
}

- (void)flushStockedActionsIfNeeded:(EventTracingVTree *)VTree {
    NSArray<EventTracingEventAction *> *stockedEventActions = self.ctx.stockedEventActions.copy;
    [self.ctx.stockedEventActions removeAllObjects];
    
    [stockedEventActions enumerateObjectsUsingBlock:^(EventTracingEventAction * _Nonnull action, NSUInteger idx, BOOL * _Nonnull stop) {
        [action setupNode:action.view.et_currentVTreeNode VTree:VTree];
        [self.ctx.eventEmitter consumeEventAction:action];
    }];
}

#pragma mark - others
/// MARK: 为自定义埋点做一层封装
- (void)_preLogPushReferWithEvent:(NSString *)event
                             view:(UIView *)view
                      useForRefer:(BOOL)useForRefer
                    useNextActseq:(BOOL)useNextActseq {
    if (!self.started || ![event isKindOfClass:NSString.class] || event.length == 0) {
        return;
    }
    
    /// MARK: 对于需要参加链路追踪(或者需要自增actseq)的(应该存在节点)场景，尝试重新 traverse 一次 (注意: 这里是主线程同步操作!!!)
    if ((useForRefer || useNextActseq)
        && ET_isPageOrElement(view)
        && view.et_currentVTreeNode == nil
        && [view et_isSimpleVisible]) {
        [self traverseImmediatelyIfNeeded];
    }
    
    [[EventTracingEventReferQueue queue] pushEventReferForEvent:event
                                                             view:view
                                                             node:view.et_currentVTreeNode
                                                      useForRefer:useForRefer
                                                    useNextActseq:useNextActseq];
}

- (void)_afterLogWithEvent:(NSString *)event
                      view:(UIView *)view
                    params:(NSDictionary<NSString *,NSString *> *)params
               eventAction:(void(^ NS_NOESCAPE _Nullable)(EventTracingEventActionConfig *config))block {
    if (!self.started || ![event isKindOfClass:NSString.class] || event.length == 0) {
        return;
    }
    
    if (!ET_isPageOrElement(view)) {
        return;
    }
    
    EventTracingEventActionConfig *config = [EventTracingEventActionConfig configWithEvent:event];
    !block ?: block(config);
    EventTracingEventAction *action = [EventTracingEventAction actionWithEvent:event view:view];
    action.params = params;
    [action syncFromActionConfig:config];
    
    EventTracingVTreeNode *node = view.et_currentVTreeNode;
    EventTracingVTree *VTree = node.VTree;
    
    /// MARK: 比如点击事件，发生的时候，当前的VTree一定是生成好了的（因为不会有人可以点击那么快，快到VTree还没生成好）
    /// MARK: 如果该action.useForRefer==YES，node节点找不到，说明有问题，比如节点不可见，或者构建时被遮挡等等
    if (node && VTree) {
        [action setupNode:node VTree:VTree];
        [VTree syncNodeDynamicParamsForNode:node event:event];
        
        [self.ctx.eventEmitter consumeEventAction:action];
        return;
    }
    
    /// MARK: 当用户在一个非常早的时机触发自定义事件的时候，此时VTree可能还没生成好
    /// MARK: 只有当某一个事件不参与链路追踪，才会作为 stocked 暂存（否则前面已经尝试同步遍历一次了）
    /// MARK: 对一个不可见的节点发自定义事件，可能发不出来
    // 此时需要将该action放入待处理列表，等下次生成VTree后，再处理这个存量action列表
    [self.ctx.stockedEventActions addObject:action];
    
    // 打上需要遍历标识
    [self traverse];
    
    /// MARK: DEBUG => exception check
    [[EventTracingEngine sharedInstance].ctx.paramGuardExector asyncDoDispatchCheckTask:^{
        ET_CheckEventKeyValid(event);
        
        [params enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
            ET_CheckUserParamKeyValid(key);
        }];
    }];
}

#pragma mark - EventTracingEventEmitterDelegate
- (void)eventEmitter:(EventTracingEventEmitter *)eventEmitter
           emitEvent:(NSString *)event
       contextParams:(NSDictionary * _Nullable)contextParams
     logActionParams:(NSDictionary * _Nullable)logActionParams
                node:(EventTracingVTreeNode *)node
             inVTree:(EventTracingVTree *)VTree {
    [self.ctx.eventOutput outputEvent:event
                        contextParams:contextParams
                      logActionParams:logActionParams
                                 node:node
                              inVTree:VTree];
}

@end


@implementation EventTracingEngine (MergeLogForH5)

- (void)logWithEvent:(NSString *)event
            baseNode:(EventTracingVTreeNode *)baseNode
               elist:(NSArray<NSDictionary<NSString *,NSString *> *> *)elist
               plist:(NSArray<NSDictionary<NSString *,NSString *> *> *)plist
         positionKey:(NSString *)positionKey
              params:(NSDictionary<NSString *,NSString *> *)params
         eventAction:(void (^ NS_NOESCAPE)(EventTracingEventActionConfig * _Nonnull))block {
    if (event.length == 0 || !baseNode) {
        return;
    }
    
    BOOL useForRefer = NO;
    BOOL fromH5 = NO;
    if (block) {
        EventTracingEventActionConfig *config = [EventTracingEventActionConfig configWithEvent:event];
        block(config);
        
        useForRefer = config.useForRefer;
        fromH5 = config.fromH5;
    }
    
    [self.ctx.eventOutput outputEvent:event
                             baseNode:baseNode
                          useForRefer:useForRefer
                               fromH5:fromH5
                                elist:elist
                                plist:plist
                          positionKey:positionKey
                               params:params];
}

@end
