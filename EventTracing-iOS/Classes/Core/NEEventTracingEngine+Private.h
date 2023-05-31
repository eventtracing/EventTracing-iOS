//
//  NEEventTracingEngine+Private.h
//  BlocksKit
//
//  Created by dl on 2021/2/4.
//


#import "NEEventTracingEngine.h"
#import "NEEventTracingContext+Private.h"
#import "NEEventTracingDefines.h"
#import "NEEventTracingEngine+Action.h"
#import "NEEventTracingEngine+TraverseAction.h"
#import "NEEventTracingAppLifecycleProcotol.h"

NS_ASSUME_NONNULL_BEGIN

@interface NEEventTracingEngine () <NEEventTracingTraversalRunnerDelegate>

@property(nonatomic, strong, readonly) NEEventTracingContext *ctx;

@property(nonatomic, strong) NEEventTracingStockedTraverseActionRecord *stockedTraverseActionRecord;

// 列表滚动
@property(nonatomic, strong) NSHashTable<UIScrollView *> *stockedTraverseScrollViews;

- (NSUInteger)pgstepIncreased;
- (NSUInteger)actseqIncreased;
- (void)refreshAppInActiveState;

@end

@interface NEEventTracingEngine (InnerLifecycle) <NEEventTracingAppLifecycleProcotol>
@end

@interface NEEventTracingEngine (InnerTraverse)

- (void)traverseImmediatelyIfNeeded;

@end

NS_ASSUME_NONNULL_END
