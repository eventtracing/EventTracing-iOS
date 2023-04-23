//
//  EventTracingEventOutput.m
//  BlocksKit
//
//  Created by dl on 2021/3/22.
//

#import "EventTracingEventOutput.h"
#import "EventTracingEventOutput+Private.h"
#import "NSArray+ETEnumerator.h"
#import "EventTracingEngine.h"
#import "EventTracingDefines.h"
#import "EventTracingParamGuardConfiguration.h"
#import "EventTracingEngine+Private.h"
#import "EventTracingVTreeNode+Private.h"
#import "EventTracingFormattedReferBuilder.h"
#import "EventTracingEventReferQueue.h"

@implementation EventTracingEventOutput
@synthesize formatter = _formatter;
@synthesize publicDynamicParamsProvider = _publicDynamicParamsProvider;

- (instancetype)init {
    self = [super init];
    if (self) {
        _outputChannels = [NSHashTable hashTableWithOptions:NSPointerFunctionsStrongMemory];
        _outputParamsFilters = [NSHashTable hashTableWithOptions:NSPointerFunctionsStrongMemory];
        _innerStaticPublicParams = [@{} mutableCopy];
        _innerCurrentActivePublicParams = [@{} mutableCopy];
    }
    return self;
}

- (void)outputEvent:(NSString *)event
      contextParams:(NSDictionary * _Nullable)contextParams
    logActionParams:(NSDictionary * _Nullable)logActionParams
               node:(EventTracingVTreeNode *)node
            inVTree:(EventTracingVTree *)VTree {
    NSMutableDictionary *resultJson = [@{} mutableCopy];
    
    NSDictionary *nodeParams = [self fulllyParamsForEvent:event
                                            contextParams:contextParams
                                          logActionParams:logActionParams
                                                     node:node
                                                  inVTree:VTree];
    if (nodeParams) {
        [resultJson addEntriesFromDictionary:nodeParams];
    }
    
    [self _doOutputToChannels:event node:node json:resultJson.copy];
}

- (void)outputEventWithoutNode:(NSString *)event contextParams:(NSDictionary * _Nullable)contextParams {
    NSMutableDictionary *resultJson = [@{} mutableCopy];
    
    NSDictionary *nodeParams = [self fulllyParamsForEvent:event
                                            contextParams:contextParams
                                          logActionParams:nil
                                                     node:nil
                                                  inVTree:nil];
    if (nodeParams) {
        [resultJson addEntriesFromDictionary:nodeParams];
    }
    
    ETDispatchMainAsyncSafe(^{
        [self _doOutputToChannels:event node:nil json:resultJson.copy];
    })
}

- (NSDictionary *)publicParamsForEvent:(NSString * _Nullable)event
                                  node:(EventTracingVTreeNode * _Nullable)node
                               inVTree:(EventTracingVTree * _Nullable)VTree  {
    NSMutableDictionary *publicParams = [@{} mutableCopy];
    if (self.staticPublicParmas) {
        [publicParams addEntriesFromDictionary:self.staticPublicParmas];
        [publicParams addEntriesFromDictionary:self.currentActivePublicParmas];
    }
    
    /// MARK: public dynamic params
    if ([self.publicDynamicParamsProvider respondsToSelector:@selector(outputPublicDynamicParamsForEvent:node:inVTree:)]) {
        NSDictionary *publicDynamicParams = [self.publicDynamicParamsProvider outputPublicDynamicParamsForEvent:event node:node inVTree:VTree];
        if (publicDynamicParams) {
            [[EventTracingEngine sharedInstance].ctx.paramGuardExector asyncDoDispatchCheckTask:^{
                [publicDynamicParams.allKeys enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    ET_CheckPublicParamKeyValid(obj);
                }];
            }];
            
            [publicParams addEntriesFromDictionary:publicDynamicParams];
        }
    }
    return publicParams.copy;
}

- (NSDictionary *)fulllyParamsForEvent:(NSString * _Nullable)event
                         contextParams:(NSDictionary * _Nullable)contextParams
                       logActionParams:(NSDictionary * _Nullable)logActionParams
                                  node:(EventTracingVTreeNode * _Nullable)node
                               inVTree:(EventTracingVTree * _Nullable)VTree {
    NSMutableDictionary *resultJson = [@{} mutableCopy];
    
    NSDictionary *formatedJson = nil;
    /// MARK: formatter
    if (node != nil && VTree != nil && [self.formatter respondsToSelector:@selector(formatWithEvent:logActionParams:node:inVTree:)]) {
        formatedJson = [self.formatter formatWithEvent:event logActionParams:logActionParams node:node inVTree:VTree];
    }
    if (formatedJson) {
        [resultJson addEntriesFromDictionary:formatedJson];
    }
    
    /// MARK: public static/dynamic params
    NSDictionary *publicParams = [self publicParamsForEvent:event node:node inVTree:VTree];
    [resultJson addEntriesFromDictionary:publicParams];
    
    /// MARK: 标识打出该埋点的时候是否是在后台
    [resultJson setValue:@(![EventTracingEngine sharedInstance].context.isAppInActive).stringValue forKey:ET_CONST_KEY_IB];
    
    /// MARK: context params
    if (contextParams.count) {
        [resultJson addEntriesFromDictionary:contextParams];
    }

    /// 整体的一个filter过滤
    return [self _filteredJsonWithEvent:event originalJson:resultJson.copy node:node inVTree:VTree];
}

#pragma mark - private methods
- (NSDictionary *)_filteredJsonWithEvent:(NSString *)event
                            originalJson:(NSDictionary *)originalJson
                                    node:(EventTracingVTreeNode *)node
                                 inVTree:(EventTracingVTree *)VTree {
    __block NSDictionary *filteredJson = originalJson.copy;
    [self.allParmasFilters enumerateObjectsUsingBlock:^(id<EventTracingOutputParamsFilter>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj respondsToSelector:@selector(filteredJsonWithEvent:originalJson:node:inVTree:)]) {
            filteredJson = [obj filteredJsonWithEvent:event originalJson:filteredJson node:node inVTree:VTree];
        }
    }];
    return filteredJson;
}

- (void)_doOutputToChannels:(NSString *)event node:(EventTracingVTreeNode * _Nullable)node json:(NSDictionary *)json {
    void(^block)(void) = ^(void) {
        [self.allOutputChannels enumerateObjectsUsingBlock:^(id<EventTracingEventOutputChannel>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj respondsToSelector:@selector(eventOutput:didOutputEvent:json:)]) {
                [obj eventOutput:self didOutputEvent:event json:json];
            }
            
            if ([obj respondsToSelector:@selector(eventOutput:didOutputEvent:node:json:)]) {
                [obj eventOutput:self didOutputEvent:event node:node json:json];
            }
        }];
    };
    ETDispatchMainAsyncSafe(block);
}

#pragma mark - EventTracingContextOutputFormatterBuilder
- (void) registeFormatter:(id<EventTracingOutputFormatter>)formatter {
    _formatter = formatter;
}

- (void)registePublicDynamicParamsProvider:(id<EventTracingOutputPublicDynamicParamsProvider>)publicDynamicParamsProvider {
    _publicDynamicParamsProvider = publicDynamicParamsProvider;
}

- (void)configStaticPublicParams:(NSDictionary<NSString *,NSString *> *)params {
    [self configStaticPublicParams:params withParamGuard:YES];
}
- (void)configStaticPublicParams:(NSDictionary<NSString *,NSString *> *)params withParamGuard:(BOOL)withParamGuard {
    [self.innerStaticPublicParams addEntriesFromDictionary:params];
    
    if (withParamGuard) {
        [[EventTracingEngine sharedInstance].ctx.paramGuardExector asyncDoDispatchCheckTask:^{
            [params.allKeys enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                ET_CheckPublicParamKeyValid(obj);
            }];
        }];
    }
}

- (void)configCurrentActivePublicParams:(NSDictionary<NSString *,NSString *> *)params withParamGuard:(BOOL)withParamGuard {
    [self.innerCurrentActivePublicParams addEntriesFromDictionary:params];
    
    if (withParamGuard) {
        [[EventTracingEngine sharedInstance].ctx.paramGuardExector asyncDoDispatchCheckTask:^{
            [params.allKeys enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                ET_CheckPublicParamKeyValid(obj);
            }];
        }];
    }
}

- (void)removeCurrentActivePublicParmas {
    [self.innerCurrentActivePublicParams removeAllObjects];
}

- (void)removeStaticPublicParamForKey:(NSString *)key {
    [self.innerStaticPublicParams removeObjectForKey:key];
}

- (void)addOutputChannel:(id<EventTracingEventOutputChannel>)outputChannel {
    [self.outputChannels addObject:outputChannel];
}

- (void)removeOutputChannel:(id<EventTracingEventOutputChannel>)outputChannel {
    [self.outputChannels removeObject:outputChannel];
}

- (void)removeAllOutputChannels {
    [self.outputChannels removeAllObjects];
}


#pragma mark - EventTracingContextOutputParamsFilterBuilder
- (void)addParamsFilter:(id<EventTracingOutputParamsFilter>)paramsFilter {
    [self.outputParamsFilters addObject:paramsFilter];
}

- (void)removeParamsFilter:(id<EventTracingOutputParamsFilter>)paramsFilter {
    [self.outputParamsFilters removeObject:paramsFilter];
}

- (void)removeAllParamsFilters {
    [self.outputParamsFilters removeAllObjects];
}

#pragma mark - getters
- (NSArray<id<EventTracingEventOutputChannel>> *)allOutputChannels {
    return self.outputChannels.allObjects;
}

- (NSArray<id<EventTracingOutputParamsFilter>> *)allParmasFilters {
    return self.outputParamsFilters.allObjects;
}

- (NSDictionary *)staticPublicParmas {
    return self.innerStaticPublicParams.copy;
}

- (NSDictionary *)currentActivePublicParmas {
    return self.innerCurrentActivePublicParams.copy;
}

@end

@implementation EventTracingEventOutput (MergeLogForH5)

- (void)outputEvent:(NSString *)event
           baseNode:(EventTracingVTreeNode *)baseNode
        useForRefer:(BOOL)useForRefer
             fromH5:(BOOL)fromH5
              elist:(NSArray<NSDictionary<NSString *,NSString *> *> *)elist
              plist:(NSArray<NSDictionary<NSString *,NSString *> *> *)plist
        positionKey:(NSString *)positionKey
             params:(NSDictionary<NSString *,NSString *> *)params {
    
    EventTracingVTreeNode *node = baseNode;
    EventTracingVTree *VTree = node.VTree;
    EventTracingVTreeNode *rootPageNode = [node findToppestNode:YES];
    BOOL needsIncreaseActseq = useForRefer;
    
    NSString *spm = [self _mergeLogH5_spmFromNode:node elist:elist plist:plist positionKey:positionKey];
    BOOL scmNeedsEncode = NO;
    NSString *scm = [self _mergeLogH5_scmFromNode:node elist:elist plist:plist needsEncode:&scmNeedsEncode];
    
    /// MARK: _pv 事件，需要plist第一个节点有 _pgstep, 并且需要 pgstep ++
    NSMutableArray<NSDictionary<NSString *,NSString *> *> *mutablePlist = (plist ?: @[]).mutableCopy;
    NSMutableArray<NSDictionary<NSString *,NSString *> *> *mutableElist = (elist ?: @[]).mutableCopy;
    if ([event isEqualToString:ET_EVENT_ID_P_VIEW] && plist.count > 0) {
        NSMutableDictionary *firstPDict = [mutablePlist.firstObject mutableCopy];
        
        /// MARK: _pgstep
        NSInteger pgstep = [[EventTracingEngine sharedInstance] pgstepIncreased];
        [firstPDict setObject:@(pgstep) forKey:ET_REFER_KEY_PGSTEP];
        
        [mutablePlist replaceObjectAtIndex:0 withObject:firstPDict.copy];
        
        needsIncreaseActseq = YES;
    }
    
    /// MARK: append baseNode elist & plist
    NSDictionary *formatedJson = nil;
    /// MARK: formatter
    if ([self.formatter respondsToSelector:@selector(formatWithEvent:logActionParams:node:inVTree:)]) {
        formatedJson = [self.formatter formatWithEvent:event logActionParams:params node:node inVTree:VTree];
    }
    
    /// MARK: make json
    NSMutableDictionary *json = [formatedJson ?: @{} mutableCopy];
    if (![json.allKeys containsObject:ET_REFER_KEY_HSREFER]) {
        NSString *hsrefer = [EventTracingEngine sharedInstance].context.hsrefer;
        if (hsrefer.length) {
            [json setObject:hsrefer forKey:ET_REFER_KEY_HSREFER];
        }
    }
    
    NSArray<NSDictionary<NSString *,NSString *> *> *nodeElist = [json objectForKey:@"_elist"] ?: @[];
    NSArray<NSDictionary<NSString *,NSString *> *> *nodePlist = [json objectForKey:@"_plist"] ?: @[];
    
    [mutableElist addObjectsFromArray:nodeElist];
    [mutablePlist addObjectsFromArray:nodePlist];
    
    [json setObject:mutableElist.copy forKey:ET_CONST_KEY_ELIST];
    [json setObject:mutablePlist.copy forKey:ET_CONST_KEY_PLIST];
    
    [json setObject:spm forKey:ET_REFER_KEY_SPM];
    [json setObject:scm forKey:ET_REFER_KEY_SCM];
    if (scmNeedsEncode) {
        [json setObject:@"1" forKey:ET_REFER_KEY_SCM_ER];
    }
    
    NSDictionary *publicParams = [self publicParamsForEvent:event node:node inVTree:VTree];
    [json addEntriesFromDictionary:publicParams];
    
    /// MARK: 标识打出该埋点的时候是否是在后台
    [json setValue:@(![EventTracingEngine sharedInstance].context.isAppInActive).stringValue forKey:ET_CONST_KEY_IB];
    
    /// MARK: _actseq
    NSInteger actseq = 0;
    if (needsIncreaseActseq) {
        actseq = [rootPageNode doIncreaseActseq];
        [json setObject:@(actseq) forKey:ET_REFER_KEY_ACTSEQ];
    }
    
    /// 整体的一个filter过滤
    NSDictionary *resultJson = [self _filteredJsonWithEvent:event originalJson:json.copy node:node inVTree:VTree];
    [self _doOutputToChannels:event node:node json:resultJson.copy];
    
    /// MARK: useForRefer => 生成refer
    if (!useForRefer) {
        return;
    }
    
    id<EventTracingFormattedRefer> formattedRefer = [EventTracingFormattedReferBuilder build:^(id<EventTracingFormattedReferComponentBuilder>  _Nonnull builder) {
        builder
        .type(elist.count > 0 ? ET_REFER_KEY_E : ET_REFER_KEY_P)
        .actseq(actseq)
        .pgstep(rootPageNode.pgstep)
        .spm(spm)
        .scm(scm);
        
        if (scmNeedsEncode) {
            builder.er();
        }
        
        if (fromH5) {
            builder.h5();
        }
    }].generateRefer;
    
    EventTracingFormattedEventRefer *refer = [EventTracingFormattedEventRefer referWithEvent:event
                                                                                  formattedRefer:formattedRefer
                                                                                      rootPagePV:NO
                                                                              shouldStartHsrefer:NO
                                                                              isNodePsreferMuted:NO];
    [[EventTracingEventReferQueue queue] pushEventRefer:refer node:node isSubPage:NO];
}

- (NSString *)_mergeLogH5_spmFromNode:(EventTracingVTreeNode *)node
                                elist:(NSArray<NSDictionary<NSString *,NSString *> *> *)elist
                                plist:(NSArray<NSDictionary<NSString *,NSString *> *> *)plist
                          positionKey:(NSString *)positionKey {
    NSMutableString *spm = @"".mutableCopy;
    void(^appendSPMComponents)(NSDictionary<NSString *,NSString *> * _Nonnull, NSUInteger idx, BOOL * _Nonnull) = ^(NSDictionary<NSString *,NSString *> * _Nonnull dict, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *oid = [dict objectForKey:@"_oid"];
        NSInteger pos = [[dict objectForKey:positionKey] integerValue];
        if ([oid isKindOfClass:NSString.class] && oid.length != 0) {
            if (spm.length != 0) {
                [spm appendString:@"|"];
            }
            [spm appendString:oid];
            if (pos > 0) {
                [spm appendFormat:@":%@", @(pos).stringValue];
            }
        }
    };
    
    [elist enumerateObjectsUsingBlock:appendSPMComponents];
    [plist enumerateObjectsUsingBlock:appendSPMComponents];
    
    [spm appendFormat:@"|%@", node.spm];
    
    return spm.copy;
}

- (NSString *)_mergeLogH5_scmFromNode:(EventTracingVTreeNode *)node
                                elist:(NSArray<NSDictionary<NSString *,NSString *> *> *)elist
                                plist:(NSArray<NSDictionary<NSString *,NSString *> *> *)plist
                          needsEncode:(BOOL *)needsEncode {
    NSMutableString *scm = @"".mutableCopy;
    
    __block BOOL shouldEncode = NO;
    void(^appendSCMComponents)(NSDictionary<NSString *,NSString *> * _Nonnull, NSUInteger idx, BOOL * _Nonnull) = ^(NSDictionary<NSString *,NSString *> * _Nonnull dict, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *value = [[EventTracingEngine sharedInstance].ctx.referNodeSCMFormatter nodeSCMWithNodeParams:dict];
        shouldEncode = shouldEncode || [[EventTracingEngine sharedInstance] .ctx.referNodeSCMFormatter needsEncodeSCMForNodeParams:dict];
        
        if (scm.length != 0) {
            [scm appendString:@"|"];
        }
        [scm appendString:value];
    };
    
    [elist enumerateObjectsUsingBlock:appendSCMComponents];
    [plist enumerateObjectsUsingBlock:appendSCMComponents];
    
    [scm appendFormat:@"|%@", node.scm];
    
    shouldEncode = shouldEncode || node.isSCMNeedsER;
    
    if (shouldEncode) {
        *needsEncode = YES;
    }
    
    return scm.copy;
}

@end
