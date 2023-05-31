//
//  NEEventTracingEventEmitter.h
//  NEEventTracing
//
//  Created by dl on 2021/3/16.
//

#import <Foundation/Foundation.h>
#import "NEEventTracingContext.h"
#import "NEEventTracingVTree.h"
#import "NEEventTracingEventReferCollector.h"

NS_ASSUME_NONNULL_BEGIN

@class NEEventTracingEventEmitter;
@protocol NEEventTracingEventEmitterDelegate <NSObject>

- (void)eventEmitter:(NEEventTracingEventEmitter *)eventEmitter
           emitEvent:(NSString *)event
       contextParams:(NSDictionary * _Nullable)contextParams
     logActionParams:(NSDictionary * _Nullable)logActionParams
                node:(NEEventTracingVTreeNode * _Nullable)node
             inVTree:(NEEventTracingVTree * _Nullable)VTree;

@end

@interface NEEventTracingEventEmitter : NSObject <NEEventTracingContextVTreeObserverBuilder>

@property(nonatomic, weak, nullable) id<NEEventTracingEventEmitterDelegate> delegate;
@property(nonatomic, strong, readonly, nullable) NEEventTracingVTree *lastVTree;
@property(nonatomic, strong, readonly, nullable) NSArray<id<NEEventTracingVTreeObserver>> *allVTreeObservers;
@property(nonatomic, weak, nullable) id<NEEventTracingContextVTreePerformanceObserver> VTreePerformanceObserver;
@property(nonatomic, strong) NEEventTracingEventReferCollector *referCollector;

- (void)consumeVTree:(NEEventTracingVTree *)VTree;
- (void)flush;

// 下面俩方法，仅仅在主线程中调用
- (void)consumeEventAction:(NEEventTracingEventAction *)action;

/// MARK: 目前仅仅针对 UIAlertController 场景使用
- (void)consumeEventAction:(NEEventTracingEventAction *)action forceInCurrentVTree:(BOOL)forceInCurrentVTree;

@end

NS_ASSUME_NONNULL_END
