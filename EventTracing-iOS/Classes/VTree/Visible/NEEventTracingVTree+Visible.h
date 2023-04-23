//
//  EventTracingVTree+Visible.h
//  EventTracing
//
//  Created by dl on 2021/3/18.
//

#import "EventTracingVTree+Private.h"

NS_ASSUME_NONNULL_BEGIN

@interface EventTracingVTree (Visible)

- (void)updateVisibleForNode:(EventTracingVTreeNode *)node;
- (void)applySubpageOcclusionIfNeeded;

@end

NS_ASSUME_NONNULL_END
