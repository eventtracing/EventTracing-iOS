//
//  NEEventTracingVTree+Sync.h
//  BlocksKit
//
//  Created by dl on 2021/3/25.
//

#import "NEEventTracingVTree.h"

NS_ASSUME_NONNULL_BEGIN

@interface NEEventTracingVTree (Sync)

// 同步VTree的 pgstep & actseq 等重要参数
- (void)syncToVTree:(NEEventTracingVTree *)VTree;

// 更新节点以及父节点的params
- (void)syncNodeDynamicParamsForNode:(NEEventTracingVTreeNode *)node event:(NSString *)event;

// 这里用来回填数据，由于某些原因导致VTree切换后，上一个VTree又触发了 event ，需要递增 actseq
// 目前这里针对 UIAlertController
- (void)increaseActseqFromOtherTree:(NEEventTracingVTree *)otherTree node:(NEEventTracingVTreeNode *)node;

@end

NS_ASSUME_NONNULL_END
