//
//  EventTracingContext+Private.h
//  EventTracing
//
//  Created by dl on 2021/2/25.
//

#import "EventTracingContext.h"
#import "EventTracingTraversalRunner.h"
#import "EventTracingVTree.h"
#import "EventTracingAppLifecycleProcotol.h"
#import "EventTracingEngine+Action.h"
#import "EventTracingSentinel.h"

#import "EventTracingTraverser.h"
#import "EventTracingTraversalRunner.h"
#import "EventTracingEventEmitter.h"
#import "EventTracingEventOutput.h"
#import "EventTracingParamGuardExector.h"
#import "EventTracingReferFuncs.h"

NS_ASSUME_NONNULL_BEGIN

@class EventTracingEngine;
@interface EventTracingContext : NSObject<EventTracingContextBuilder, EventTracingContext, EventTracingAppLifecycleProcotol> {
    BOOL _started;
    EventTracingSentinel *_pgstepSentinel;
    EventTracingSentinel *_actseqSentinel;
    
    NSTimeInterval _appStartedTime;
    NSTimeInterval _appLastAtForegroundTime;
    NSTimeInterval _appLastEnterBackgroundTime;
    
    __weak id<EventTracingExtraConfigurationProvider> _extraConfigurationProvider;
    NSHashTable<id<EventTracingReferObserver>> *_innerReferObservers;
}

@property(nonatomic, weak) EventTracingEngine *engine;

@property(nonatomic, copy) dispatch_semaphore_t lock;

@property(nonatomic, assign, getter=isFirstViewControllerAppeared) BOOL firstViewControllerAppeared;
@property(nonatomic, assign, readonly) NSInteger appEnterBackgroundSeq;

@property(nonatomic, strong) EventTracingTraverser *traverser;
@property(nonatomic, strong) EventTracingTraversalRunner *traversalRunner;
@property(nonatomic, strong) EventTracingEventEmitter *eventEmitter;
@property(nonatomic, strong) EventTracingEventOutput *eventOutput;
@property(nonatomic, strong, readonly) EventTracingParamGuardExector *paramGuardExector;

@property(nonatomic, strong) NSArray<NSString *> *needIncreaseActseqLogEvents;
@property(nonatomic, strong) NSMutableArray<EventTracingEventAction *> *stockedEventActions;
@property(nonatomic, strong) NSArray<NSString *> *needStartHsreferOids;

@property(nonatomic, copy) NSString *multiReferAppliedEventList;
@property(nonatomic, assign) NSInteger multiReferMaxItemCount;

- (void)refreshAppInActiveState;
- (void)markRunState:(BOOL)started;

@end

@interface EventTracingContext (Refer)

// pgstep
- (NSUInteger)pgstepIncreased;
- (NSUInteger)actseqIncreased;

@end

NS_ASSUME_NONNULL_END
