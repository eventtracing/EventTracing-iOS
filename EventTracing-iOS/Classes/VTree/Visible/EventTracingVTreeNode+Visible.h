//
//  EventTracingVTreeNode+Visible.h
//  EventTracing
//
//  Created by dl on 2021/3/18.
//

#import "EventTracingVTreeNode+Private.h"

NS_ASSUME_NONNULL_BEGIN

@interface EventTracingVTreeNode (Visible)

// VisibleRect
- (void)updateVisible:(BOOL)visible visibleRect:(CGRect)visibleRect;
- (void)markBlockedByOcclusionPageNode:(EventTracingVTreeNode *)occlusionPageNode;

@end

NS_ASSUME_NONNULL_END
