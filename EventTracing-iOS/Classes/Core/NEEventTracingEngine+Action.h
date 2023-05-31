//
//  NEEventTracingEngine+Action.h
//  BlocksKit
//
//  Created by dl on 2021/3/23.
//

#import "NEEventTracingEngine.h"
#import "NEEventTracingEventEmitter.h"

NS_ASSUME_NONNULL_BEGIN

@interface NEEventTracingEngine (ActionPrivate) <NEEventTracingEventEmitterDelegate>

- (void)flushStockedActionsIfNeeded:(NEEventTracingVTree *)VTree;

- (void)AOP_preLogWithEvent:(NSString *)event view:(UIView *)view;
- (void)AOP_preLogWithEvent:(NSString *)event
                       view:(UIView *)view
                eventAction:(void(^ NS_NOESCAPE _Nullable)(NEEventTracingEventActionConfig *config))block;

- (void)AOP_logWithEvent:(NSString *)event
                    view:(UIView *)view
                  params:(NSDictionary<NSString *, NSString *> * _Nullable)params;

- (void)AOP_logWithEvent:(NSString *)event
                    view:(UIView *)view
                  params:(NSDictionary<NSString *, NSString *> * _Nullable)params
             eventAction:(void(^ NS_NOESCAPE _Nullable)(NEEventTracingEventActionConfig *config))block;

@end

NS_ASSUME_NONNULL_END
