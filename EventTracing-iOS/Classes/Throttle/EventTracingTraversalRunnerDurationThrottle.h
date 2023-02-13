//
//  EventTracingTraversalRunnerDurationThrottle.h
//  EventTracing
//
//  Created by dl on 2021/4/2.
//

#import <Foundation/Foundation.h>
#import "EventTracingTraversalRunnerThrottle.h"

NS_ASSUME_NONNULL_BEGIN

@interface EventTracingTraversalRunnerDurationThrottle : NSObject <EventTracingTraversalRunnerThrottle>

// 最小需要多长时间才放行
// 默认 0.1s
@property(nonatomic, assign) NSTimeInterval tolerentDuration;

@end

NS_ASSUME_NONNULL_END
