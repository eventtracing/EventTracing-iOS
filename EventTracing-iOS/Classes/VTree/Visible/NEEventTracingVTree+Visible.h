//
//  NEEventTracingVTree+Visible.h
//  NEEventTracing
//
//  Created by dl on 2021/3/18.
//

#import "NEEventTracingVTree+Private.h"

NS_ASSUME_NONNULL_BEGIN

@interface NEEventTracingVTree (Visible)

- (void)updateVisibleForNode:(NEEventTracingVTreeNode *)node;
- (void)applySubpageOcclusionIfNeeded;

@end

NS_ASSUME_NONNULL_END
