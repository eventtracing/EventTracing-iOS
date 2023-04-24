//
//  NEEventTracingUIAlertControllerAOP.m
//  BlocksKit
//
//  Created by dl on 2021/4/7.
//

#import "NEEventTracingUIAlertControllerAOP.h"
#import "NEEventTracingDelegateChain.h"

#import "NEEventTracingVTree+Sync.h"
#import "NEEventTracingVTreeNode+Private.h"
#import "NEEventTracingEngine+Private.h"
#import "UIAlertController+EventTracingParams.h"
#import "UIView+EventTracingPrivate.h"
#import "NEEventTracingEventReferQueue.h"
#import "EventTracingConfuseMacro.h"

#import "NSArray+ETEnumerator.h"
#import <BlocksKit/BlocksKit.h>
#import <JRSwizzle/JRSwizzle.h>
#import <objc/runtime.h>

@interface UIAlertAction (EventTracingAOP)
@property (nonatomic, strong, setter=ne_et_setVTreeNodeCopy:) NEEventTracingVTreeNode *ne_et_VTreeNodeCopy;
@property (nonatomic, weak, setter=ne_et_setActionView:) UIView *ne_et_actionView;
@end

@interface UIAlertController (EventTracingAOP) <NEEventTracingVTreeObserver>
@end
@implementation UIAlertController (EventTracingAOP)

/// MARK: AOP
- (void)ne_et_alertController_viewDidLoad {
    [self ne_et_alertController_viewDidLoad];
    
    [[NEEventTracingEngine sharedInstance] addVTreeObserver:self];
    
    self.view.ne_et_ignoreReferCascade = YES;
}

- (void)ne_et_alertController_viewDidAppear:(BOOL)animated {
    [self ne_et_alertController_viewDidAppear:animated];
    
    /// MARK: 通过在这个时机遍历系统Alert的子view，来设置元素oid
    NSMutableDictionary<NSString *, UIAlertAction *> *actionTitleOidMap = @{}.mutableCopy;
    [[self.actions bk_reject:^BOOL(UIAlertAction *obj) {
        return obj.title.length == 0;
    }] bk_each:^(UIAlertAction *alertAction) {
        [actionTitleOidMap setObject:alertAction forKey:alertAction.title];
    }];
    
    NSMutableArray<UIView *> *actionViews = @[].mutableCopy;
    // Alert || Actionsheet 中按钮，都处于 `UIStackView` 内，并且在 `` 内的label.text就是按钮文案
    [self.view.subviews ne_et_enumerateObjectsUsingBlock:^NSArray<__kindof UIView *> * _Nonnull(__kindof UIView * _Nonnull obj, BOOL * _Nonnull stop) {
        if (NE_STR_MATCHES(NSStringFromClass([obj class]), ET_MANGLED(_,U,I,A,l,e,r,t),@"Controller",@"Action",@"View")) {
            [actionViews addObject:obj];
            return nil;
        }
        return obj.subviews;
    }];
    
    /// MARK: _UIAlertControllerActionView 内的label文案来判断该是什么oid
    [actionViews enumerateObjectsUsingBlock:^(UIView * _Nonnull actionView, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *actionTitle = [self _ne_et_alertActionTitleFromActionView:actionView];
        UIAlertAction *alertAction = [actionTitleOidMap objectForKey:actionTitle];
        NSDictionary *params = alertAction.ne_et_innerParams ?: @{};
        [actionView ne_et_setElementId:alertAction.ne_et_elementId params:params];
        actionView.ne_et_position = alertAction.ne_et_position;
        actionView.ne_et_buildinEventLogDisableStrategy = NEETNodeBuildinEventLogDisableStrategyAll;
        
        alertAction.ne_et_actionView = actionView;
    }];
}

- (void)ne_et_alertController_addAction:(UIAlertAction *)action {
    [self ne_et_alertController_addAction:action];
    
    action.ne_et_alertController = self;
}

#pragma mark - NEEventTracingVTreeObserver
- (void)didGenerateVTree:(NEEventTracingVTree *)VTree
               lastVTree:(NEEventTracingVTree * _Nullable)lastVTree
              hasChanges:(BOOL)hasChanges {
    NEEventTracingVTree *VTreeCopy = VTree.copy;
    NEEventTracingVTreeNode *node = self.ne_et_currentVTreeNode;
    if (!node) {
        return;
    }
    
    self.ne_et_VTreeCopy = VTreeCopy;
    self.ne_et_VTreeNodeCopy = [VTreeCopy nodeForSpm:node.spm];
    
    [[self.actions bk_reject:^BOOL(UIAlertAction *action) {
        return !action.ne_et_isElement;
    }] enumerateObjectsUsingBlock:^(UIAlertAction * _Nonnull action, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *actionSPM = action.ne_et_elementId;
        if (action.ne_et_position > 0) {
            actionSPM = [NSString stringWithFormat:@"%@:%@", action.ne_et_elementId, @(action.ne_et_position).stringValue];
        }
        actionSPM = [NSString stringWithFormat:@"%@|%@", actionSPM, node.spm];
        
        action.ne_et_VTreeNodeCopy = [VTreeCopy nodeForSpm:actionSPM];
    }];
}

// 只此一处 overrite
- (void)ne_et_setPageId:(NSString *)pageId params:(NSDictionary<NSString *,NSString *> *)params {
    [super ne_et_setPageId:pageId params:params];
    
    [self ne_et_autoMountOnCurrentRootPageWithPriority:NEETAutoMountRootPageQueuePriorityVeryHigh];
}

- (NEEventTracingVTreeNode *)ne_et_VTreeNodeCopy {
    return objc_getAssociatedObject(self, _cmd);
}
- (void)ne_et_setVTreeNodeCopy:(NEEventTracingVTreeNode *)ne_et_VTreeNodeCopy {
    objc_setAssociatedObject(self, @selector(ne_et_VTreeNodeCopy), ne_et_VTreeNodeCopy, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (NEEventTracingVTree *)ne_et_VTreeCopy {
    return objc_getAssociatedObject(self, _cmd);
}
- (void)ne_et_setVTreeCopy:(NEEventTracingVTree *)ne_et_VTreeCopy {
    objc_setAssociatedObject(self, @selector(ne_et_VTreeCopy), ne_et_VTreeCopy, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark - private methods
- (NSString *) _ne_et_alertActionTitleFromActionView:(UIView *)actionView {
    __block NSString *title = nil;
    [@[actionView] ne_et_enumerateObjectsUsingBlock:^NSArray * _Nonnull(UIView * _Nonnull obj, BOOL * _Nonnull stop) {
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
+ (instancetype)ne_et_alertAction_actionWithTitle:(NSString *)title style:(UIAlertActionStyle)style handler:(void (^)(UIAlertAction * _Nonnull alertAction))handler {
    return [self ne_et_alertAction_actionWithTitle:title style:style handler:^(UIAlertAction * _Nonnull alertAction) {
        
        if (!alertAction.ne_et_isElement) {

            NEEventTracingVTreeNode *node = alertAction.ne_et_VTreeNodeCopy;
            [[NEEventTracingEventReferQueue queue] pushEventReferForEvent:NE_ET_EVENT_ID_E_CLCK
                                                                     view:alertAction.ne_et_actionView
                                                                     node:node
                                                              useForRefer:NO
                                                            useNextActseq:NO];
            
            !handler ?: handler(alertAction);
            
            return;
        }
        
        NEEventTracingVTree *VTree = alertAction.ne_et_alertController.ne_et_VTreeCopy;
        NEEventTracingVTreeNode *node = alertAction.ne_et_VTreeNodeCopy;
        if (!VTree || !node) {
            !handler ?: handler(alertAction);
            
            return;
        }
        
        // pre
        [self ne_et_doPreEventActionWithAlertAction:alertAction];
        
        // original
        !handler ?: handler(alertAction);
        
        // after
        [self ne_et_doAfterEventActionWithAlertAction:alertAction];
    }];
}

+ (void)ne_et_doPreEventActionWithAlertAction:(UIAlertAction *)alertAction {
    NEEventTracingEventActionConfig *logEventActionConfig = alertAction.ne_et_logEventActionConfig;
    NEEventTracingVTreeNode *node = alertAction.ne_et_VTreeNodeCopy;
    [[NEEventTracingEventReferQueue queue] pushEventReferForEvent:NE_ET_EVENT_ID_E_CLCK
                                                             view:alertAction.ne_et_actionView
                                                             node:node
                                                      useForRefer:logEventActionConfig.useForRefer
                                                    useNextActseq:logEventActionConfig.increaseActseq];
}

+ (void)ne_et_doAfterEventActionWithAlertAction:(UIAlertAction *)alertAction {
    NEEventTracingVTree *VTree = alertAction.ne_et_alertController.ne_et_VTreeCopy;
    NEEventTracingVTreeNode *node = alertAction.ne_et_VTreeNodeCopy;
    
    UIView *actionView = alertAction.ne_et_actionView;
    NEEventTracingEventAction *action = [NEEventTracingEventAction actionWithEvent:NE_ET_EVENT_ID_E_CLCK view:actionView];
    [action syncFromActionConfig:alertAction.ne_et_logEventActionConfig];
    [action setupNode:node VTree:VTree];
    
    [[(NEEventTracingContext *)[NEEventTracingEngine sharedInstance].context eventEmitter] consumeEventAction:action forceInCurrentVTree:YES];
}

- (NEEventTracingVTreeNode *)ne_et_VTreeNodeCopy {
    return objc_getAssociatedObject(self, _cmd);
}
- (void)ne_et_setVTreeNodeCopy:(NEEventTracingVTreeNode *)ne_et_VTreeNodeCopy {
    objc_setAssociatedObject(self, @selector(ne_et_VTreeNodeCopy), ne_et_VTreeNodeCopy, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIView *)ne_et_actionView {
    return [self bk_associatedValueForKey:_cmd];
}
- (void)ne_et_setActionView:(UIView *)ne_et_actionView {
    [self bk_weaklyAssociateValue:ne_et_actionView withKey:@selector(ne_et_actionView)];
}

@end

@implementation NEEventTracingUIAlertControllerAOP

NEEventTracingAOPInstanceImp

- (void)asyncInject {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [UIAlertController jr_swizzleMethod:@selector(addAction:) withMethod:@selector(ne_et_alertController_addAction:) error:nil];
        [UIAlertController jr_swizzleMethod:@selector(viewDidLoad) withMethod:@selector(ne_et_alertController_viewDidLoad) error:nil];
        [UIAlertController jr_swizzleMethod:@selector(viewDidAppear:) withMethod:@selector(ne_et_alertController_viewDidAppear:) error:nil];
        [UIAlertAction jr_swizzleClassMethod:@selector(actionWithTitle:style:handler:) withClassMethod:@selector(ne_et_alertAction_actionWithTitle:style:handler:) error:nil];
    });
}

@end
