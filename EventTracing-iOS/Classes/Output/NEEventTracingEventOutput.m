//
//  NEEventTracingEventOutput.m
//  BlocksKit
//
//  Created by dl on 2021/3/22.
//

#import "NEEventTracingEventOutput.h"
#import "NEEventTracingEventOutput+Private.h"
#import "NSArray+ETEnumerator.h"
#import "NEEventTracingEngine.h"
#import "NEEventTracingDefines.h"
#import "NEEventTracingParamGuardConfiguration.h"
#import "NEEventTracingEngine+Private.h"
#import "NEEventTracingVTreeNode+Private.h"
#import "NEEventTracingFormattedReferBuilder.h"
#import "NEEventTracingEventReferQueue.h"
#include <pthread/pthread.h>


#define NEET_WR_LOCK(...) \
pthread_rwlock_wrlock(&self->_lock); \
__VA_ARGS__; \
pthread_rwlock_unlock(&self->_lock);

#define NEET_RD_LOCK(...) \
pthread_rwlock_rdlock(&self->_lock); \
__VA_ARGS__; \
pthread_rwlock_unlock(&self->_lock);


@implementation NEEventTracingEventOutput {
    pthread_rwlock_t _lock;
}
@synthesize formatter = _formatter;
@synthesize publicDynamicParamsProvider = _publicDynamicParamsProvider;

- (void)dealloc
{
    pthread_rwlock_destroy(&self->_lock);
}
        
- (instancetype)init {
    self = [super init];
    if (self) {
        _lock = (pthread_rwlock_t)PTHREAD_RWLOCK_INITIALIZER;
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
               node:(NEEventTracingVTreeNode *)node
            inVTree:(NEEventTracingVTree *)VTree {
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
    
    NEETDispatchMainAsyncSafe(^{
        [self _doOutputToChannels:event node:nil json:resultJson.copy];
    })
}

- (NSDictionary *)publicParamsForEvent:(NSString * _Nullable)event
                                  node:(NEEventTracingVTreeNode * _Nullable)node
                               inVTree:(NEEventTracingVTree * _Nullable)VTree  {
    NSMutableDictionary *publicParams = [@{} mutableCopy];
    if (self.staticPublicParmas) {
        [publicParams addEntriesFromDictionary:self.staticPublicParmas];
        [publicParams addEntriesFromDictionary:self.currentActivePublicParmas];
    }
    
    /// MARK: public dynamic params
    if ([self.publicDynamicParamsProvider respondsToSelector:@selector(outputPublicDynamicParamsForEvent:node:inVTree:)]) {
        NSDictionary *publicDynamicParams = [self.publicDynamicParamsProvider outputPublicDynamicParamsForEvent:event node:node inVTree:VTree];
        if (publicDynamicParams) {
            [[NEEventTracingEngine sharedInstance].ctx.paramGuardExector asyncDoDispatchCheckTask:^{
                [publicDynamicParams.allKeys enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    NE_ET_CheckPublicParamKeyValid(obj);
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
                                  node:(NEEventTracingVTreeNode * _Nullable)node
                               inVTree:(NEEventTracingVTree * _Nullable)VTree {
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
    [resultJson setValue:@(![NEEventTracingEngine sharedInstance].context.isAppInActive).stringValue forKey:NE_ET_CONST_KEY_IB];
    
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
                                    node:(NEEventTracingVTreeNode *)node
                                 inVTree:(NEEventTracingVTree *)VTree {
    __block NSDictionary *filteredJson = originalJson.copy;
    [self.allParmasFilters enumerateObjectsUsingBlock:^(id<NEEventTracingOutputParamsFilter>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj respondsToSelector:@selector(filteredJsonWithEvent:originalJson:node:inVTree:)]) {
            filteredJson = [obj filteredJsonWithEvent:event originalJson:filteredJson node:node inVTree:VTree];
        }
    }];
    return filteredJson;
}

- (void)_doOutputToChannels:(NSString *)event node:(NEEventTracingVTreeNode * _Nullable)node json:(NSDictionary *)json {
    void(^block)(void) = ^(void) {
        [self.allOutputChannels enumerateObjectsUsingBlock:^(id<NEEventTracingEventOutputChannel>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj respondsToSelector:@selector(eventOutput:didOutputEvent:json:)]) {
                [obj eventOutput:self didOutputEvent:event json:json];
            }
            
            if ([obj respondsToSelector:@selector(eventOutput:didOutputEvent:node:json:)]) {
                [obj eventOutput:self didOutputEvent:event node:node json:json];
            }
        }];
    };
    NEETDispatchMainAsyncSafe(block);
}

#pragma mark - NEEventTracingContextOutputFormatterBuilder
- (void) registeFormatter:(id<NEEventTracingOutputFormatter>)formatter {
    _formatter = formatter;
}

- (void)registePublicDynamicParamsProvider:(id<NEEventTracingOutputPublicDynamicParamsProvider>)publicDynamicParamsProvider {
    _publicDynamicParamsProvider = publicDynamicParamsProvider;
}

- (void)configStaticPublicParams:(NSDictionary<NSString *,NSString *> *)params {
    [self configStaticPublicParams:params withParamGuard:YES];
}
- (void)configStaticPublicParams:(NSDictionary<NSString *,NSString *> *)params withParamGuard:(BOOL)withParamGuard {
    [self.innerStaticPublicParams addEntriesFromDictionary:params];
    
    if (withParamGuard) {
        [[NEEventTracingEngine sharedInstance].ctx.paramGuardExector asyncDoDispatchCheckTask:^{
            [params.allKeys enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                NE_ET_CheckPublicParamKeyValid(obj);
            }];
        }];
    }
}

- (void)configCurrentActivePublicParams:(NSDictionary<NSString *,NSString *> *)params withParamGuard:(BOOL)withParamGuard {
    [self.innerCurrentActivePublicParams addEntriesFromDictionary:params];
    
    if (withParamGuard) {
        [[NEEventTracingEngine sharedInstance].ctx.paramGuardExector asyncDoDispatchCheckTask:^{
            [params.allKeys enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                NE_ET_CheckPublicParamKeyValid(obj);
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

- (void)addOutputChannel:(id<NEEventTracingEventOutputChannel>)outputChannel {
    NEET_WR_LOCK(
    [self.outputChannels addObject:outputChannel];
    )
}

- (void)removeOutputChannel:(id<NEEventTracingEventOutputChannel>)outputChannel {
    NEET_WR_LOCK(
    [self.outputChannels removeObject:outputChannel];
    )
}

- (void)removeAllOutputChannels {
    NEET_WR_LOCK(
    [self.outputChannels removeAllObjects];
    )
}


#pragma mark - NEEventTracingContextOutputParamsFilterBuilder
- (void)addParamsFilter:(id<NEEventTracingOutputParamsFilter>)paramsFilter {
    [self.outputParamsFilters addObject:paramsFilter];
}

- (void)removeParamsFilter:(id<NEEventTracingOutputParamsFilter>)paramsFilter {
    [self.outputParamsFilters removeObject:paramsFilter];
}

- (void)removeAllParamsFilters {
    [self.outputParamsFilters removeAllObjects];
}

#pragma mark - getters
- (NSArray<id<NEEventTracingEventOutputChannel>> *)allOutputChannels {
    NSArray<id<NEEventTracingEventOutputChannel>> * allChannels;
    NEET_RD_LOCK( allChannels = self.outputChannels.allObjects; )
    return allChannels;
}

- (NSArray<id<NEEventTracingOutputParamsFilter>> *)allParmasFilters {
    return self.outputParamsFilters.allObjects;
}

- (NSDictionary *)staticPublicParmas {
    return self.innerStaticPublicParams.copy;
}

- (NSDictionary *)currentActivePublicParmas {
    return self.innerCurrentActivePublicParams.copy;
}

@end

@implementation NEEventTracingEventOutput (MergeLogForH5)

- (void)outputEvent:(NSString *)event
           baseNode:(NEEventTracingVTreeNode *)baseNode
        useForRefer:(BOOL)useForRefer
             fromH5:(BOOL)fromH5
              elist:(NSArray<NSDictionary<NSString *,NSString *> *> *)elist
              plist:(NSArray<NSDictionary<NSString *,NSString *> *> *)plist
        positionKey:(NSString *)positionKey
             params:(NSDictionary<NSString *,NSString *> *)params {
    
    NEEventTracingVTreeNode *node = baseNode;
    NEEventTracingVTree *VTree = node.VTree;
    NEEventTracingVTreeNode *rootPageNode = [node findToppestNode:YES];
    BOOL needsIncreaseActseq = useForRefer;
    
    NSString *spm = [self _mergeLogH5_spmFromNode:node elist:elist plist:plist positionKey:positionKey];
    BOOL scmNeedsEncode = NO;
    NSString *scm = [self _mergeLogH5_scmFromNode:node elist:elist plist:plist needsEncode:&scmNeedsEncode];
    
    /// MARK: _pv 事件，需要plist第一个节点有 _pgstep, 并且需要 pgstep ++
    NSMutableArray<NSDictionary<NSString *,NSString *> *> *mutablePlist = (plist ?: @[]).mutableCopy;
    NSMutableArray<NSDictionary<NSString *,NSString *> *> *mutableElist = (elist ?: @[]).mutableCopy;
    if ([event isEqualToString:NE_ET_EVENT_ID_P_VIEW] && plist.count > 0) {
        NSMutableDictionary *firstPDict = [mutablePlist.firstObject mutableCopy];
        
        /// MARK: _pgstep
        NSInteger pgstep = [[NEEventTracingEngine sharedInstance] pgstepIncreased];
        [firstPDict setObject:@(pgstep) forKey:NE_ET_REFER_KEY_PGSTEP];
        
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
    if (![json.allKeys containsObject:NE_ET_REFER_KEY_HSREFER]) {
        NSString *hsrefer = [NEEventTracingEngine sharedInstance].context.hsrefer;
        if (hsrefer.length) {
            [json setObject:hsrefer forKey:NE_ET_REFER_KEY_HSREFER];
        }
    }
    
    NSArray<NSDictionary<NSString *,NSString *> *> *nodeElist = [json objectForKey:@"_elist"] ?: @[];
    NSArray<NSDictionary<NSString *,NSString *> *> *nodePlist = [json objectForKey:@"_plist"] ?: @[];
    
    [mutableElist addObjectsFromArray:nodeElist];
    [mutablePlist addObjectsFromArray:nodePlist];
    
    [json setObject:mutableElist.copy forKey:NE_ET_CONST_KEY_ELIST];
    [json setObject:mutablePlist.copy forKey:NE_ET_CONST_KEY_PLIST];
    
    [json setObject:spm forKey:NE_ET_REFER_KEY_SPM];
    [json setObject:scm forKey:NE_ET_REFER_KEY_SCM];
    if (scmNeedsEncode) {
        [json setObject:@"1" forKey:NE_ET_REFER_KEY_SCM_ER];
    }
    
    NSDictionary *publicParams = [self publicParamsForEvent:event node:node inVTree:VTree];
    [json addEntriesFromDictionary:publicParams];
    
    /// MARK: 标识打出该埋点的时候是否是在后台
    [json setValue:@(![NEEventTracingEngine sharedInstance].context.isAppInActive).stringValue forKey:NE_ET_CONST_KEY_IB];
    
    /// MARK: _actseq
    NSInteger actseq = 0;
    if (needsIncreaseActseq) {
        actseq = [rootPageNode doIncreaseActseq];
        [json setObject:@(actseq) forKey:NE_ET_REFER_KEY_ACTSEQ];
    }
    
    /// 整体的一个filter过滤
    NSDictionary *resultJson = [self _filteredJsonWithEvent:event originalJson:json.copy node:node inVTree:VTree];
    [self _doOutputToChannels:event node:node json:resultJson.copy];
    
    /// MARK: useForRefer => 生成refer
    if (!useForRefer) {
        return;
    }
    
    id<NEEventTracingFormattedRefer> formattedRefer = [NEEventTracingFormattedReferBuilder build:^(id<NEEventTracingFormattedReferComponentBuilder>  _Nonnull builder) {
        builder
        .type(elist.count > 0 ? NE_ET_REFER_KEY_E : NE_ET_REFER_KEY_P)
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
    
    NEEventTracingFormattedEventRefer *refer = [NEEventTracingFormattedEventRefer referWithEvent:event
                                                                                  formattedRefer:formattedRefer
                                                                                      rootPagePV:NO
                                                                              shouldStartHsrefer:NO
                                                                              isNodePsreferMuted:NO];
    [[NEEventTracingEventReferQueue queue] pushEventRefer:refer node:node isSubPage:NO];
}

- (NSString *)_mergeLogH5_spmFromNode:(NEEventTracingVTreeNode *)node
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

- (NSString *)_mergeLogH5_scmFromNode:(NEEventTracingVTreeNode *)node
                                elist:(NSArray<NSDictionary<NSString *,NSString *> *> *)elist
                                plist:(NSArray<NSDictionary<NSString *,NSString *> *> *)plist
                          needsEncode:(BOOL *)needsEncode {
    NSMutableString *scm = @"".mutableCopy;
    
    __block BOOL shouldEncode = NO;
    void(^appendSCMComponents)(NSDictionary<NSString *,NSString *> * _Nonnull, NSUInteger idx, BOOL * _Nonnull) = ^(NSDictionary<NSString *,NSString *> * _Nonnull dict, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *value = [[NEEventTracingEngine sharedInstance].ctx.referNodeSCMFormatter nodeSCMWithNodeParams:dict];
        shouldEncode = shouldEncode || [[NEEventTracingEngine sharedInstance] .ctx.referNodeSCMFormatter needsEncodeSCMForNodeParams:dict];
        
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
