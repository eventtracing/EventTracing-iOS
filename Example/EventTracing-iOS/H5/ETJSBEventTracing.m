//
//  ETJSBEventTracing.m
//  EventTracing-iOS_Example
//
//  Created by dl on 2022/12/27.
//  Copyright © 2022 9446796. All rights reserved.
//

#import "ETWebViewBridgeManager.h"
#import <EventTracing/NEEventTracing.h>
#import <BlocksKit/BlocksKit.h>
#import <EventTracing/NEEventTracingMultiReferPatch.h>

@interface ETJSBEventTracing : ETWebViewBridgeModule <NEEventTracingVTreeObserver>
@property(nonatomic, strong) NEEventTracingVTree *containerVTreeCopy;
@property(nonatomic, strong) NEEventTracingVTreeNode *containerVTreeNodeCopy;
@end

@implementation ETJSBEventTracing

ETWEBKIT_BRIDGE_MODULE_EXPORT(eventTracing)

- (instancetype)init {
    self = [super init];
    if (self) {
        [[NEEventTracingEngine sharedInstance] addVTreeObserver:self];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self _didGenerageVTree:[NEEventTracingEngine sharedInstance].context.currentVTree];
        });
    }
    return self;
}

/// MARK: for test
ETWEBKIT_BRIDGE_MODULE_METHDO_EXPORT(test) {
    NSLog(@"%@", context.params);
    
    callback(nil, @{@"success": @YES});
}

ETWEBKIT_BRIDGE_MODULE_METHDO_EXPORT(report) {
    NEEventTracingVTreeNode *VTreeNode = [self _doFetchNodeAndCheckBeforeReportForContext:context callback:callback];
    if (!VTreeNode) {
        return;
    }
    
    NSString *event = [context.params objectForKey:@"event"];
    BOOL useForRefer = [[context.params objectForKey:@"useForRefer"] boolValue];
    NSArray<NSDictionary<NSString *, NSString *> *> *elist = [context.params objectForKey:@"_elist"];
    NSArray<NSDictionary<NSString *, NSString *> *> *plist = [context.params objectForKey:@"_plist"];
    NSMutableDictionary *params = ((NSDictionary *)[context.params objectForKey:@"params"] ?: @{}).mutableCopy;
    [params setObject:@"h5" forKey:@"_rpc_source"];
    
    if (event.length == 0) {
        callback(@{@"code": @(ETWebViewBridgeCodeInvalidParams)}, [NSError et_webkit_errorParamsWithMessage:@"event 不能为空"]);
        return;
    }
    
    [[NEEventTracingEngine sharedInstance] logWithEvent:event
                                               baseNode:VTreeNode
                                                  elist:elist
                                                  plist:plist
                                            positionKey:@"s_position"
                                                 params:params.copy
                                            eventAction:^(NEEventTracingEventActionConfig * _Nonnull config) {
        config.useForRefer = useForRefer;
        config.fromH5 = YES;
    }];
    
    callback(@{@"code": @(ETWebViewBridgeCodeSuccess)}, nil);
}

ETWEBKIT_BRIDGE_MODULE_METHDO_EXPORT(reportBatch) {
    NEEventTracingVTreeNode *VTreeNode = [self _doFetchNodeAndCheckBeforeReportForContext:context callback:callback];
    if (!VTreeNode) {
        return;
    }
    
    __block NSInteger validCount = 0;
    [[(NSArray *)[context.params objectForKey:@"logs"] bk_reject:^BOOL(id obj) {
        return ![obj isKindOfClass:NSDictionary.class];
    }] enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *event = [obj objectForKey:@"event"];
        
        if (event.length == 0) {
            return;
        }
        
        BOOL useForRefer = [[obj objectForKey:@"useForRefer"] boolValue];
        NSArray<NSDictionary<NSString *, NSString *> *> *elist = [obj objectForKey:@"_elist"];
        NSArray<NSDictionary<NSString *, NSString *> *> *plist = [obj objectForKey:@"_plist"];
        NSMutableDictionary *params = ((NSDictionary *)[obj objectForKey:@"params"] ?: @{}).mutableCopy;
        [params setObject:@"h5" forKey:@"_rpc_source"];
        
        [[NEEventTracingEngine sharedInstance] logWithEvent:event
                                                   baseNode:VTreeNode
                                                      elist:elist
                                                      plist:plist
                                                positionKey:@"s_position"
                                                     params:params.copy
                                                eventAction:^(NEEventTracingEventActionConfig * _Nonnull config) {
            config.useForRefer = useForRefer;
            config.fromH5 = YES;
        }];
        
        validCount ++;
    }];
    
    if (validCount == 0) {
        callback(@{@"code": @(ETWebViewBridgeCodeInvalidParams)}, [NSError et_webkit_errorParamsWithMessage:@"event 不能为空"]);
        return;
    }
    
    callback(@{@"code": @(ETWebViewBridgeCodeSuccess)}, nil);
}

ETWEBKIT_BRIDGE_MODULE_METHDO_EXPORT(refers) {
    if (![NEEventTracingEngine sharedInstance].context.started) {
        callback(@{@"code": @(ETWebViewBridgeCodeNotFound)}, [NSError et_webkit_errorWithMessage:@"EventTracing not started." code:ETWebViewBridgeCodeNotFound]);
        return;
    }
    
    NSString *k_all = @"all";
    NSString *k_sessid = @"sessid";
    NSString *k_sidrefer = @"sidrefer";
    NSString *k_eventrefer = @"eventrefer";
    NSString *k_multirefers = @"multirefers";
    NSString *k_hsrefer = @"hsrefer";

    NSString *keyString = [context.params objectForKey:@"key"] ?: k_all;
    
    NSArray<NSString *> *allKeys = @[k_sessid, k_sidrefer, k_eventrefer, k_multirefers, k_hsrefer];
    NSArray<NSString *> *keys = allKeys;
    if (![keyString isEqualToString:k_all]) {
        NSMutableArray<NSString *> *mkeys = @[].mutableCopy;
        [[keyString componentsSeparatedByString:@","] enumerateObjectsUsingBlock:^(NSString * _Nonnull key, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *trimKey = [key stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            if ([allKeys containsObject:trimKey] && ![mkeys containsObject:trimKey]) {
                [mkeys addObject:trimKey];
            }
        }];
        keys = mkeys.copy;
    }
    
    NSMutableDictionary<NSString *, NSString *> *refers = @{}.mutableCopy;
    // 1. sessid
    if ([keys containsObject:k_sessid]) {
        [refers setObject:[NEEventTracingEngine sharedInstance].context.sessid forKey:k_sessid];
    }
    
    // 2. sidrefer
    if ([keys containsObject:k_sidrefer]) {
        [refers setObject:[NEEventTracingEngine sharedInstance].context.sidrefer forKey:k_sidrefer];
    }
    
    // 3. eventrefer
    if ([keys containsObject:k_eventrefer]) {
        id<NEEventTracingEventRefer> lastestAutoEventRefer = NE_ET_lastestAutoEventRefer();
        id<NEEventTracingEventRefer> lastestAOPAutoEventSPMRefer = NE_ET_lastestUndefinedXpathRefer();
        
        [refers setObject:lastestAutoEventRefer.refer forKey:k_eventrefer];
        
        if (lastestAOPAutoEventSPMRefer.eventTime > lastestAutoEventRefer.eventTime) {
            [refers setObject:lastestAOPAutoEventSPMRefer.refer forKey:@"undefinedEventRefer"];
        }
    }
    
    // 4. multirefers
    if ([keys containsObject:k_multirefers]) {
        [refers setObject:[NEEventTracingMultiReferPatch sharedPatch].multiRefersJsonString forKey:k_multirefers];
    }
    
    // 5. hsrefer
    if ([keys containsObject:k_hsrefer]) {
        [refers setObject:([NEEventTracingEngine sharedInstance].context.hsrefer ?: @"") forKey:k_hsrefer];
    }
    
    callback(@{@"code": @(ETWebViewBridgeCodeSuccess), @"refers": refers.copy}, nil);
}

#pragma mark -
#pragma mark - Observer
- (void)didGenerateVTree:(NEEventTracingVTree *)VTree lastVTree:(NEEventTracingVTree * _Nullable)lastVTree hasChanges:(BOOL)hasChanges {
    [self _didGenerageVTree:VTree];
}

#pragma mark -
#pragma mark - Private methods
- (void)_didGenerageVTree:(NEEventTracingVTree *)VTree {
    UIView *rootView = self.bridge.context.webView;
    NEEventTracingVTreeNode *VTreeNode = [self _fetchContainerNodeFromRootView:rootView];
    if (!VTreeNode) {
        return;
    }
    
    self.containerVTreeCopy = VTreeNode.VTree.copy;
    self.containerVTreeNodeCopy = [self.containerVTreeCopy nodeForSpm:VTreeNode.spm];
}

- (NEEventTracingVTreeNode *)_doFetchNodeAndCheckBeforeReportForContext:(id<ETWebViewBridgeCallContextProtocol>)context
                                                    callback:(void (^)(NSDictionary * _Nullable, NSDictionary * _Nullable))callback {
    if (![NEEventTracingEngine sharedInstance].context.started) {
        callback(@{@"code": @(ETWebViewBridgeCodeNotFound)}, [NSError et_webkit_errorWithMessage:@"EventTracing not started." code:ETWebViewBridgeCodeNotFound]);
        return nil;
    }
    
    UIView *rootView = context.bridge.context.webView;
    NEEventTracingVTreeNode *foundedVTreeNode = [self _fetchContainerNodeFromRootView:rootView];
    NEEventTracingVTreeNode *VTreeNode = foundedVTreeNode ?: self.containerVTreeNodeCopy;
    if (!VTreeNode) {
        callback(@{@"code": @(ETWebViewBridgeCodeInvalidParams)}, [NSError et_webkit_errorParamsWithMessage:@"当前上下文向上找不到一个page节点"]);
        return nil;
    }
    
    return VTreeNode;
}

/// MARK: 双端规范
// 1. H5容器内的所有埋点，必须可以挂载到一个原生的native节点名下
// 2. 该原生的native节点，比如是一个page节点（在向上找的过程中，如果遇到元素节点，则直接忽略）
// 3. 否则，该埋点打不出来
- (NEEventTracingVTreeNode *)_fetchContainerNodeFromRootView:(UIView *)rootView {
    NEEventTracingVTreeNode *node = [NE_ET_FindAncestorNodeViewAt(rootView) ne_et_currentVTreeNode];
    if (!node) {
        return nil;
    }
    
    NEEventTracingVTreeNode *nextNode = node;
    while (nextNode != nil && !nextNode.isRoot && !nextNode.isPageNode) {
        nextNode = nextNode.parentNode;
    }
    
    return nextNode.isPageNode ? nextNode : nil;
}


@end
