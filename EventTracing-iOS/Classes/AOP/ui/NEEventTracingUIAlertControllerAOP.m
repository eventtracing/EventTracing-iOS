//
//  EventTracingUIAlertControllerAOP.m
//  BlocksKit
//
//  Created by dl on 2021/4/7.
//

#import "EventTracingUIAlertControllerAOP.h"
#import "EventTracingDelegateChain.h"

#import "EventTracingVTree+Sync.h"
#import "EventTracingVTreeNode+Private.h"
#import "EventTracingEngine+Private.h"
#import "UIAlertController+EventTracingParams.h"
#import "UIView+EventTracingPrivate.h"
#import "EventTracingEventReferQueue.h"
#import "EventTracingConfuseMacro.h"

#import "NSArray+ETEnumerator.h"
#import <BlocksKit/BlocksKit.h>
#import <JRSwizzle/JRSwizzle.h>
#import <objc/runtime.h>

@interface UIAlertAction (EventTracingAOP)
@property (nonatomic, strong, setter=et_setVTreeNodeCopy:) EventTracingVTreeNode *et_VTreeNodeCopy;
@property (nonatomic, weak, setter=et_setActionView:) UIView *et_actionView;
@end

@interface UIAlertController (EventTracingAOP) <EventTracingVTreeObserver>
@end
@implementation UIAlertController (EventTracingAOP)

/// MARK: AOP
- (void)et_alertController_viewDidLoad {
    [self et_alertController_viewDidLoad];
    
    [[EventTracingEngine sharedInstance] addVTreeObserver:self];
    
    self.view.et_ignoreReferCascade = YES;
}

- (void)et_alertController_viewDidAppear:(BOOL)animated {
    [self et_alertController_viewDidAppear:animated];
    
    /// MARK: 通过在这个时机遍历系统Alert的子view，来设置元素oid
    NSMutableDictionary<NSString *, UIAlertAction *> *actionTitleOidMap = @{}.mutableCopy;
    [[self.actions bk_reject:^BOOL(UIAlertAction *obj) {
        return obj.title.length == 0;
    }] bk_each:^(UIAlertAction *alertAction) {
        [actionTitleOidMap setObject:alertAction forKey:alertAction.title];
    }];
    
    NSMutableArray<UIView *> *actionViews = @[].mutableCopy;
    // Alert || Actionsheet 中按钮，都处于 `UIStackView` 内，并且在 `_UIAlertControllerActionView` 内的label.text就是按钮文案
    [self.view.subviews et_enumerateObjectsUsingBlock:^NSArray<__kindof UIView *> * _Nonnull(__kindof UIView * _Nonnull obj, BOOL * _Nonnull stop) {
        if (ET_STR_MATCHES(NSStringFromClass([obj class]), ET_CONFUSED(_,U,I,A,l,e,r,t),@"Controller",@"Action",@"View")) {
            [actionViews addObject:obj];
            return nil;
        }
        return obj.subviews;
    }];
    
    /// MARK: _UIAlertControllerActionView 内的label文案来判断该是什么oid
    [actionViews enumerateObjectsUsingBlock:^(UIView * _Nonnull actionView, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *actionTitle = [self _et_alertActionTitleFromActionView:actionView];
        UIAlertAction *alertAction = [actionTitleOidMap objectForKey:actionTitle];
        NSDictionary *params = alertAction.et_innerParams ?: @{};
        [actionView et_setElementId:alertAction.et_elementId params:params];
        actionView.et_position = alertAction.et_position;
        actionView.et_buildinEventLogDisableStrategy = ETNodeBuildinEventLogDisableStrategyAll;
        
        alertAction.et_actionView = actionView;
    }];
}

- (void)et_alertController_addAction:(UIAlertAction *)action {
    [self et_alertController_addAction:action];
    
    action.et_alertController = self;
}

#pragma mark - EventTracingVTreeObserver
- (void)didGenerateVTree:(EventTracingVTree *)VTree
               lastVTree:(EventTracingVTree * _Nullable)lastVTree
              hasChanges:(BOOL)hasChanges {
    EventTracingVTree *VTreeCopy = VTree.copy;
    EventTracingVTreeNode *node = self.et_currentVTreeNode;
    if (!node) {
        return;
    }
    
    self.et_VTreeCopy = VTreeCopy;
    self.et_VTreeNodeCopy = [VTreeCopy nodeForSpm:node.spm];
    
    [[self.actions bk_reject:^BOOL(UIAlertAction *action) {
        return !action.et_isElement;
    }] enumerateObjectsUsingBlock:^(UIAlertAction * _Nonnull action, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *actionSPM = action.et_elementId;
        if (action.et_position > 0) {
            actionSPM = [NSString stringWithFormat:@"%@:%@", action.et_elementId, @(action.et_position).stringValue];
        }
        actionSPM = [NSString stringWithFormat:@"%@|%@", actionSPM, node.spm];
        
        action.et_VTreeNodeCopy = [VTreeCopy nodeForSpm:actionSPM];
    }];
}

// 只此一处 overrite
- (void)et_setPageId:(NSString *)pageId params:(NSDictionary<NSString *,NSString *> *)params {
    [super et_setPageId:pageId params:params];
    
    [self et_autoMountOnCurrentRootPageWithPriority:ETAutoMountRootPageQueuePriorityVeryHigh];
}

- (EventTracingVTreeNode *)et_VTreeNodeCopy {
    return objc_getAssociatedObject(self, _cmd);
}
- (void)et_setVTreeNodeCopy:(EventTracingVTreeNode *)et_VTreeNodeCopy {
    objc_setAssociatedObject(self, @selector(et_VTreeNodeCopy), et_VTreeNodeCopy, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (EventTracingVTree *)et_VTreeCopy {
    return objc_getAssociatedObject(self, _cmd);
}
- (void)et_setVTreeCopy:(EventTracingVTree *)et_VTreeCopy {
    objc_setAssociatedObject(self, @selector(et_VTreeCopy), et_VTreeCopy, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark - private methods
- (NSString *) _et_alertActionTitleFromActionView:(UIView *)actionView {
    __block NSString *title = nil;
    [@[actionView] et_enumerateObjectsUsingBlock:^NSArray * _Nonnull(UIView * _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[UILabel class]]) {
            title = [(UILabel *)obj text];
            *stop = YES;
        }
        return obj.subviews;
    }];
    return title;
}

@end

@implementation UIAlertAction (EventTracingAOP)

// 这里是特殊处理的
// Alert样式的时候，点击OK按钮，是Alert dismiss finish的时候，才回调这里的hanler
// 此时该AlertView已经不再view树中了
// 而且在handler调用之前，VTree已经生成了新的版本，并且不包含AlertView
+ (instancetype)et_alertAction_actionWithTitle:(NSString *)title style:(UIAlertActionStyle)style handler:(void (^)(UIAlertAction * _Nonnull alertAction))handler {
    return [self et_alertAction_actionWithTitle:title style:style handler:^(UIAlertAction * _Nonnull alertAction) {
        
        if (!alertAction.et_isElement) {

            EventTracingVTreeNode *node = alertAction.et_VTreeNodeCopy;
            [[EventTracingEventReferQueue queue] pushEventReferForEvent:ET_EVENT_ID_E_CLCK
                                                                     view:alertAction.et_actionView
                                                                     node:node
                                                              useForRefer:NO
                                                            useNextActseq:NO];
            
            !handler ?: handler(alertAction);
            
            return;
        }
        
        EventTracingVTree *VTree = alertAction.et_alertController.et_VTreeCopy;
        EventTracingVTreeNode *node = alertAction.et_VTreeNodeCopy;
        if (!VTree || !node) {
            !handler ?: handler(alertAction);
            
            return;
        }
        
        // pre
        [self et_doPreEventActionWithAlertAction:alertAction];
        
        // original
        !handler ?: handler(alertAction);
        
        // after
        [self et_doAfterEventActionWithAlertAction:alertAction];
    }];
}

+ (void)et_doPreEventActionWithAlertAction:(UIAlertAction *)alertAction {
    EventTracingEventActionConfig *logEventActionConfig = alertAction.et_logEventActionConfig;
    EventTracingVTreeNode *node = alertAction.et_VTreeNodeCopy;
    [[EventTracingEventReferQueue queue] pushEventReferForEvent:ET_EVENT_ID_E_CLCK
                                                             view:alertAction.et_actionView
                                                             node:node
                                                      useForRefer:logEventActionConfig.useForRefer
                                                    useNextActseq:logEventActionConfig.increaseActseq];
}

+ (void)et_doAfterEventActionWithAlertAction:(UIAlertAction *)alertAction {
    EventTracingVTree *VTree = alertAction.et_alertController.et_VTreeCopy;
    EventTracingVTreeNode *node = alertAction.et_VTreeNodeCopy;
    
    UIView *actionView = alertAction.et_actionView;
    EventTracingEventAction *action = [EventTracingEventAction actionWithEvent:ET_EVENT_ID_E_CLCK view:actionView];
    [action syncFromActionConfig:alertAction.et_logEventActionConfig];
    [action setupNode:node VTree:VTree];
    
    [[(EventTracingContext *)[EventTracingEngine sharedInstance].context eventEmitter] consumeEventAction:action forceInCurrentVTree:YES];
}

- (EventTracingVTreeNode *)et_VTreeNodeCopy {
    return objc_getAssociatedObject(self, _cmd);
}
- (void)et_setVTreeNodeCopy:(EventTracingVTreeNode *)et_VTreeNodeCopy {
    objc_setAssociatedObject(self, @selector(et_VTreeNodeCopy), et_VTreeNodeCopy, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIView *)et_actionView {
    return [self bk_associatedValueForKey:_cmd];
}
- (void)et_setActionView:(UIView *)et_actionView {
    [self bk_weaklyAssociateValue:et_actionView withKey:@selector(et_actionView)];
}

@end

@implementation EventTracingUIAlertControllerAOP

EventTracingAOPInstanceImp

- (void)asyncInject {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [UIAlertController jr_swizzleMethod:@selector(addAction:) withMethod:@selector(et_alertController_addAction:) error:nil];
        [UIAlertController jr_swizzleMethod:@selector(viewDidLoad) withMethod:@selector(et_alertController_viewDidLoad) error:nil];
        [UIAlertController jr_swizzleMethod:@selector(viewDidAppear:) withMethod:@selector(et_alertController_viewDidAppear:) error:nil];
        [UIAlertAction jr_swizzleClassMethod:@selector(actionWithTitle:style:handler:) withClassMethod:@selector(et_alertAction_actionWithTitle:style:handler:) error:nil];
    });
}

@end
