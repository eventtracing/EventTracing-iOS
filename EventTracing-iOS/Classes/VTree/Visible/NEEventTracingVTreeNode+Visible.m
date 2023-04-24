//
//  NEEventTracingVTreeNode+Visible.m
//  NEEventTracing
//
//  Created by dl on 2021/3/18.
//

#import "NEEventTracingVTreeNode+Visible.h"
#import "NSArray+ETEnumerator.h"
#import <BlocksKit/BlocksKit.h>

@implementation NEEventTracingVTreeNode (Visible)

- (void)updateVisible:(BOOL)visible visibleRect:(CGRect)visibleRect {
    self.visible = visible;
    self.visibleRect = visibleRect;
    
    CGFloat viewSelfArea = self.viewVisibleRectOnScreen.size.width * self.viewVisibleRectOnScreen.size.height;
    if (viewSelfArea <= 0) {
        return;
    }
    CGFloat viewVisibleArea = visibleRect.size.width * visibleRect.size.height;
    self.impressMaxRatio = MAX(0.f, MIN(1.f, roundf(viewVisibleArea / viewSelfArea * 100) / 100.f)); // 保留两位小数
}

- (void)markBlockedByOcclusionPageNode:(NEEventTracingVTreeNode *)occlusionPageNode {
    if (self.isVirtualNode) {
        self.blockedBySubPage = YES;
        return;
    }
    
    [@[self] ne_et_enumerateObjectsUsingBlock:^NSArray<NEEventTracingVTreeNode *> * _Nonnull(NEEventTracingVTreeNode * _Nonnull obj, BOOL * _Nonnull stop) {
        obj.blockedBySubPage = YES;
        return obj.subNodes;
    }];
    
    if (self.parentNode.isVirtualNode) {
        BOOL parentVirtualNodeHasVisiableSubNodes = [self.parentNode.subNodes bk_any:^BOOL(NEEventTracingVTreeNode *obj) {
            return !obj.blockedBySubPage && obj.isVisible;
        }];
        if (!parentVirtualNodeHasVisiableSubNodes) {
            self.parentNode.blockedBySubPage = YES;
        }
        
        return;
    }
    
    /// MARK: 如果一个节点明确声明只有存在指定子节点的时候才合法，而且所有子节点都被遮挡了，该节点也应该算被遮挡
    if (self.parentNode.validForContainingSubNodeOids.count == 0) {
        return;
    }
    
    /// MARK: 遮挡，只能遮挡`左侧兄弟节点`，或者左右兄弟节点的子节点，不可以向上遮挡
    __block BOOL shouldBeBlocked = YES;
    [occlusionPageNode enumerateAncestorNodeWithBlock:^(NEEventTracingVTreeNode * _Nonnull ancestorNode, BOOL * _Nonnull stop) {
        if (ancestorNode == self.parentNode) {
            shouldBeBlocked = NO;
            *stop = YES;
        }
    }];
    
    if (shouldBeBlocked) {
        [[self.parentNode.subNodes bk_reject:^BOOL(NEEventTracingVTreeNode *obj) {
            return !obj.visible;
        }] enumerateObjectsUsingBlock:^(NEEventTracingVTreeNode * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([self.parentNode.validForContainingSubNodeOids containsObject:obj.oid]) {
                shouldBeBlocked = NO;
            }
        }];
    }
    
    if (shouldBeBlocked) {
        [self.parentNode markBlockedByOcclusionPageNode:occlusionPageNode];
    }
}

@end
