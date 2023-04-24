//
//  NEEventTracingUIControlAOP.m
//  BlocksKit
//
//  Created by dl on 2021/2/24.
//

#import "NEEventTracingUIControlAOP.h"
#import "NEEventTracingDelegateChain.h"
#import "NEEventTracingEngine+Private.h"
#import "NEEventTracingClickMonitor.h"

#import <BlocksKit/BlocksKit.h>
#import <JRSwizzle/JRSwizzle.h>
#import <objc/runtime.h>

// 保证:
//   1. pre 执行在所有的 target-action 之前
//   2. after 执行在所有的 target-action 之后
@interface UIControl (EventTracingAOP)
@property(nonatomic, copy, readonly) NSMutableArray *ne_et_lastClickActions;

- (void)ne_et_Control_sendAction:(SEL)action to:(id)target forEvent:(UIEvent *)event;
@end
@implementation UIControl (EventTracingAOP)
- (void)ne_et_Control_sendAction:(SEL)action to:(id)target forEvent:(UIEvent *)event {
    NSString *selStr = NSStringFromSelector(action);
    NSMutableArray<NSString *> *actions = @[].mutableCopy;
    [self.allTargets enumerateObjectsUsingBlock:^(id  _Nonnull obj, BOOL * _Nonnull stop) {
        NSArray<NSString *> *actionsForTarget = [self actionsForTarget:obj forControlEvent:UIControlEventTouchUpInside];
        if (actionsForTarget.count) {
            [actions addObjectsFromArray:actionsForTarget];
        }
    }];
    BOOL valid = [actions containsObject:selStr];
    if (!valid) {
        [self ne_et_Control_sendAction:action to:target forEvent:event];
        return;
    }
    
    void(^eventActionBlock)(NEEventTracingEventActionConfig * _Nonnull) = ^(NEEventTracingEventActionConfig * _Nonnull config) {
        config.useForRefer = YES;
    };
    
    // pre
    if ([self.ne_et_lastClickActions count] == 0) {
        // observers => pre
        [[[NEEventTracingClickMonitor sharedInstance] observersForView:self] enumerateObjectsUsingBlock:^(id<NEEventTracingClickObserver>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj respondsToSelector:@selector(clickMonitor:willTouchUpInsideControl:)]) {
                [(id<NEEventTracingClickControlTouchUpInsideObserver>)obj clickMonitor:[NEEventTracingClickMonitor sharedInstance] willTouchUpInsideControl:self];
            }
        }];
        
        [[NEEventTracingEngine sharedInstance] AOP_preLogWithEvent:NE_ET_EVENT_ID_E_CLCK view:self eventAction:eventActionBlock];
    }
    [self.ne_et_lastClickActions addObject:[NSString stringWithFormat:@"%@-%@", [target class], NSStringFromSelector(action)]];
    
    // original
    [self ne_et_Control_sendAction:action to:target forEvent:event];
    
    // after
    if (self.ne_et_lastClickActions.count == actions.count) {
        [[NEEventTracingEngine sharedInstance] AOP_logWithEvent:NE_ET_EVENT_ID_E_CLCK view:self params:nil eventAction:eventActionBlock];
        [self.ne_et_lastClickActions removeAllObjects];
        
        // observers => after
        [[[NEEventTracingClickMonitor sharedInstance] observersForView:self] enumerateObjectsUsingBlock:^(id<NEEventTracingClickObserver>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj respondsToSelector:@selector(clickMonitor:didTouchUpInsideControl:)]) {
                [(id<NEEventTracingClickControlTouchUpInsideObserver>)obj clickMonitor:[NEEventTracingClickMonitor sharedInstance] didTouchUpInsideControl:self];
            }
        }];
    }
}

- (NSMutableArray *)ne_et_lastClickActions {
    NSMutableArray * actions = objc_getAssociatedObject(self, _cmd);
    if (!actions) {
        actions = [@[] mutableCopy];
        objc_setAssociatedObject(self, _cmd, actions, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return actions;
}

@end

@implementation NEEventTracingUIControlAOP

NEEventTracingAOPInstanceImp

- (void)asyncInject {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [UIControl jr_swizzleMethod:@selector(sendAction:to:forEvent:) withMethod:@selector(ne_et_Control_sendAction:to:forEvent:) error:nil];
    });
}

@end
