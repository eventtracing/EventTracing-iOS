//
//  EventTracingTraverser.h
//  BlocksKit
//
//  Created by dl on 2021/2/4.
//

#import <Foundation/Foundation.h>
#import "EventTracingVTree.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT BOOL ET_isPage(UIView *view);
FOUNDATION_EXPORT BOOL ET_isElement(UIView *view);
FOUNDATION_EXPORT BOOL ET_isPageOrElement(UIView *view);
FOUNDATION_EXPORT NSArray<UIView *> * ET_subViews(UIView *view);
FOUNDATION_EXPORT UIView * _Nullable ET_superView(UIView *view);
FOUNDATION_EXPORT BOOL ET_isIgnoreRefer(UIView *view);
FOUNDATION_EXPORT BOOL ET_isHasSubNodes(UIView *view);       // MARK: 使用原始 view 树来判断是否 子view 中有节点对象
FOUNDATION_EXPORT CGRect ET_viewVisibleRectOnSelf(UIView *view);
FOUNDATION_EXPORT CGRect ET_calculateVisibleRect(UIView *view, CGRect visibleRectOnView, CGRect containerVisibleRect);
FOUNDATION_EXPORT BOOL ET_checkIfExistsLogicalMountEndlessLoopAtView(UIView *view, UIView *viewToMount);
FOUNDATION_EXPORT NSString * _Nullable ET_undefinedXpathReferForView(UIView *view);
FOUNDATION_EXPORT BOOL ET_checkIfExistsAncestorViewControllerTransitioning(UIView *view);

@interface EventTracingTraverser : NSObject

- (void)cleanAssociationForPreVTree:(EventTracingVTree *)VTree;
- (void)associateNodeToViewForVTree:(EventTracingVTree *)VTree;

- (EventTracingVTree *)totalGenerateVTreeFromWindows;
- (EventTracingVTree *)incrementalGenerateVTreeFrom:(EventTracingVTree * _Nullable)VTree
                                                views:(NSArray<UIView *> * _Nullable)views;

@end

NS_ASSUME_NONNULL_END
