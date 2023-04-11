//
//  EventTracingTraverser.m
//  BlocksKit
//
//  Created by dl on 2021/2/4.
//

#import "EventTracingTraverser.h"
#import <stack>
#import <BlocksKit/BlocksKit.h>

#import "EventTracingInternalLog.h"
#import "NSArray+ETEnumerator.h"

#import "EventTracingVTree+Private.h"
#import "EventTracingVTree+Visible.h"
#import "EventTracingVTree+Sync.h"
#import "EventTracingVTreeNode+Private.h"

#import "UIView+EventTracingPrivate.h"
#import "EventTracingEngine+Private.h"

BOOL ET_isPage(UIView *view) {
    return view && view.et_pageId.length > 0;
}

BOOL ET_isElement(UIView *view) {
    return view && view.et_elementId.length > 0;
}

BOOL ET_isPageOrElement(UIView *view) {
    EventTracingAssociatedPros *props = view.et_props;
    return view && (props.pageId.length > 0 || props.elementId.length > 0);
}

NSArray<UIView *> * ET_subViews(UIView *view) {
    NSMutableArray<UIView *> *views = [NSMutableArray array];
    [[view.subviews copy] enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        BOOL hasLogicalParentView = obj.et_logicalParentView != nil;
        BOOL hasLogicalParentSPM = obj.et_logicalParentSPM != nil;
        BOOL autoMountOnRootPage = obj.et_isAutoMountOnCurrentRootPageEnable;
        
        if (hasLogicalParentView || hasLogicalParentSPM || autoMountOnRootPage) {
            return;
        }
        
        [views addObject:obj];
    }];
    
    if (view.et_subLogicalViews.count) {
        [views addObjectsFromArray:[view.et_subLogicalViews.allObjects bk_map:^id(EventTracingWeakObjectContainer<UIView *> *obj) {
            return obj.target;
        }]];
    }
    return views.copy;
}

UIView * _Nullable ET_superView(UIView *view) {
    if (view.et_logicalParentView) {
        return view.et_logicalParentView;
    }
    if (view.et_logicalParentSPM != nil && ET_isPage(view)) {
        return view.et_currentVTreeNode.parentNode.view;
    }
    if (view.et_isAutoMountOnCurrentRootPageEnable && ET_isPageOrElement(view)) {
        return view.et_currentVTreeNode.parentNode.view;
    }
    return view.superview;
}

/// MARK: 节点校验-辅助功能
/// 从当前view向上找，直到找个一个节点为止，如果中间发现手动挂载(中间不出现自动挂载)，则 return YES
BOOL ET_viewIsLogicalMount(UIView *view) {
    // 1. 如果当前节点有手动挂载，则直接可判定 => YES
    if (view.et_logicalParentView != nil) {
        return YES;
    }
    // 2. 如果该节点是自动挂载的节点，则可直接判断 => NO
    if (view.et_isAutoMountOnCurrentRootPageEnable) {
        return NO;
    }
    
    // 3. 需要向上遍历(到第一个节点为止)
    //   3.1 如果遇到了自动挂载view，则终止，可判断为 NO
    //   3.2 如果遇到了手动挂载view，则终止，可判断为 YES
    UIView *nextView = ET_superView(view);
    BOOL logicalMount = NO;
    while (nextView != nil && !ET_isPageOrElement(nextView) && nextView.et_isAutoMountOnCurrentRootPageEnable) {
        if (nextView.et_logicalParentView != nil) {
            logicalMount = YES;
            break;
        }
        nextView = ET_superView(nextView);
    }
    return logicalMount;
}

/// MARK: 节点校验-辅助功能
BOOL ET_viewIsAutoMount(UIView *view) {
    // 1. 如果该节点是自动挂载的节点，则可直接判断 => YES
    if (view.et_isAutoMountOnCurrentRootPageEnable) {
        return YES;
    }
    
    // 2. 如果当前节点有手动挂载，则直接可判定 => NO
    if (view.et_logicalParentView != nil) {
        return NO;
    }
    
    // 3. 需要向上遍历(到第一个节点为止)
    //   3.1 如果遇到了自动挂载view，则终止，可判断为 NO
    //   3.2 如果遇到了手动挂载view，则终止，可判断为 YES
    UIView *nextView = ET_superView(view);
    BOOL autoMount = NO;
    while (nextView != nil && !ET_isPageOrElement(nextView) && nextView.et_logicalParentView == nil) {
        if (nextView.et_isAutoMountOnCurrentRootPageEnable) {
            autoMount = YES;
            break;
        }
        nextView = ET_superView(nextView);
    }
    return autoMount;
}

BOOL ET_isIgnoreRefer(UIView *view) {
    UIView *nextView = view;
    while (nextView && !nextView.et_ignoreReferCascade) {
        nextView = ET_superView(nextView);
    }
    
    return nextView && nextView.et_ignoreReferCascade;
}

BOOL ET_isHasSubNodes(UIView *view) {
    __block BOOL hasSubNodes = NO;
    
    [view.subviews et_enumerateObjectsUsingBlock:^NSArray<__kindof UIView *> * _Nonnull(__kindof UIView * _Nonnull nextView, BOOL * _Nonnull stop) {
        hasSubNodes = ET_isPageOrElement(nextView);
        
        if (hasSubNodes) {
            *stop = YES;
        }

        return nextView.subviews;
    }];
    
    return hasSubNodes;
}

CGRect ET_viewVisibleRectOnSelf(UIView *view) {
    if (!view) {
        return CGRectZero;
    }
    
    return UIEdgeInsetsInsetRect(view.bounds, view.et_visibleEdgeInsets);
}

CGRect ET_calculateVisibleRect(UIView *view, CGRect visibleRectOnView, CGRect containerVisibleRect) {
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

BOOL ET_checkIfExistsLogicalMountEndlessLoopAtView(UIView *view, UIView *viewToMount) {
    if (!view || !viewToMount) {
        return NO;
    }
    
    void(^exceptionBlock)(void) = ^(void) {
        id<EventTracingExceptionDelegate> exceptionDelegate = [EventTracingEngine sharedInstance].context.exceptionInterface;
        NSString *errmsg = [NSString stringWithFormat:@"View logical mount endlessloop: view: %@, viewToMount: %@", view, viewToMount];
        if ([exceptionDelegate respondsToSelector:@selector(logicalMountEndlessLoopExceptionKey:code:message:view:viewToMount:)]) {
            [exceptionDelegate logicalMountEndlessLoopExceptionKey:@"LogicalMountEndlessLoop"
                                                              code:EventTracingExceptionCodeLogicalMountEndlessLoop
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
    [@[viewToMount] et_enumerateObjectsUsingBlock:^NSArray<UIView *> * _Nonnull(UIView * _Nonnull obj, BOOL * _Nonnull stop) {
        if (obj == view) {
            hasEndlessLoop = YES;
            *stop = YES;
        }
        
        UIView *nextView = ET_superView(obj);
        return nextView ? @[nextView] : nil;
    }];
    
    if (hasEndlessLoop) {
        exceptionBlock();
        return YES;
    }
    
    return NO;
}

NSString * _Nullable ET_undefinedXpathReferForView(UIView *view) {
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

BOOL ET_checkIfExistsAncestorViewControllerTransitioning(UIView *view) {
    UIViewController *viewController = nil;
    UIResponder *next = view;
    
    while (next != nil) {
        if ([next isKindOfClass:UIViewController.class]
            && ![next isMemberOfClass:UIViewController.class]
            && ![next isKindOfClass:UINavigationController.class]) {
            viewController = (UIViewController *)next;
        }
        
        if (viewController.et_isTransitioning) {
            break;
        }
        
        next = next.nextResponder;
    }
    
    return viewController.et_transitioning;
}

@implementation EventTracingTraverser

- (void)cleanAssociationForPreVTree:(EventTracingVTree *)VTree {
    [VTree.rootNode.subNodes et_enumerateObjectsUsingBlock:^NSArray<EventTracingVTreeNode *> * _Nonnull(EventTracingVTreeNode * _Nonnull node, BOOL * _Nonnull stop) {
        node.view.et_currentVTreeNode = nil;
        
        return node.subNodes;
    }];
}

- (void)associateNodeToViewForVTree:(EventTracingVTree *)VTree {
    [VTree.rootNode.subNodes et_enumerateObjectsUsingBlock:^NSArray<EventTracingVTreeNode *> * _Nonnull(EventTracingVTreeNode * _Nonnull node, BOOL * _Nonnull stop) {
        node.view.et_currentVTreeNode = node;
        
        return node.subNodes;
    }];
}

// View 上的一些额外配置，可以随着view树的递归一起参与遍历，可减少后续再单独遍历
struct ETTraverseObjectViewConfigData {
    BOOL ignoreRefer;
};

struct ETTraverseObject {
    EventTracingVTreeNode *parentNode;
    UIView *view;
    ETTraverseObjectViewConfigData configData;
    
    ETTraverseObject(EventTracingVTreeNode *p, UIView *v, ETTraverseObjectViewConfigData data) :
    parentNode(p), view(v), configData(data) {};
};

- (EventTracingVTree *)totalGenerateVTreeFromWindows {
    NSMutableArray<UIWindow *> *windows = [UIApplication sharedApplication].windows.mutableCopy;
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    if (keyWindow && ![windows containsObject:keyWindow]) {
        [windows addObject:keyWindow];
    }
    
    EventTracingVTree *VTree = [[EventTracingVTree alloc] init];
    
    NSMutableArray<EventTracingVTreeNode *> *needsMakeSureValidNodes = [@[] mutableCopy];

    [self _pushItemsToVTree:VTree
                 parentNode:nil
                      views:windows
    needsMakeSureValidNodes:needsMakeSureValidNodes
      needsCheckEndlessloop:NO];
    
    [needsMakeSureValidNodes enumerateObjectsUsingBlock:^(EventTracingVTreeNode * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.subNodes.count == 0) {
            [obj.parentNode removeSubNode:obj];
        }
    }];
    
    // 自动挂载到rootPage的逻辑
    EventTracingVTreeNode *rootPageNode = [VTree findToppestRightPageNode];
    if (rootPageNode && !ET_checkIfExistsAncestorViewControllerTransitioning(rootPageNode.view)) {
        [self _pushItemsToVTree:VTree
                     parentNode:rootPageNode
                          views:EventTracingAutoMountRootPageViews()
        needsMakeSureValidNodes:nil
         needsCheckEndlessloop:YES];
    }
    
    // spm 形式的挂载
    [self _mountLogicalParentSPMViewsToVTree:VTree];
    
    return VTree;
}

- (EventTracingVTree *)incrementalGenerateVTreeFrom:(EventTracingVTree *)VTree views:(NSArray<UIView *> *)views {
    if (!VTree) {
        return [self totalGenerateVTreeFromWindows];
    }

    // 首先，view内部得有节点
    NSArray<UIView *> *hasSubNodeViews = [views bk_reject:^BOOL(UIView *obj) {
        return !obj.et_hasSubNodes;
    }];
    
    // 如果当前view不是一个节点，则可以尝试向上追溯, 找到向上最近的一个节点
    NSMutableSet<UIView *> *nodableViews = [NSMutableSet set];
    [hasSubNodeViews enumerateObjectsUsingBlock:^(UIView * _Nonnull view, NSUInteger idx, BOOL * _Nonnull stop) {
        if (ET_isPageOrElement(view)) {
            [nodableViews addObject:view];
        } else if(ET_superView(view)) {
            [@[ET_superView(view)] et_enumerateObjectsUsingBlock:^NSArray<UIView *> * _Nonnull(UIView * _Nonnull obj, BOOL * _Nonnull stop) {
                if (ET_isPageOrElement(obj)) {
                    [nodableViews addObject:obj];
                    *stop = YES;
                }
                return ET_superView(obj) ? @[ET_superView(obj)] : nil;
            }];
        }
    }];
    
    // 剔除有上下级重叠的ScrollView，防止重复构建
    NSMutableSet<UIView *> *validViews = nodableViews.mutableCopy;
    [nodableViews enumerateObjectsUsingBlock:^(UIView * _Nonnull view, BOOL * _Nonnull stop) {
        UIView *next = view;
        while (next) {
            next = ET_superView(next);
            
            if ([nodableViews containsObject:(UIView *)next]) {
                [validViews removeObject:view];
                next = nil;
            }
        }
    }];
    
    __block EventTracingVTree *VTreeCopy = nil;
    __block EventTracingVTreeNode *rootPageNode = nil;
    __block BOOL needAutoMoundNodes = NO;
    
    __block BOOL VTreeChanged = NO;
    [validViews enumerateObjectsUsingBlock:^(UIView * _Nonnull view, BOOL * _Nonnull stop) {
        EventTracingVTreeNode *viewNode = view.et_currentVTreeNode;
        
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
        __block EventTracingVTreeNode *parentNode = nil;
        [VTreeCopy.rootNode.subNodes et_enumerateObjectsUsingBlock:^NSArray<EventTracingVTreeNode *> * _Nonnull(EventTracingVTreeNode * _Nonnull obj, BOOL * _Nonnull stop) {
            if ([obj et_isEqualToDiffableObject:viewNode]) {
                parentNode = obj;
                *stop = YES;
            }
            return obj.subNodes;
        }];
        
        [parentNode.subNodes enumerateObjectsUsingBlock:^(EventTracingVTreeNode * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [parentNode removeSubNode:obj];
        }];
        
        VTreeChanged = YES;
        
        // 如果当前需要构建的节点是 rootPage, 则需要重新做自动挂载
        needAutoMoundNodes = needAutoMoundNodes || [parentNode et_isEqualToDiffableObject:rootPageNode];
        
        [self _pushItemsToVTree:VTreeCopy
                     parentNode:parentNode
                          views:ET_subViews(view)
        needsMakeSureValidNodes:nil
          needsCheckEndlessloop:NO];
    }];
    
    if (!VTreeChanged) {
        return VTree;
    }
    
    // 需要重新处理: 自动挂载到rootPage的逻辑
    if (needAutoMoundNodes && !ET_checkIfExistsAncestorViewControllerTransitioning(rootPageNode.view)) {
        [self _pushItemsToVTree:VTreeCopy
                     parentNode:rootPageNode
                          views:EventTracingAutoMountRootPageViews()
        needsMakeSureValidNodes:nil
         needsCheckEndlessloop:YES];
    }
    
    // spm 形式的逻辑挂载
    [self _mountLogicalParentSPMViewsToVTree:VTree];
    
    return VTreeCopy;
}

#pragma mark - private methods
- (void)_mountLogicalParentSPMViewsToVTree:(EventTracingVTree *)VTree {
    [EventTracingLogicalParentSPMViews() enumerateObjectsUsingBlock:^(UIView * _Nonnull view, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *spm = view.et_logicalParentSPM;
        EventTracingVTreeNode *parentNode = [VTree nodeForSpm:spm];
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

- (void)_pushItemsToVTree:(EventTracingVTree *)VTree
               parentNode:(EventTracingVTreeNode * _Nullable)parentNode
                    views:(NSArray<UIView *> *)views
  needsMakeSureValidNodes:(NSMutableArray<EventTracingVTreeNode *> *)needsMakeSureValidNodes
    needsCheckEndlessloop:(BOOL)needsCheckEndlessloop {
    
    __block std::stack<ETTraverseObject> stack;
    [views enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(UIView * _Nonnull v, NSUInteger idx, BOOL * _Nonnull stop) {
        stack.push(ETTraverseObject(parentNode, v, {ET_isIgnoreRefer(v)}));
    }];
    
    while (!stack.empty()) {
        ETTraverseObject object = stack.top();
        
        BOOL continueTraverseSubViews = YES;
        EventTracingVTreeNode *node = [self _nodeForObject:object
                                                   inVTree:VTree
                                  continueTraverseSubViews:&continueTraverseSubViews
                                     needsCheckEndlessloop:needsCheckEndlessloop];

        if (needsMakeSureValidNodes && node.validForContainingSubNodeOids.count) {
            [needsMakeSureValidNodes addObject:node];
        }
        
        stack.pop();
        
        if (continueTraverseSubViews) {
            [ET_subViews(object.view) enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(UIView * _Nonnull v, NSUInteger idx, BOOL * _Nonnull stop) {
                BOOL ignoreRefer = object.configData.ignoreRefer || v.et_ignoreReferCascade;
                stack.push(ETTraverseObject((node ?: object.parentNode), v, {ignoreRefer}));
            }];
        }
    }
}

- (EventTracingVTreeNode *)_nodeForObject:(ETTraverseObject)object
                                  inVTree:(EventTracingVTree *)VTree
                 continueTraverseSubViews:(BOOL *)continueTraverseSubViews
                    needsCheckEndlessloop:(BOOL)needsCheckEndlessloop {
    if (![object.view et_isSimpleVisible]) {
        *continueTraverseSubViews = NO;
        
        return nil;
    }
    
    EventTracingVTreeNode *node = nil;
    
    if (ET_isPageOrElement(object.view)) {
        
        // 需要针对自动挂载做循环检测
        // 非自动挂载的场景，在 `et_setLogicalParentView:` 方法中实现，可大大减少检测次数
        if (needsCheckEndlessloop && ET_checkIfExistsLogicalMountEndlessLoopAtView(object.view, object.parentNode.view)) {
            return nil;
        }
        
        node = [EventTracingVTreeNode buildWithView:object.view];
        [node associateToVTree:VTree];
        if (object.configData.ignoreRefer) {
            [node markIgnoreRefer];
        }
        
        /// MARK: 1. 自动挂载; => 忽略对父节点的校验
        BOOL ignoreParentValid = object.view.et_isAutoMountOnCurrentRootPageEnable;
        [VTree pushNode:node parentNode:object.parentNode ignoreParentValid:ignoreParentValid];
        
        // MARK: 更新节点的可见性
        [VTree updateVisibleForNode:node];
        
        // validForContainingSubNodeOids
        [self _setupValidForContainingSubNodeOidsForNode:node];
        
        // MARK: => Params
        [node updateStaticParams:object.view.et_params];
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

- (void)_setupValidForContainingSubNodeOidsForNode:(EventTracingVTreeNode *)node {
    NSArray<NSString *> *validForContainingSubNodeOids = [node.view et_validForContainingSubNodeOids];
    UIViewController *vc = node.view.et_currentViewController;
    if (vc) {
        validForContainingSubNodeOids = [vc et_validForContainingSubNodeOids];
    }
    node.validForContainingSubNodeOids = validForContainingSubNodeOids;
}

// 虚拟父节点处理
// 1. 先找到有虚拟父节点的view（自底向上，查找截止到父节点view），如果找不到即结束
// 2. 增加虚拟父节点
- (void)_updateVirtualParentNodeForNodeIfNeeded:(EventTracingVTreeNode *)node
                                     parentNode:(EventTracingVTreeNode *)parentNode
                                        inVTree:(EventTracingVTree *)VTree
                              ignoreParentValid:(BOOL)ignoreParentValid {
    UIView *view = node.view;
    while (view && view != parentNode.view && !view.et_virtualParentProps.hasVirtualParentNode) {
        view = ET_superView(view);
    }
    // 只考虑两个父子节点之间的其他view，是否设置了虚拟父节点
    view = view != parentNode.view ? view : nil;
    
    if (!view.et_virtualParentProps.hasVirtualParentNode) {
        return;
    }
    
    [node.parentNode removeSubNode:node];
    
    NSString *virtualParentNodeIdentifier = view.et_virtualParentProps.virtualParentNodeIdentifier;
    NSString *virtualParentNodeOid = view.et_virtualParentOid;
    NSDictionary *virtualParentNodeParams = view.et_virtualParentProps.virtualParentNodeParams;
    EventTracingVTreeNode *virtualParentNode = [parentNode.subNodes bk_match:^BOOL(EventTracingVTreeNode *obj) {
        return [obj.identifier isEqualToString:virtualParentNodeIdentifier]
                && ([obj.oid isEqualToString:virtualParentNodeOid]);
    }];
    if (!virtualParentNode) {
        virtualParentNode = [EventTracingVTreeNode buildVirtualNodeWithOid:view.et_virtualParentOid
                                                                    isPage:view.et_virtualParentIsPage
                                                                identifier:virtualParentNodeIdentifier
                                                                  position:view.et_virtualParentProps.position
                                            buildinEventLogDisableStrategy:view.et_virtualParentProps.buildinEventLogDisableStrategy
                                                                  params:virtualParentNodeParams];
        
        /// MARK: 虚拟父节点是否校验父节点，跟随原节点走
        [VTree pushNode:virtualParentNode parentNode:parentNode ignoreParentValid:ignoreParentValid];
    } else if (virtualParentNodeParams.count) {
        NSMutableDictionary *params = [virtualParentNode.innerStaticParams ?: @[] mutableCopy];
        [params addEntriesFromDictionary:view.et_virtualParentProps.virtualParentNodeParams];
        [virtualParentNode updateStaticParams:params];
    }
    
    [VTree pushNode:node parentNode:virtualParentNode ignoreParentValid:YES];
}

@end
