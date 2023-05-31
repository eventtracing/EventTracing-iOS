//
//  NEEventTracingTraverser.h
//  BlocksKit
//
//  Created by dl on 2021/2/4.
//

#import <Foundation/Foundation.h>
#import "NEEventTracingVTree.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT BOOL NE_ET_isPage(UIView *view);
FOUNDATION_EXPORT BOOL NE_ET_isElement(UIView *view);
FOUNDATION_EXPORT BOOL NE_ET_isPageOrElement(UIView *view);
FOUNDATION_EXPORT NSArray<UIView *> * NE_ET_subViews(UIView *view);
FOUNDATION_EXPORT UIView * _Nullable NE_ET_superView(UIView *view);
FOUNDATION_EXPORT BOOL NE_ET_isIgnoreRefer(UIView *view);
FOUNDATION_EXPORT BOOL NE_ET_isHasSubNodes(UIView *view);       // MARK: 使用原始 view 树来判断是否 子view 中有节点对象
FOUNDATION_EXPORT CGRect NE_ET_viewVisibleRectOnSelf(UIView *view);
FOUNDATION_EXPORT CGRect NE_ET_calculateVisibleRect(UIView *view, CGRect visibleRectOnView, CGRect containerVisibleRect);
FOUNDATION_EXPORT BOOL NE_ET_checkIfExistsLogicalMountEndlessLoopAtView(UIView *view, UIView *viewToMount);
FOUNDATION_EXPORT NSString * _Nullable NE_ET_undefinedXpathReferForView(UIView *view);
FOUNDATION_EXPORT BOOL NE_ET_checkIfExistsAncestorViewControllerTransitioning(UIView *view);

@interface NEEventTracingTraverser : NSObject

- (void)cleanAssociationForPreVTree:(NEEventTracingVTree *)VTree;
- (void)associateNodeToViewForVTree:(NEEventTracingVTree *)VTree;

- (NEEventTracingVTree *)totalGenerateVTreeFromWindows;
- (NEEventTracingVTree *)incrementalGenerateVTreeFrom:(NEEventTracingVTree * _Nullable)VTree
                                                views:(NSArray<UIView *> * _Nullable)views;

@end

NS_ASSUME_NONNULL_END
