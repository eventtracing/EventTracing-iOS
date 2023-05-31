//
//  NEEventTracingOutputFlattenFormatter.m
//  BlocksKit
//
//  Created by dl on 2021/2/4.
//

#import "NEEventTracingOutputFlattenFormatter.h"
#import "NSArray+ETEnumerator.h"
#import <BlocksKit/BlocksKit.h>
#import "NEEventTracingDefines.h"
#import "NEEventTracingVTreeNode+Private.h"

@implementation NEEventTracingOutputFlattenFormatter

- (NSDictionary *)formatWithEvent:(NSString *)event
                  logActionParams:(NSDictionary * _Nullable)logActionParams
                             node:(nonnull NEEventTracingVTreeNode *)node
                          inVTree:(nonnull NEEventTracingVTree *)VTree {
    if (!node || node.isRoot) {
        return @{};
    }
    
    NSMutableArray<NEEventTracingVTreeNode *> *parentPageNodes = [@[] mutableCopy];
    NSMutableArray<NEEventTracingVTreeNode *> *parentElementNodes = [@[] mutableCopy];

    [node enumerateAncestorNodeWithBlock:^(NEEventTracingVTreeNode * _Nonnull ancestorNode, BOOL * _Nonnull stop) {
        if (parentPageNodes.count == 0 && !ancestorNode.isPageNode) {
            [parentElementNodes addObject:ancestorNode];
        } else if(ancestorNode.isPageNode) {
            [parentPageNodes addObject:ancestorNode];
        }
    }];
    
    id(^mapBlock)(NEEventTracingVTreeNode *) = ^id(NEEventTracingVTreeNode *obj) {
        return [self _nodeParamsForEvent:event node:obj];
    };
    
    NSArray<NSDictionary *> *_elist = [parentElementNodes bk_map:mapBlock];
    NSArray<NSDictionary *> *_plist = [parentPageNodes bk_map:mapBlock];
    
    NSMutableDictionary *json = [@{} mutableCopy];
    if (logActionParams.count) {
        [json addEntriesFromDictionary:logActionParams];
    }
    
    [json setObject:_elist forKey:NE_ET_CONST_KEY_ELIST];
    [json setObject:_plist forKey:NE_ET_CONST_KEY_PLIST];

    [json setObject:node.spm forKey:NE_ET_REFER_KEY_SPM];
    [json setObject:node.scm forKey:NE_ET_REFER_KEY_SCM];
    if (node.isSCMNeedsER) {
        [json setObject:@"1" forKey:NE_ET_REFER_KEY_SCM_ER];
    }
    [json setObject:event forKey:NE_ET_CONST_KEY_EVENT_CODE];
    
    return json;
}

- (NSDictionary *)_nodeParamsForEvent:(NSString *)event node:(NEEventTracingVTreeNode *)node {
    NSMutableDictionary *params = [@{} mutableCopy];
    NSDictionary *nodeParams = [node nodeParamsForEvent:event];
    if (nodeParams.count) {
        [params addEntriesFromDictionary:nodeParams];
    }
    
    [params setObject:node.oid forKey:NE_ET_CONST_KEY_OID];
    [params setObject:@(node.impressMaxRatio) forKey:NE_ET_REFER_KEY_RATIO];
    if (!node.visible) {
        [params setObject:@"1" forKey:NE_ET_CONST_KEY_INVISIBLE];
    }
    
    /// MARK: debug能力，临时使用，为了排查一些元素没有曝光的问题
    NSString *debugVisibleRectString = [NSString stringWithFormat:@"{%.1f,%.1f,%.1f,%.1f}", node.visibleRect.origin.x, node.visibleRect.origin.y, node.visibleRect.size.width, node.visibleRect.size.height];
    [params setObject:debugVisibleRectString forKey:@"_debug_visible_rect"];

    if (node.isPageNode) {
        [params setObject:@(node.pgstep) forKey:NE_ET_REFER_KEY_PGSTEP];
        
        if (node.pgrefer) {
            [params setObject:node.pgrefer forKey:NE_ET_REFER_KEY_PGREFER];
        }
        
        if (node.psrefer) {
            [params setObject:node.psrefer forKey:NE_ET_REFER_KEY_PSREFER];
        }
    }
    
    return params;
}

@end
