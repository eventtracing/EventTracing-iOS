//
//  UIView+EventTracingPrivate.h
//  BlocksKit
//
//  Created by dl on 2021/2/4.
//

#import <UIKit/UIKit.h>
#import "UIView+EventTracing.h"
#import "NEEventTracingAssociatedPros.h"

#import "UIView+EventTracingNodeImpressObserver.h"
#import "NEEventTracingVTreeNodeExtraConfigProtocol.h"
#import "NEEventTracingEventActionConfig.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSArray<UIView *> *NEEventTracingAutoMountRootPageViews(void);
FOUNDATION_EXPORT NSArray<UIView *> *NEEventTracingLogicalParentSPMViews(void);

// 几个非公开的便捷方法
FOUNDATION_EXPORT __attribute__((overloadable)) UIView *NE_ET_FindAncestorNodeViewAt(UIView *view, BOOL onlyPage);
FOUNDATION_EXPORT __attribute__((overloadable)) UIView *NE_ET_FindSubNodeViewAt(UIView *view);
FOUNDATION_EXPORT __attribute__((overloadable)) UIView *NE_ET_FindSubNodeViewAt(UIView *view, BOOL onlyPage);

#define ETGetArgsArr(out_args, arg0, cls) \
    va_list args;\
    va_start(args, arg0);\
    cls *v;\
    if (arg0) {\
        [out_args addObject:arg0];\
        while((v = va_arg(args, id))) {\
            if (v && [v isKindOfClass: cls.class]){\
                [out_args addObject:v];\
            }\
        }\
    }\
    va_end(args);\

@interface UIView (EventTracingPrivate) <NEEventTracingVTreeNodeExtraConfigProtocol>

/// MARK: pros
@property(nonatomic, weak, readwrite, nullable, setter=ne_et_setCurrentVTreeNode:) NEEventTracingVTreeNode *ne_et_currentVTreeNode;
@end

@interface UIView (EventTracingPrivate_Direct)
@property(nonatomic, strong, nullable, direct, setter=ne_et_setProps:) NEEventTracingAssociatedPros *ne_et_props;
@property(nonatomic, strong, nullable, direct, setter=ne_et_setVirtualParentProps:) NEEventTracingVirtualParentAssociatedPros *ne_et_virtualParentProps;

@property(nonatomic, assign, readonly, direct, getter=ne_et_isSimpleVisible) BOOL ne_et_simipleVisilble;

@property(nonatomic, assign, readonly, direct) BOOL ne_et_hasSubNodes;
@property(nonatomic, strong, direct, setter=ne_et_setSubLogicalViews:) NSHashTable<NEEventTracingWeakObjectContainer<UIView *> *> *ne_et_subLogicalViews;
@property(nonatomic, strong, readonly, nullable, direct) UIViewController *ne_et_currentViewController;

// refresh self and subviews node dynamicParams
// 当一个UIView需要被从屏幕中移除之前，做掉这个参数同步
// 或者一个view(cell)在即将进入复用队列的时候
- (void)ne_et_tryRefreshDynamicParamsCascadeSubViews __attribute__((objc_direct));
@end

@interface UIView (EventTracingPipEventInternal)
@property(nonatomic, strong, readonly, direct, getter=ne_et_pipEventViews) NSMutableDictionary<NSString *, NSHashTable<UIView *> *> *ne_et_pipEventViews;
@property(nonatomic, strong, readonly, direct, getter=ne_et_pipEventToView) NSMapTable<NSString *, UIView *> *ne_et_pipEventToView;
@end

@interface UIViewController (EventTracingPrivate) <NEEventTracingVTreeNodeExtraConfigProtocol>
/// MARK: vc.view
@property(nonatomic, strong, readonly) UIView *p_ne_et_view;

/// MARK: vc是否正在 `transitioning`, 如果正在展示中，则不做自动逻辑挂载
@property(nonatomic, assign, getter=ne_et_isTransitioning, setter=ne_et_setTransitioning:) BOOL ne_et_transitioning;
@end

#pragma mark - UIAlertController & UIAlertAction
@interface UIAlertAction (EventTracingPrivate)

@property(nonatomic, weak, readwrite, setter=ne_et_setAlertController:) UIAlertController *ne_et_alertController;
@property(nonatomic, strong, readonly) NSMutableDictionary *ne_et_innerParams;
@property(nonatomic, strong, readonly) NEEventTracingEventActionConfig *ne_et_logEventActionConfig;

@end

/// Action被触发的时候，是在 alertController dismiss finished的时候，这个时候，已经消失了，新的虚拟树已经不包含该view了
@interface UIAlertController (EventTracingPrivate)
@property(nonatomic, strong, setter=ne_et_setVTreeNodeCopy:) NEEventTracingVTreeNode *ne_et_VTreeNodeCopy;
@property(nonatomic, strong, setter=ne_et_setVTreeCopy:) NEEventTracingVTree *ne_et_VTreeCopy;
@end

NS_ASSUME_NONNULL_END
