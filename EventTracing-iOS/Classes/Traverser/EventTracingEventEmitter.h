//
//  EventTracingEventEmitter.h
//  EventTracing
//
//  Created by dl on 2021/3/16.
//

#import <Foundation/Foundation.h>
#import "EventTracingContext.h"
#import "EventTracingVTree.h"
#import "EventTracingEventReferCollector.h"

NS_ASSUME_NONNULL_BEGIN

@class EventTracingEventEmitter;
@protocol EventTracingEventEmitterDelegate <NSObject>

- (void)eventEmitter:(EventTracingEventEmitter *)eventEmitter
           emitEvent:(NSString *)event
       contextParams:(NSDictionary * _Nullable)contextParams
     logActionParams:(NSDictionary * _Nullable)logActionParams
                node:(EventTracingVTreeNode * _Nullable)node
             inVTree:(EventTracingVTree * _Nullable)VTree;

@end

@interface EventTracingEventEmitter : NSObject <EventTracingContextVTreeObserverBuilder>

@property(nonatomic, weak, nullable) id<EventTracingEventEmitterDelegate> delegate;
@property(nonatomic, strong, readonly, nullable) EventTracingVTree *lastVTree;
@property(nonatomic, strong, readonly, nullable) NSArray<id<EventTracingVTreeObserver>> *allVTreeObservers;
@property(nonatomic, weak, nullable) id<EventTracingContextVTreePerformanceObserver> VTreePerformanceObserver;
@property(nonatomic, strong) EventTracingEventReferCollector *referCollector;

- (void)consumeVTree:(EventTracingVTree *)VTree;
- (void)flush;

// 下面俩方法，仅仅在主线程中调用
- (void)consumeEventAction:(EventTracingEventAction *)action;

/// MARK: 目前仅仅针对 UIAlertController 场景使用
- (void)consumeEventAction:(EventTracingEventAction *)action forceInCurrentVTree:(BOOL)forceInCurrentVTree;

@end

NS_ASSUME_NONNULL_END
