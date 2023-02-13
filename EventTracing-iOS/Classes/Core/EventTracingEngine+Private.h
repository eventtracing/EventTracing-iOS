//
//  EventTracingEngine+Private.h
//  BlocksKit
//
//  Created by dl on 2021/2/4.
//


#import "EventTracingEngine.h"
#import "EventTracingContext+Private.h"
#import "EventTracingDefines.h"
#import "EventTracingEngine+Action.h"
#import "EventTracingEngine+TraverseAction.h"
#import "EventTracingAppLifecycleProcotol.h"

NS_ASSUME_NONNULL_BEGIN

@interface EventTracingEngine () <EventTracingTraversalRunnerDelegate>

@property(nonatomic, strong, readonly) EventTracingContext *ctx;

@property(nonatomic, strong) NSMutableArray<EventTracingTraverseAction *> *stockedTraverseActions;
// 列表滚动
@property(nonatomic, strong) NSHashTable<UIScrollView *> *stockedTraverseScrollViews;

- (NSUInteger)pgstepIncreased;
- (NSUInteger)actseqIncreased;
- (void)refreshAppInActiveState;

@end

@interface EventTracingEngine (InnerLifecycle) <EventTracingAppLifecycleProcotol>
@end

@interface EventTracingEngine (InnerTraverse)

- (void)traverseImmediatelyIfNeeded;

@end

NS_ASSUME_NONNULL_END
