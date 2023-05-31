//
//  NEEventTracingVTreeNode+Visible.h
//  NEEventTracing
//
//  Created by dl on 2021/3/18.
//

#import "NEEventTracingVTreeNode+Private.h"

NS_ASSUME_NONNULL_BEGIN

@interface NEEventTracingVTreeNode (Visible)

// VisibleRect
- (void)updateVisible:(BOOL)visible visibleRect:(CGRect)visibleRect;
- (void)markBlockedByOcclusionPageNode:(NEEventTracingVTreeNode *)occlusionPageNode;

@end

NS_ASSUME_NONNULL_END
