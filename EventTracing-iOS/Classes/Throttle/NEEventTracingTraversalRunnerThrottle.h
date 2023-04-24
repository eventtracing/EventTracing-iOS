//
//  NEEventTracingTraversalRunnerThrottle.h
//  NEEventTracing
//
//  Created by dl on 2021/4/2.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol NEEventTracingTraversalRunnerThrottle;
@protocol NEEventTracingTraversalRunnerThrottleCallback <NSObject>
- (void)throttle:(id<NEEventTracingTraversalRunnerThrottle>)throttle throttleDidFinished:(BOOL)throttled;
@end

@protocol NEEventTracingTraversalRunnerThrottle <NSObject>

@property(nonatomic, copy, readonly) NSString *name;
// 标识当前正在处于 被限流状态
@property(nonatomic, assign, readonly, getter=isThrottled) BOOL throttled;
@property(nonatomic, assign, readonly, getter=isPaused) BOOL paused;
@property(nonatomic, weak, nullable) id<NEEventTracingTraversalRunnerThrottleCallback> callback;

- (void)pushValue:(id _Nullable)value;
- (void)reset;
- (void)pause;

@end

NS_ASSUME_NONNULL_END
