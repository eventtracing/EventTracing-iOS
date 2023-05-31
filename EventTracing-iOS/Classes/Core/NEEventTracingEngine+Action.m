//
//  NEEventTracingEngine+Action.m
//  BlocksKit
//
//  Created by dl on 2021/3/23.
//

#import "NEEventTracingEngine+Action.h"
#import "NEEventTracingEngine+Private.h"
#import "UIView+EventTracingPrivate.h"
#import "NEEventTracingContext+Private.h"
#import "NEEventTracingEventOutput+Private.h"
#import "NEEventTracingVTree+Sync.h"
#import "NEEventTracingVTreeNode+Private.h"
#import "NEEventTracingEventActionConfig+Private.h"
#import "NEEventTracingParamGuardConfiguration.h"
#import "NEEventTracingEventReferQueue.h"
#import "NSArray+ETEnumerator.h"
#import "NEEventTracingFormattedReferBuilder.h"
#import "NEEventTracingEventRefer+Private.h"
#import <BlocksKit/BlocksKit.h>
#import "NSString+EventTracingUtil.h"

@implementation NEEventTracingEngine (Action)

#pragma mark - Log
- (void)logSimplyWithEvent:(NSString *)event
                    params:(NSDictionary *)params {
    if (![event isKindOfClass:[NSString class]] || event.length == 0) {
        return;
    }
    
    NSMutableDictionary *mutableParams = [(params ?: @{}) mutableCopy];
    if (![params.allKeys containsObject:NE_ET_REFER_KEY_HSREFER]) {
        NSString *hsrefer = [NEEventTracingEngine sharedInstance].context.hsrefer;
        if (hsrefer.length) {
            [mutableParams setObject:hsrefer forKey:NE_ET_REFER_KEY_HSREFER];
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
    
    [mutableParams setObject:@(self.context.actseq).stringValue forKey:NE_ET_REFER_KEY_ACTSEQ];
    
    [self logSimplyWithEvent:event params:mutableParams.copy];
    
    /// MARK: refer => queue
    id<NEEventTracingFormattedRefer> formattedRefer = [NEEventTracingFormattedReferBuilder build:^(id<NEEventTracingFormattedReferComponentBuilder>  _Nonnull builder) {
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
        
        if ([scm ne_et_hasBeenUrlEncoded]) {
            builder.er();
        }
    }].generateRefer;
    
    NEEventTracingFormattedEventRefer *refer = [NEEventTracingFormattedEventRefer referWithEvent:event
                                                                                  formattedRefer:formattedRefer
                                                                                      rootPagePV:NO
                                                                              shouldStartHsrefer:NO
                                                                              isNodePsreferMuted:NO];
    [[NEEventTracingEventReferQueue queue] pushEventRefer:refer];
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
         eventAction:(void(^ NS_NOESCAPE _Nullable)(NEEventTracingEventActionConfig *config))block {
    /// MARK: 1. do pre (ignore buildin disable click)
    NEEventTracingEventActionConfig *config = [NEEventTracingEventActionConfig configWithEvent:event];
    !block ?: block(config);
    
    UIView *pipFixedView = [view.ne_et_pipEventToView objectForKey:event] ?: view;
    [self _preLogPushReferWithEvent:event view:pipFixedView useForRefer:config.useForRefer useNextActseq:config.increaseActseq];
    
    /// MARK: 2. do after (ignore buildin disable click)
    [self _afterLogWithEvent:event view:pipFixedView params:params eventAction:block];
}

- (void)AOP_preLogWithEvent:(NSString *)event view:(UIView *)view {
    [self AOP_preLogWithEvent:event view:view eventAction:nil];
}

- (void)AOP_preLogWithEvent:(NSString *)event
                       view:(UIView *)view
                eventAction:(void(^ NS_NOESCAPE _Nullable)(NEEventTracingEventActionConfig *config))block {
    UIView *pipFixedView = [view.ne_et_pipEventToView objectForKey:event] ?: view;

    if ([event isEqualToString:NE_ET_EVENT_ID_E_CLCK]
        && pipFixedView.ne_et_buildinEventLogDisableStrategy & NEETNodeBuildinEventLogDisableStrategyClick) {
        return;
    }
    
    NEEventTracingEventActionConfig *config = [NEEventTracingEventActionConfig configWithEvent:event];
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
             eventAction:(void(^ NS_NOESCAPE _Nullable)(NEEventTracingEventActionConfig *config))block {
    
    UIView *pipFixedView = [view.ne_et_pipEventToView objectForKey:event] ?: view;
    if ([event isEqualToString:NE_ET_EVENT_ID_E_CLCK]
        && pipFixedView.ne_et_buildinEventLogDisableStrategy & NEETNodeBuildinEventLogDisableStrategyClick) {
        return;
    }
    
    [self _afterLogWithEvent:event view:pipFixedView params:params eventAction:block];
}

- (void)flushStockedActionsIfNeeded:(NEEventTracingVTree *)VTree {
    NSArray<NEEventTracingEventAction *> *stockedEventActions = self.ctx.stockedEventActions.copy;
    [self.ctx.stockedEventActions removeAllObjects];
    
    [stockedEventActions enumerateObjectsUsingBlock:^(NEEventTracingEventAction * _Nonnull action, NSUInteger idx, BOOL * _Nonnull stop) {
        [action setupNode:action.view.ne_et_currentVTreeNode VTree:VTree];
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
        && NE_ET_isPageOrElement(view)
        && view.ne_et_currentVTreeNode == nil
        && [view ne_et_isSimpleVisible]) {
        [self traverseImmediatelyIfNeeded];
    }
    
    [[NEEventTracingEventReferQueue queue] pushEventReferForEvent:event
                                                             view:view
                                                             node:view.ne_et_currentVTreeNode
                                                      useForRefer:useForRefer
                                                    useNextActseq:useNextActseq];
}

- (void)_afterLogWithEvent:(NSString *)event
                      view:(UIView *)view
                    params:(NSDictionary<NSString *,NSString *> *)params
               eventAction:(void(^ NS_NOESCAPE _Nullable)(NEEventTracingEventActionConfig *config))block {
    if (!self.started || ![event isKindOfClass:NSString.class] || event.length == 0) {
        return;
    }
    
    if (!NE_ET_isPageOrElement(view)) {
        return;
    }
    
    NEEventTracingEventActionConfig *config = [NEEventTracingEventActionConfig configWithEvent:event];
    !block ?: block(config);
    NEEventTracingEventAction *action = [NEEventTracingEventAction actionWithEvent:event view:view];
    action.params = params;
    [action syncFromActionConfig:config];
    
    NEEventTracingVTreeNode *node = view.ne_et_currentVTreeNode;
    NEEventTracingVTree *VTree = node.VTree;
    
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
    [[NEEventTracingEngine sharedInstance].ctx.paramGuardExector asyncDoDispatchCheckTask:^{
        NE_ET_CheckEventKeyValid(event);
        
        [params enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
            NE_ET_CheckUserParamKeyValid(key);
        }];
    }];
}

#pragma mark - NEEventTracingEventEmitterDelegate
- (void)eventEmitter:(NEEventTracingEventEmitter *)eventEmitter
           emitEvent:(NSString *)event
       contextParams:(NSDictionary * _Nullable)contextParams
     logActionParams:(NSDictionary * _Nullable)logActionParams
                node:(NEEventTracingVTreeNode *)node
             inVTree:(NEEventTracingVTree *)VTree {
    [self.ctx.eventOutput outputEvent:event
                        contextParams:contextParams
                      logActionParams:logActionParams
                                 node:node
                              inVTree:VTree];
}

@end


@implementation NEEventTracingEngine (MergeLogForH5)

- (void)logWithEvent:(NSString *)event
            baseNode:(NEEventTracingVTreeNode *)baseNode
               elist:(NSArray<NSDictionary<NSString *,NSString *> *> *)elist
               plist:(NSArray<NSDictionary<NSString *,NSString *> *> *)plist
         positionKey:(NSString *)positionKey
              params:(NSDictionary<NSString *,NSString *> *)params
         eventAction:(void (^ NS_NOESCAPE)(NEEventTracingEventActionConfig * _Nonnull))block {
    if (event.length == 0 || !baseNode) {
        return;
    }
    
    BOOL useForRefer = NO;
    BOOL fromH5 = NO;
    if (block) {
        NEEventTracingEventActionConfig *config = [NEEventTracingEventActionConfig configWithEvent:event];
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
