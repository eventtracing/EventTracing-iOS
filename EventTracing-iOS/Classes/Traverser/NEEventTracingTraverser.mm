//
//  NEEventTracingTraverser.m
//  BlocksKit
//
//  Created by dl on 2021/2/4.
//

#import "NEEventTracingTraverser.h"
#import <stack>
#import <BlocksKit/BlocksKit.h>

#import "NEEventTracingInternalLog.h"
#import "NSArray+ETEnumerator.h"

#import "NEEventTracingVTree+Private.h"
#import "NEEventTracingVTree+Visible.h"
#import "NEEventTracingVTree+Sync.h"
#import "NEEventTracingVTreeNode+Private.h"

#import "UIView+EventTracingPrivate.h"
#import "NEEventTracingEngine+Private.h"

BOOL NE_ET_isPage(UIView *view) {
    return view && view.ne_et_pageId.length > 0;
}

BOOL NE_ET_isElement(UIView *view) {
    return view && view.ne_et_elementId.length > 0;
}

BOOL NE_ET_isPageOrElement(UIView *view) {
    NEEventTracingAssociatedPros *props = view.ne_et_props;
    return view && (props.pageId.length > 0 || props.elementId.length > 0);
}

NSArray<UIView *> * NE_ET_subViews(UIView *view) {
    NSMutableArray<UIView *> *views = [NSMutableArray array];
    [[view.subviews copy] enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        BOOL hasLogicalParentView = obj.ne_et_logicalParentView != nil;
        BOOL hasLogicalParentSPM = obj.ne_et_logicalParentSPM != nil;
        BOOL autoMountOnRootPage = obj.ne_et_isAutoMountOnCurrentRootPageEnable;
        
        if (hasLogicalParentView || hasLogicalParentSPM || autoMountOnRootPage) {
            return;
        }
        
        [views addObject:obj];
    }];
    
    if (view.ne_et_subLogicalViews.count) {
        [views addObjectsFromArray:[view.ne_et_subLogicalViews.allObjects bk_map:^id(NEEventTracingWeakObjectContainer<UIView *> *obj) {
            return obj.target;
        }]];
    }
    return views.copy;
}

UIView * _Nullable NE_ET_superView(UIView *view) {
    if (view.ne_et_logicalParentView) {
        return view.ne_et_logicalParentView;
    }
    if (view.ne_et_logicalParentSPM != nil && NE_ET_isPage(view)) {
        return view.ne_et_currentVTreeNode.parentNode.view;
    }
    if (view.ne_et_isAutoMountOnCurrentRootPageEnable && NE_ET_isPageOrElement(view)) {
        return view.ne_et_currentVTreeNode.parentNode.view;
    }
    return view.superview;
}

/// MARK: 节点校验-辅助功能
/// 从当前view向上找，直到找个一个节点为止，如果中间发现手动挂载(中间不出现自动挂载)，则 return YES
BOOL NE_ET_viewIsLogicalMount(UIView *view) {
    // 1. 如果当前节点有手动挂载，则直接可判定 => YES
    if (view.ne_et_logicalParentView != nil) {
        return YES;
    }
    // 2. 如果该节点是自动挂载的节点，则可直接判断 => NO
    if (view.ne_et_isAutoMountOnCurrentRootPageEnable) {
        return NO;
    }
    
    // 3. 需要向上遍历(到第一个节点为止)
    //   3.1 如果遇到了自动挂载view，则终止，可判断为 NO
    //   3.2 如果遇到了手动挂载view，则终止，可判断为 YES
    UIView *nextView = NE_ET_superView(view);
    BOOL logicalMount = NO;
    while (nextView != nil && !NE_ET_isPageOrElement(nextView) && nextView.ne_et_isAutoMountOnCurrentRootPageEnable) {
        if (nextView.ne_et_logicalParentView != nil) {
            logicalMount = YES;
            break;
        }
        nextView = NE_ET_superView(nextView);
    }
    return logicalMount;
}

/// MARK: 节点校验-辅助功能
BOOL NE_ET_viewIsAutoMount(UIView *view) {
    // 1. 如果该节点是自动挂载的节点，则可直接判断 => YES
    if (view.ne_et_isAutoMountOnCurrentRootPageEnable) {
        return YES;
    }
    
    // 2. 如果当前节点有手动挂载，则直接可判定 => NO
    if (view.ne_et_logicalParentView != nil) {
        return NO;
    }
    
    // 3. 需要向上遍历(到第一个节点为止)
    //   3.1 如果遇到了自动挂载view，则终止，可判断为 NO
    //   3.2 如果遇到了手动挂载view，则终止，可判断为 YES
    UIView *nextView = NE_ET_superView(view);
    BOOL autoMount = NO;
    while (nextView != nil && !NE_ET_isPageOrElement(nextView) && nextView.ne_et_logicalParentView == nil) {
        if (nextView.ne_et_isAutoMountOnCurrentRootPageEnable) {
            autoMount = YES;
            break;
        }
        nextView = NE_ET_superView(nextView);
    }
    return autoMount;
}

BOOL NE_ET_isIgnoreRefer(UIView *view) {
    UIView *nextView = view;
    while (nextView && !nextView.ne_et_ignoreReferCascade) {
        nextView = NE_ET_superView(nextView);
    }
    
    return nextView && nextView.ne_et_ignoreReferCascade;
}

BOOL NE_ET_isHasSubNodes(UIView *view) {
    __block BOOL hasSubNodes = NO;
    
    [view.subviews ne_et_enumerateObjectsUsingBlock:^NSArray<__kindof UIView *> * _Nonnull(__kindof UIView * _Nonnull nextView, BOOL * _Nonnull stop) {
        hasSubNodes = NE_ET_isPageOrElement(nextView);
        
        if (hasSubNodes) {
            *stop = YES;
        }

        return nextView.subviews;
    }];
    
    return hasSubNodes;
}

CGRect NE_ET_viewVisibleRectOnSelf(UIView *view) {
    if (!view) {
        return CGRectZero;
    }
    
    return UIEdgeInsetsInsetRect(view.bounds, view.ne_et_visibleEdgeInsets);
}

CGRect NE_ET_calculateVisibleRect(UIView *view, CGRect visibleRectOnView, CGRect containerVisibleRect) {
    CGRect visibleRectOnScreen = [view convertRect:visibleRectOnView toView:nil];
    
    CGRect fixedContainerVisibleRect = containerVisibleRect;
    if (CGRectEqualToRect(containerVisibleRect, CGRectZero)) {
        fixedContainerVisibleRect = UIScreen.mainScreen.bounds;
    }
    
    CGRect visibleRect = CGRectZero;
    if (CGRectIntersectsRect(visibleRectOnScreen, fixedContainerVisibleRect)) {
        visibleRect = CGRectIntersection(visibleRectOnScreen, fixedContainerVisibleRect);
    }
    return visibleRect;
}

BOOL NE_ET_checkIfExistsLogicalMountEndlessLoopAtView(UIView *view, UIView *viewToMount) {
    if (!view || !viewToMount) {
        return NO;
    }
    
    void(^exceptionBlock)(void) = ^(void) {
        id<NEEventTracingExceptionDelegate> exceptionDelegate = [NEEventTracingEngine sharedInstance].context.exceptionInterface;
        NSString *errmsg = [NSString stringWithFormat:@"View logical mount endlessloop: view: %@, viewToMount: %@", view, viewToMount];
        if ([exceptionDelegate respondsToSelector:@selector(logicalMountEndlessLoopExceptionKey:code:message:view:viewToMount:)]) {
            [exceptionDelegate logicalMountEndlessLoopExceptionKey:@"LogicalMountEndlessLoop"
                                                              code:NEEventTracingExceptionCodeLogicalMountEndlessLoop
                                                           message:errmsg
                                                              view:view
                                                       viewToMount:viewToMount];
        }
        ETLogE(@"EndlessLoop", errmsg);
    };
    
    if (view == viewToMount) {
        exceptionBlock();
        return YES;
    }
    
    __block BOOL hasEndlessLoop = NO;
    [@[viewToMount] ne_et_enumerateObjectsUsingBlock:^NSArray<UIView *> * _Nonnull(UIView * _Nonnull obj, BOOL * _Nonnull stop) {
        if (obj == view) {
            hasEndlessLoop = YES;
            *stop = YES;
        }
        
        UIView *nextView = NE_ET_superView(obj);
        return nextView ? @[nextView] : nil;
    }];
    
    if (hasEndlessLoop) {
        exceptionBlock();
        return YES;
    }
    
    return NO;
}

NSString * _Nullable NE_ET_undefinedXpathReferForView(UIView *view) {
    if (!view) {
        return nil;
    }
    
    NSMutableString *spm = [@"" mutableCopy];
    UIResponder *next = view;
    BOOL viewControllerFounded = NO;
    while (next != nil) {
        viewControllerFounded = viewControllerFounded || [next isKindOfClass:UIViewController.class];
        
        void(^appendSPM)(UIResponder *) = ^(UIResponder *obj) {
            if (spm.length) {
                [spm appendString:@"."];
            }
            [spm appendString:NSStringFromClass(obj.class)];
        };
        
        if (!viewControllerFounded) {
            appendSPM(next);
        } else if ([next isKindOfClass:UIViewController.class] && ![next isKindOfClass:UINavigationController.class]) {
            appendSPM(next);
        }
        
        next = next.nextResponder;
    }
    
    return spm;
}

BOOL NE_ET_checkIfExistsAncestorViewControllerTransitioning(UIView *view) {
    UIViewController *viewController = nil;
    UIResponder *next = view;
    
    while (next != nil) {
        if ([next isKindOfClass:UIViewController.class]
            && ![next isMemberOfClass:UIViewController.class]
            && ![next isKindOfClass:UINavigationController.class]) {
            viewController = (UIViewController *)next;
        }
        
        if (viewController.ne_et_isTransitioning) {
            break;
        }
        
        next = next.nextResponder;
    }
    
    return viewController.ne_et_transitioning;
}

@implementation NEEventTracingTraverser

- (void)cleanAssociationForPreVTree:(NEEventTracingVTree *)VTree {
    [VTree.rootNode.subNodes ne_et_enumerateObjectsUsingBlock:^NSArray<NEEventTracingVTreeNode *> * _Nonnull(NEEventTracingVTreeNode * _Nonnull node, BOOL * _Nonnull stop) {
        node.view.ne_et_currentVTreeNode = nil;
        
        return node.subNodes;
    }];
}

- (void)associateNodeToViewForVTree:(NEEventTracingVTree *)VTree {
    [VTree.rootNode.subNodes ne_et_enumerateObjectsUsingBlock:^NSArray<NEEventTracingVTreeNode *> * _Nonnull(NEEventTracingVTreeNode * _Nonnull node, BOOL * _Nonnull stop) {
        node.view.ne_et_currentVTreeNode = node;
        
        return node.subNodes;
    }];
}

// View 上的一些额外配置，可以随着view树的递归一起参与遍历，可减少后续再单独遍历
struct ETTraverseObjectViewConfigData {
    BOOL ignoreRefer;
    
    /// MARK: 节点校验-辅助功能
    // 如果当前view是被手动挂载的，则该标识被携带，向下遍历影响第一层节点
    // 如果当前view是被自动挂载的，则该标识被携带，向下遍历影响第一层节点
    NEEventTracingNodeValidMountType mountType;
};

struct ETTraverseObject {
    NEEventTracingVTreeNode *parentNode;
    UIView *view;
    ETTraverseObjectViewConfigData configData;
    
    ETTraverseObject(NEEventTracingVTreeNode *p, UIView *v, ETTraverseObjectViewConfigData data) :
    parentNode(p), view(v), configData(data) {};
};

- (NEEventTracingVTree *)totalGenerateVTreeFromWindows {
    NSMutableArray<UIWindow *> *windows = [UIApplication sharedApplication].windows.mutableCopy;
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    if (keyWindow && ![windows containsObject:keyWindow]) {
        [windows addObject:keyWindow];
    }
    
    NEEventTracingVTree *VTree = [[NEEventTracingVTree alloc] init];
    
    NSMutableArray<NEEventTracingVTreeNode *> *needsMakeSureValidNodes = [@[] mutableCopy];

    [self _pushItemsToVTree:VTree
                 parentNode:nil
                      views:windows
    needsMakeSureValidNodes:needsMakeSureValidNodes
      needsCheckEndlessloop:NO];
    
    [needsMakeSureValidNodes enumerateObjectsUsingBlock:^(NEEventTracingVTreeNode * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.subNodes.count == 0) {
            [obj.parentNode removeSubNode:obj];
        }
    }];
    
    // 自动挂载到rootPage的逻辑
    NEEventTracingVTreeNode *rootPageNode = [VTree findToppestRightPageNode];
    if (rootPageNode && !NE_ET_checkIfExistsAncestorViewControllerTransitioning(rootPageNode.view)) {
        [self _pushItemsToVTree:VTree
                     parentNode:rootPageNode
                          views:NEEventTracingAutoMountRootPageViews()
        needsMakeSureValidNodes:nil
         needsCheckEndlessloop:YES];
    }
    
    // spm 形式的挂载
    [self _mountLogicalParentSPMViewsToVTree:VTree];
    
    return VTree;
}

- (NEEventTracingVTree *)incrementalGenerateVTreeFrom:(NEEventTracingVTree *)VTree views:(NSArray<UIView *> *)views {
    if (!VTree) {
        return [self totalGenerateVTreeFromWindows];
    }

    // 首先，view内部得有节点
    NSArray<UIView *> *hasSubNodeViews = [views bk_reject:^BOOL(UIView *obj) {
        return !obj.ne_et_hasSubNodes;
    }];
    
    // 如果当前view不是一个节点，则可以尝试向上追溯, 找到向上最近的一个节点
    NSMutableSet<UIView *> *nodableViews = [NSMutableSet set];
    [hasSubNodeViews enumerateObjectsUsingBlock:^(UIView * _Nonnull view, NSUInteger idx, BOOL * _Nonnull stop) {
        if (NE_ET_isPageOrElement(view)) {
            [nodableViews addObject:view];
        } else if(NE_ET_superView(view)) {
            [@[NE_ET_superView(view)] ne_et_enumerateObjectsUsingBlock:^NSArray<UIView *> * _Nonnull(UIView * _Nonnull obj, BOOL * _Nonnull stop) {
                if (NE_ET_isPageOrElement(obj)) {
                    [nodableViews addObject:obj];
                    *stop = YES;
                }
                return NE_ET_superView(obj) ? @[NE_ET_superView(obj)] : nil;
            }];
        }
    }];
    
    // 剔除有上下级重叠的ScrollView，防止重复构建
    NSMutableSet<UIView *> *validViews = nodableViews.mutableCopy;
    [nodableViews enumerateObjectsUsingBlock:^(UIView * _Nonnull view, BOOL * _Nonnull stop) {
        UIView *next = view;
        while (next) {
            next = NE_ET_superView(next);
            
            if ([nodableViews containsObject:(UIView *)next]) {
                [validViews removeObject:view];
                next = nil;
            }
        }
    }];
    
    __block NEEventTracingVTree *VTreeCopy = nil;
    __block NEEventTracingVTreeNode *rootPageNode = nil;
    __block BOOL needAutoMoundNodes = NO;
    
    __block BOOL VTreeChanged = NO;
    [validViews enumerateObjectsUsingBlock:^(UIView * _Nonnull view, BOOL * _Nonnull stop) {
        NEEventTracingVTreeNode *viewNode = view.ne_et_currentVTreeNode;
        
        // 当前view没有对应的节点 或者 节点没有有子节点(如果没有子节点，是不需要重新构建的)
        if (viewNode == nil || viewNode.subNodes.count == 0) {
            return;
        }
        
        // 按需来决定是否需要真正的 copy VTree && 增量构建VTree
        if (VTreeCopy == nil) {
            VTreeCopy = VTree.copy;
            /// MARK: 从lastVTree拷贝而来，并且标识 unstable, 以供后续再次被 consume
            [VTreeCopy VTreeMarkUnStable];
            [VTreeCopy regenerateVTreeIdentifier];
            rootPageNode = [VTreeCopy findToppestRightPageNode];
        }
        
        // 在 VTree 中找到该节点
        __block NEEventTracingVTreeNode *parentNode = nil;
        [VTreeCopy.rootNode.subNodes ne_et_enumerateObjectsUsingBlock:^NSArray<NEEventTracingVTreeNode *> * _Nonnull(NEEventTracingVTreeNode * _Nonnull obj, BOOL * _Nonnull stop) {
            if ([obj ne_et_isEqualToDiffableObject:viewNode]) {
                parentNode = obj;
                *stop = YES;
            }
            return obj.subNodes;
        }];
        
        [parentNode.subNodes enumerateObjectsUsingBlock:^(NEEventTracingVTreeNode * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [parentNode removeSubNode:obj];
        }];
        
        VTreeChanged = YES;
        
        // 如果当前需要构建的节点是 rootPage, 则需要重新做自动挂载
        needAutoMoundNodes = needAutoMoundNodes || [parentNode ne_et_isEqualToDiffableObject:rootPageNode];
        
        [self _pushItemsToVTree:VTreeCopy
                     parentNode:parentNode
                          views:NE_ET_subViews(view)
        needsMakeSureValidNodes:nil
          needsCheckEndlessloop:NO];
    }];
    
    if (!VTreeChanged) {
        return VTree;
    }
    
    // 需要重新处理: 自动挂载到rootPage的逻辑
    if (needAutoMoundNodes && !NE_ET_checkIfExistsAncestorViewControllerTransitioning(rootPageNode.view)) {
        [self _pushItemsToVTree:VTreeCopy
                     parentNode:rootPageNode
                          views:NEEventTracingAutoMountRootPageViews()
        needsMakeSureValidNodes:nil
         needsCheckEndlessloop:YES];
    }
    
    // spm 形式的逻辑挂载
    [self _mountLogicalParentSPMViewsToVTree:VTree];
    
    return VTreeCopy;
}

#pragma mark - private methods
- (void)_mountLogicalParentSPMViewsToVTree:(NEEventTracingVTree *)VTree {
    [NEEventTracingLogicalParentSPMViews() enumerateObjectsUsingBlock:^(UIView * _Nonnull view, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *spm = view.ne_et_logicalParentSPM;
        NEEventTracingVTreeNode *parentNode = [VTree nodeForSpm:spm];
        if (!parentNode) {
            return;
        }
        
        [self _pushItemsToVTree:VTree
                     parentNode:parentNode
                          views:@[view]
        needsMakeSureValidNodes:nil
          needsCheckEndlessloop:YES];
    }];
}

- (void)_pushItemsToVTree:(NEEventTracingVTree *)VTree
               parentNode:(NEEventTracingVTreeNode * _Nullable)parentNode
                    views:(NSArray<UIView *> *)views
  needsMakeSureValidNodes:(NSMutableArray<NEEventTracingVTreeNode *> *)needsMakeSureValidNodes
    needsCheckEndlessloop:(BOOL)needsCheckEndlessloop {
    
    BOOL nodeInfoValidationEnable = [NEEventTracingEngine sharedInstance].context.nodeInfoValidationEnable;
    
    __block std::stack<ETTraverseObject> stack;
    [views enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(UIView * _Nonnull v, NSUInteger idx, BOOL * _Nonnull stop) {
        NEEventTracingNodeValidMountType mountType = NEEventTracingNodeValidMountTypeNone;
        /// MARK: 节点校验-辅助功能
        if (nodeInfoValidationEnable) {
            if (NE_ET_viewIsLogicalMount(v)) {
                mountType = NEEventTracingNodeValidMountTypeManual;
            } else if (NE_ET_viewIsAutoMount(v)) {
                mountType = NEEventTracingNodeValidMountTypeAuto;
            }
        }
        stack.push(ETTraverseObject(parentNode, v, {NE_ET_isIgnoreRefer(v), mountType}));
    }];
    
    while (!stack.empty()) {
        ETTraverseObject object = stack.top();
        
        BOOL continueTraverseSubViews = YES;
        NEEventTracingVTreeNode *node = [self _nodeForObject:object
                                                   inVTree:VTree
                                  continueTraverseSubViews:&continueTraverseSubViews
                                     needsCheckEndlessloop:needsCheckEndlessloop];

        if (needsMakeSureValidNodes && node.validForContainingSubNodeOids.count) {
            [needsMakeSureValidNodes addObject:node];
        }
        
        stack.pop();
        
        if (continueTraverseSubViews) {
            [NE_ET_subViews(object.view) enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(UIView * _Nonnull v, NSUInteger idx, BOOL * _Nonnull stop) {
                BOOL ignoreRefer = object.configData.ignoreRefer || v.ne_et_ignoreReferCascade;
                NEEventTracingNodeValidMountType mountType = object.configData.mountType;
                /// MARK: 节点校验-辅助功能
                if (nodeInfoValidationEnable && node == nil) {
                    if (v.ne_et_isAutoMountOnCurrentRootPageEnable) {
                        mountType = NEEventTracingNodeValidMountTypeAuto;
                    } else if (v.ne_et_logicalParentView != nil) {
                        mountType = NEEventTracingNodeValidMountTypeManual;
                    }
                }
                stack.push(ETTraverseObject((node ?: object.parentNode), v, {ignoreRefer, mountType}));
            }];
        }
    }
}

- (NEEventTracingVTreeNode *)_nodeForObject:(ETTraverseObject)object
                                  inVTree:(NEEventTracingVTree *)VTree
                 continueTraverseSubViews:(BOOL *)continueTraverseSubViews
                    needsCheckEndlessloop:(BOOL)needsCheckEndlessloop {
    if (![object.view ne_et_isSimpleVisible]) {
        *continueTraverseSubViews = NO;
        
        return nil;
    }
    
    NEEventTracingVTreeNode *node = nil;
    
    if (NE_ET_isPageOrElement(object.view)) {
        
        // 需要针对自动挂载做循环检测
        // 非自动挂载的场景，在 `ne_et_setLogicalParentView:` 方法中实现，可大大减少检测次数
        if (needsCheckEndlessloop && NE_ET_checkIfExistsLogicalMountEndlessLoopAtView(object.view, object.parentNode.view)) {
            return nil;
        }
        
        node = [NEEventTracingVTreeNode buildWithView:object.view];
        [node associateToVTree:VTree];
        if (object.configData.ignoreRefer) {
            [node markIgnoreRefer];
        }
        
        node.validMountType = object.configData.mountType;
        
        /// MARK: 1. 自动挂载; 2. 手动挂载 => 忽略对父节点的校验
        __block BOOL ignoreParentValid = object.view.ne_et_isAutoMountOnCurrentRootPageEnable;
        if (!ignoreParentValid && object.view.ne_et_logicalParentView != nil) {
            [@[object.view.ne_et_logicalParentView] ne_et_enumerateObjectsUsingBlock:^NSArray * _Nonnull(id  _Nonnull obj, BOOL * _Nonnull stop) {
                if (obj == object.parentNode.view) {
                    ignoreParentValid = YES;
                    *stop = YES;
                }
                return NE_ET_superView(obj) ? @[NE_ET_superView(obj)] : nil;
            }];
        }
        [VTree pushNode:node parentNode:object.parentNode ignoreParentValid:ignoreParentValid];
        
        // MARK: 更新节点的可见性
        [VTree updateVisibleForNode:node];
        
        // validForContainingSubNodeOids
        [self _setupValidForContainingSubNodeOidsForNode:node];
        
        // MARK: => Params
        [node updateStaticParams:object.view.ne_et_params];
        [node doUpdateDynamicParams];
        
        // 虚拟父节点
        [self _updateVirtualParentNodeForNodeIfNeeded:node
                                           parentNode:object.parentNode
                                              inVTree:VTree
                                    ignoreParentValid:ignoreParentValid];
        
        // 子page强行作为rootpage
        [node updateParentNodesHasSubpageNodeMarkAsRootPageIfNeeded];
    }
    
    return node;
}

- (void)_setupValidForContainingSubNodeOidsForNode:(NEEventTracingVTreeNode *)node {
    NSArray<NSString *> *validForContainingSubNodeOids = [node.view ne_et_validForContainingSubNodeOids];
    UIViewController *vc = node.view.ne_et_currentViewController;
    if (vc) {
        validForContainingSubNodeOids = [vc ne_et_validForContainingSubNodeOids];
    }
    node.validForContainingSubNodeOids = validForContainingSubNodeOids;
}

// 虚拟父节点处理
// 1. 先找到有虚拟父节点的view（自底向上，查找截止到父节点view），如果找不到即结束
// 2. 增加虚拟父节点
- (void)_updateVirtualParentNodeForNodeIfNeeded:(NEEventTracingVTreeNode *)node
                                     parentNode:(NEEventTracingVTreeNode *)parentNode
                                        inVTree:(NEEventTracingVTree *)VTree
                              ignoreParentValid:(BOOL)ignoreParentValid {
    UIView *view = node.view;
    while (view && view != parentNode.view && !view.ne_et_virtualParentProps.hasVirtualParentNode) {
        view = NE_ET_superView(view);
    }
    // 只考虑两个父子节点之间的其他view，是否设置了虚拟父节点
    view = view != parentNode.view ? view : nil;
    
    if (!view.ne_et_virtualParentProps.hasVirtualParentNode) {
        return;
    }
    
    [node.parentNode removeSubNode:node];
    
    NSString *virtualParentNodeIdentifier = view.ne_et_virtualParentProps.virtualParentNodeIdentifier;
    NSString *virtualParentNodeOid = view.ne_et_virtualParentOid;
    NSDictionary *virtualParentNodeParams = view.ne_et_virtualParentProps.virtualParentNodeParams;
    NEEventTracingVTreeNode *virtualParentNode = [parentNode.subNodes bk_match:^BOOL(NEEventTracingVTreeNode *obj) {
        return [obj.identifier isEqualToString:virtualParentNodeIdentifier]
                && ([obj.oid isEqualToString:virtualParentNodeOid]);
    }];
    if (!virtualParentNode) {
        virtualParentNode = [NEEventTracingVTreeNode buildVirtualNodeWithOid:view.ne_et_virtualParentOid
                                                                      isPage:view.ne_et_virtualParentIsPage
                                                                  identifier:virtualParentNodeIdentifier
                                                                    position:view.ne_et_virtualParentProps.position
                                              buildinEventLogDisableStrategy:view.ne_et_virtualParentProps.buildinEventLogDisableStrategy
                                                                      params:virtualParentNodeParams];
        
        /// MARK: 虚拟父节点是否校验父节点，跟随原节点走
        [VTree pushNode:virtualParentNode parentNode:parentNode ignoreParentValid:ignoreParentValid];
    } else if (virtualParentNodeParams.count) {
        NSMutableDictionary *params = [virtualParentNode.innerStaticParams ?: @[] mutableCopy];
        [params addEntriesFromDictionary:view.ne_et_virtualParentProps.virtualParentNodeParams];
        [virtualParentNode updateStaticParams:params];
    }
    
    [VTree pushNode:node parentNode:virtualParentNode ignoreParentValid:view.ne_et_virtualParentIsPage == NO];
}

@end
