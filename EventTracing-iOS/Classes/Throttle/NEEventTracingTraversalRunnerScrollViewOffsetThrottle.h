//
//  NEEventTracingTraversalRunnerScrollViewOffsetThrottle.h
//  NEEventTracing
//
//  Created by dl on 2021/4/2.
//

#import <Foundation/Foundation.h>
#import "NEEventTracingTraversalRunnerThrottle.h"

NS_ASSUME_NONNULL_BEGIN

/// MARK: 被添加后，仅仅对 UIScrollView 的滚动场景做限流
@interface NEEventTracingTraversalRunnerScrollViewOffsetThrottle : NSObject <NEEventTracingTraversalRunnerThrottle>

// 最小要 X/Y 轴移动超过阈值，才放行
// 默认是 {5.f, 5.f}
@property(nonatomic, assign) CGPoint tolerentOffset;

@end

NS_ASSUME_NONNULL_END
