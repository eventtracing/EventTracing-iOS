//
//  EventTracingOutputFlattenFormatter.m
//  BlocksKit
//
//  Created by dl on 2021/2/4.
//

#import "EventTracingOutputFlattenFormatter.h"
#import "NSArray+ETEnumerator.h"
#import <BlocksKit/BlocksKit.h>
#import "EventTracingDefines.h"
#import "EventTracingVTreeNode+Private.h"

@implementation EventTracingOutputFlattenFormatter

- (NSDictionary *)formatWithEvent:(NSString *)event
                  logActionParams:(NSDictionary * _Nullable)logActionParams
                             node:(nonnull EventTracingVTreeNode *)node
                          inVTree:(nonnull EventTracingVTree *)VTree {
    if (!node || node.isRoot) {
        return @{};
    }
    
    NSMutableArray<EventTracingVTreeNode *> *parentPageNodes = [@[] mutableCopy];
    NSMutableArray<EventTracingVTreeNode *> *parentElementNodes = [@[] mutableCopy];

    [node enumerateAncestorNodeWithBlock:^(EventTracingVTreeNode * _Nonnull ancestorNode, BOOL * _Nonnull stop) {
        if (parentPageNodes.count == 0 && !ancestorNode.isPageNode) {
            [parentElementNodes addObject:ancestorNode];
        } else if(ancestorNode.isPageNode) {
            [parentPageNodes addObject:ancestorNode];
        }
    }];
    
    id(^mapBlock)(EventTracingVTreeNode *) = ^id(EventTracingVTreeNode *obj) {
        return [self _nodeParamsForEvent:event node:obj];
    };
    
    NSArray<NSDictionary *> *_elist = [parentElementNodes bk_map:mapBlock];
    NSArray<NSDictionary *> *_plist = [parentPageNodes bk_map:mapBlock];
    
    NSMutableDictionary *json = [@{} mutableCopy];
    if (logActionParams.count) {
        [json addEntriesFromDictionary:logActionParams];
    }
    
    [json setObject:_elist forKey:ET_CONST_KEY_ELIST];
    [json setObject:_plist forKey:ET_CONST_KEY_PLIST];

    [json setObject:node.spm forKey:ET_REFER_KEY_SPM];
    [json setObject:node.scm forKey:ET_REFER_KEY_SCM];
    if (node.isSCMNeedsER) {
        [json setObject:@"1" forKey:ET_REFER_KEY_SCM_ER];
    }
    [json setObject:event forKey:ET_CONST_KEY_EVENT_CODE];
    
    return json;
}

- (NSDictionary *)_nodeParamsForEvent:(NSString *)event node:(EventTracingVTreeNode *)node {
    NSMutableDictionary *params = [@{} mutableCopy];
    NSDictionary *nodeParams = [node nodeParamsForEvent:event];
    if (nodeParams.count) {
        [params addEntriesFromDictionary:nodeParams];
    }
    
    [params setObject:node.oid forKey:ET_CONST_KEY_OID];
    [params setObject:@(node.impressMaxRatio) forKey:ET_REFER_KEY_RATIO];
    if (!node.visible) {
        [params setObject:@"1" forKey:ET_CONST_KEY_INVISIBLE];
    }
    
    /// MARK: debug能力，临时使用，为了排查一些元素没有曝光的问题
    NSString *debugVisibleRectString = [NSString stringWithFormat:@"{%.1f,%.1f,%.1f,%.1f}", node.visibleRect.origin.x, node.visibleRect.origin.y, node.visibleRect.size.width, node.visibleRect.size.height];
    [params setObject:debugVisibleRectString forKey:@"_debug_visible_rect"];

    if (node.isPageNode) {
        [params setObject:@(node.pgstep) forKey:ET_REFER_KEY_PGSTEP];
        
        if (node.pgrefer) {
            [params setObject:node.pgrefer forKey:ET_REFER_KEY_PGREFER];
        }
        
        if (node.psrefer) {
            [params setObject:node.psrefer forKey:ET_REFER_KEY_PSREFER];
        }
    }
    
    return params;
}

@end
