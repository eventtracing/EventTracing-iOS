//
//  UIView+EventTracingPrivate.h
//  BlocksKit
//
//  Created by dl on 2021/2/4.
//

#import <UIKit/UIKit.h>
#import "UIView+EventTracing.h"
#import "EventTracingAssociatedPros.h"

#import "UIView+EventTracingNodeImpressObserver.h"
#import "EventTracingVTreeNodeExtraConfigProtocol.h"
#import "EventTracingEventActionConfig.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSArray<UIView *> *EventTracingAutoMountRootPageViews(void);
FOUNDATION_EXPORT NSArray<UIView *> *EventTracingLogicalParentSPMViews(void);

// 几个非公开的便捷方法
FOUNDATION_EXPORT __attribute__((overloadable)) UIView *ET_FindAncestorNodeViewAt(UIView *view, BOOL onlyPage);
FOUNDATION_EXPORT __attribute__((overloadable)) UIView *ET_FindSubNodeViewAt(UIView *view);
FOUNDATION_EXPORT __attribute__((overloadable)) UIView *ET_FindSubNodeViewAt(UIView *view, BOOL onlyPage);

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

@interface UIView (EventTracingPrivate) <EventTracingVTreeNodeExtraConfigProtocol>

/// MARK: pros
@property(nonatomic, weak, readwrite, nullable, setter=et_setCurrentVTreeNode:) EventTracingVTreeNode *et_currentVTreeNode;
@end

@interface UIView (EventTracingPrivate_Direct)
@property(nonatomic, strong, nullable, direct, setter=et_setProps:) EventTracingAssociatedPros *et_props;
@property(nonatomic, strong, nullable, direct, setter=et_setVirtualParentProps:) EventTracingVirtualParentAssociatedPros *et_virtualParentProps;

@property(nonatomic, assign, readonly, direct, getter=et_isSimpleVisible) BOOL et_simipleVisilble;

@property(nonatomic, assign, readonly, direct) BOOL et_hasSubNodes;
@property(nonatomic, strong, direct, setter=et_setSubLogicalViews:) NSHashTable<EventTracingWeakObjectContainer<UIView *> *> *et_subLogicalViews;
@property(nonatomic, strong, readonly, nullable) UIViewController *et_currentViewController;

// refresh self and subviews node dynamicParams
// 当一个UIView需要被从屏幕中移除之前，做掉这个参数同步
// 或者一个view(cell)在即将进入复用队列的时候
- (void)et_tryRefreshDynamicParamsCascadeSubViews __attribute__((objc_direct));
@end

@interface UIView (EventTracingPipEventInternal)
@property(nonatomic, strong, readonly, direct, getter=et_pipEventViews) NSMutableDictionary<NSString *, NSHashTable<UIView *> *> *et_pipEventViews;
@property(nonatomic, strong, readonly, direct, getter=et_pipEventToView) NSMapTable<NSString *, UIView *> *et_pipEventToView;
@end

@interface UIViewController (EventTracingPrivate) <EventTracingVTreeNodeExtraConfigProtocol>
/// MARK: vc.view
@property(nonatomic, strong, readonly) UIView *p_et_view;

/// MARK: vc是否正在 `transitioning`, 如果正在展示中，则不做自动逻辑挂载
@property(nonatomic, assign, getter=et_isTransitioning, setter=et_setTransitioning:) BOOL et_transitioning;
@end

#pragma mark - UIAlertController & UIAlertAction
@interface UIAlertAction (EventTracingPrivate)

@property(nonatomic, weak, readwrite, setter=et_setAlertController:) UIAlertController *et_alertController;
@property(nonatomic, strong, readonly) NSMutableDictionary *et_innerParams;
@property(nonatomic, strong, readonly) EventTracingEventActionConfig *et_logEventActionConfig;

@end

/// Action被触发的时候，是在 alertController dismiss finished的时候，这个时候，已经消失了，新的虚拟树已经不包含该view了
@interface UIAlertController (EventTracingPrivate)
@property(nonatomic, strong, setter=et_setVTreeNodeCopy:) EventTracingVTreeNode *et_VTreeNodeCopy;
@property(nonatomic, strong, setter=et_setVTreeCopy:) EventTracingVTree *et_VTreeCopy;
@end

NS_ASSUME_NONNULL_END
