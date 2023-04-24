//
//  NEEventTracingVTree+Visible.m
//  NEEventTracing
//
//  Created by dl on 2021/3/18.
//

#import "NEEventTracingVTree+Visible.h"
#import "NEEventTracingTraverser.h"
#import "NSArray+ETEnumerator.h"
#import "UIView+EventTracingPrivate.h"
#import "NEEventTracingVTreeNode+Visible.h"

#import <BlocksKit/BlocksKit.h>

@implementation NEEventTracingVTree (Visible)

#pragma mark - on main thread
- (void)updateVisibleForNode:(NEEventTracingVTreeNode *)node {
    /// MARK: prepare data
    UIView *view = node.view;
    CGRect visibleRectOnSelf = NE_ET_viewVisibleRectOnSelf(view);
    CGRect visibleRect = CGRectZero;
    
    // NEETNodeVisibleRectCalculateStrategyOnParentNode
    if (node.visibleRectCalculateStrategy == NEETNodeVisibleRectCalculateStrategyOnParentNode) {
        /// MARK: 计算自身的 VisibleRect
        visibleRect = NE_ET_calculateVisibleRect(view, visibleRectOnSelf, node.parentNode.visibleRect);
    }
    
    // NEETNodeVisibleRectCalculateStrategyRecursionOnViewTree
    else if (node.visibleRectCalculateStrategy == NEETNodeVisibleRectCalculateStrategyRecursionOnViewTree) {
        UIView *parentNodeView = node.parentNode.view;
        // 跟 superView 进行对比，逐步缩小visibleRect [递归]
        CGRect rect = visibleRectOnSelf;
        UIView *currentView = view;
        UIView *nextView = nil;

        do {
            nextView = NE_ET_superView(currentView);
            
            CGRect nextViewSelfVisibleRect = NE_ET_viewVisibleRectOnSelf(nextView);
            CGRect nextViewVisibleRect = [nextView convertRect:nextViewSelfVisibleRect toView:nil];
            rect = NE_ET_calculateVisibleRect(currentView, rect, nextViewVisibleRect);
            
            currentView = nextView;
        } while (!CGRectEqualToRect(rect, CGRectZero) && nextView != nil && nextView != parentNodeView);
        
        visibleRect = rect;
    }
    
    // NEETNodeVisibleRectCalculateStrategyPassthrough
    else {
        visibleRect = [view convertRect:visibleRectOnSelf toView:nil];;
    }
    
    /// MARK: => visible && visibleRect
    CGRect screenRect = [UIScreen mainScreen].bounds;
    BOOL(^isVisibleRectVisible)(CGRect) = ^BOOL(CGRect rect) {
        return !CGRectEqualToRect(visibleRect, CGRectZero)
                && rect.size.width > CGFLOAT_MIN
                && rect.size.height > CGFLOAT_MIN
                && CGRectIntersectsRect(screenRect, rect);
    };
    
    /// MARK: visible 判断
    BOOL visible = node.parentNode.visible && view.ne_et_logicalVisible && isVisibleRectVisible(visibleRect);
    [node updateVisible:visible visibleRect:visibleRect];
}

#pragma mark - sub thread
- (void)applySubpageOcclusionIfNeeded {
    [self.rootNode.subNodes ne_et_enumerateObjectsWithType:NEEventTracingEnumeratorTypeDFSRight usingBlock:^NSArray<NEEventTracingVTreeNode *> * _Nonnull(NEEventTracingVTreeNode * _Nonnull obj, BOOL * _Nonnull stop) {
        if (obj.isPageNode && obj.visible && obj.pageOcclusionEnable) {
            [self _doApplySubpageOcclusionForPageNode:obj];
        }
        return obj.subNodes;
    }];
}

/// MARK: page遮挡 => 子page会遮挡祖先page下的元素，并且该元素需要先于该page添加
- (void)_doApplySubpageOcclusionForPageNode:(NEEventTracingVTreeNode *)pageNode {
    if (!pageNode.parentNode) {
        return;
    }
    
    __block NEEventTracingVTreeNode *anchorNode = pageNode;
    [pageNode.parentNode enumerateAncestorNodeWithBlock:^(NEEventTracingVTreeNode * _Nonnull ancestorNode, BOOL * _Nonnull stop) {
        [self _doApplyPageOcclusionForPageNode:pageNode ancestorNode:ancestorNode anchorNode:anchorNode];
        
        if (ancestorNode.isPageNode) {
            *stop = YES;
        }
        
        anchorNode = ancestorNode;
    }];
}

- (void)_doApplyPageOcclusionForPageNode:(NEEventTracingVTreeNode *)pageNode
                            ancestorNode:(NEEventTracingVTreeNode *)ancestorNode
                              anchorNode:(NEEventTracingVTreeNode *)anchorNode {
    NSMutableArray<NEEventTracingVTreeNode *> *nodes = [@[] mutableCopy];
    [ancestorNode.subNodes enumerateObjectsUsingBlock:^(NEEventTracingVTreeNode * _Nonnull node, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([node ne_et_isEqualToDiffableObject:anchorNode]) {
            *stop = YES;
        } else if(node.visible) {
            [nodes addObject:node];
        }
    }];
    
    [self _doApplyAreaOcclusionForNodes:nodes occlusionPageNode:pageNode];
}

- (void)_doApplyAreaOcclusionForNodes:(NSArray<NEEventTracingVTreeNode *> *)nodes occlusionPageNode:(NEEventTracingVTreeNode *)occlusionPageNode {
    CGRect occlusionRect = occlusionPageNode.visibleRect;
    [nodes ne_et_enumerateObjectsUsingBlock:^NSArray<NEEventTracingVTreeNode *> * _Nonnull(NEEventTracingVTreeNode * _Nonnull node, BOOL * _Nonnull stop) {
        // 如果是一个虚拟节点，则直接跳过，不做遮挡处理
        // 如果一个节点被遮挡了，并且该子节点的父节点是虚拟节点，则需要判断该虚拟节点的子节点是否全部被遮挡了，如果全部被遮挡了，则该虚拟几点也设置为被遮挡
        if (node.isVirtualNode) {
            return node.subNodes;
        }
        
        BOOL visible = !CGRectContainsRect(occlusionRect, node.visibleRect);
        
        // 2. 节点不可见，则无需再遍历子节点
        if (!visible) {
            [node markBlockedByOcclusionPageNode:occlusionPageNode];
        }
        // 3. 节点可见，并且相交
        else if (visible && CGRectIntersectsRect(occlusionRect, node.visibleRect)) {
            return node.subNodes;
        }
        
        // 4. 节点可见，而且没有相交，则无需再遍历子节点
        return nil;
    }];
}

@end
