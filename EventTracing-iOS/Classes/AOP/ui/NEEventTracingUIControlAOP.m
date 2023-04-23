//
//  EventTracingUIControlAOP.m
//  BlocksKit
//
//  Created by dl on 2021/2/24.
//

#import "EventTracingUIControlAOP.h"
#import "EventTracingDelegateChain.h"
#import "EventTracingEngine+Private.h"
#import "EventTracingClickMonitor.h"

#import <BlocksKit/BlocksKit.h>
#import <JRSwizzle/JRSwizzle.h>
#import <objc/runtime.h>

// 保证:
//   1. pre 执行在所有的 target-action 之前
//   2. after 执行在所有的 target-action 之后
@interface UIControl (EventTracingAOP)
@property(nonatomic, copy, readonly) NSMutableArray *et_lastClickActions;

- (void)et_Control_sendAction:(SEL)action to:(id)target forEvent:(UIEvent *)event;
@end
@implementation UIControl (EventTracingAOP)
- (void)et_Control_sendAction:(SEL)action to:(id)target forEvent:(UIEvent *)event {
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
        [self et_Control_sendAction:action to:target forEvent:event];
        return;
    }
    
    void(^eventActionBlock)(EventTracingEventActionConfig * _Nonnull) = ^(EventTracingEventActionConfig * _Nonnull config) {
        config.useForRefer = YES;
    };
    
    // pre
    if ([self.et_lastClickActions count] == 0) {
        // observers => pre
        [[[EventTracingClickMonitor sharedInstance] observersForView:self] enumerateObjectsUsingBlock:^(id<EventTracingClickObserver>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj respondsToSelector:@selector(clickMonitor:willTouchUpInsideControl:)]) {
                [(id<EventTracingClickControlTouchUpInsideObserver>)obj clickMonitor:[EventTracingClickMonitor sharedInstance] willTouchUpInsideControl:self];
            }
        }];
        
        [[EventTracingEngine sharedInstance] AOP_preLogWithEvent:ET_EVENT_ID_E_CLCK view:self eventAction:eventActionBlock];
    }
    [self.et_lastClickActions addObject:[NSString stringWithFormat:@"%@-%@", [target class], NSStringFromSelector(action)]];
    
    // original
    [self et_Control_sendAction:action to:target forEvent:event];
    
    // after
    if (self.et_lastClickActions.count == actions.count) {
        [[EventTracingEngine sharedInstance] AOP_logWithEvent:ET_EVENT_ID_E_CLCK view:self params:nil eventAction:eventActionBlock];
        [self.et_lastClickActions removeAllObjects];
        
        // observers => after
        [[[EventTracingClickMonitor sharedInstance] observersForView:self] enumerateObjectsUsingBlock:^(id<EventTracingClickObserver>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj respondsToSelector:@selector(clickMonitor:didTouchUpInsideControl:)]) {
                [(id<EventTracingClickControlTouchUpInsideObserver>)obj clickMonitor:[EventTracingClickMonitor sharedInstance] didTouchUpInsideControl:self];
            }
        }];
    }
}

- (NSMutableArray *)et_lastClickActions {
    NSMutableArray * actions = objc_getAssociatedObject(self, _cmd);
    if (!actions) {
        actions = [@[] mutableCopy];
        objc_setAssociatedObject(self, _cmd, actions, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return actions;
}

@end

@implementation EventTracingUIControlAOP

EventTracingAOPInstanceImp

- (void)asyncInject {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [UIControl jr_swizzleMethod:@selector(sendAction:to:forEvent:) withMethod:@selector(et_Control_sendAction:to:forEvent:) error:nil];
    });
}

@end
