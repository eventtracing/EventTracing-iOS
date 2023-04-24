//
//  NEEventTracingContext+Private.h
//  NEEventTracing
//
//  Created by dl on 2021/2/25.
//

#import "NEEventTracingContext.h"
#import "NEEventTracingTraversalRunner.h"
#import "NEEventTracingVTree.h"
#import "NEEventTracingAppLifecycleProcotol.h"
#import "NEEventTracingEngine+Action.h"
#import "NEEventTracingSentinel.h"

#import "NEEventTracingTraverser.h"
#import "NEEventTracingTraversalRunner.h"
#import "NEEventTracingEventEmitter.h"
#import "NEEventTracingEventOutput.h"
#import "NEEventTracingParamGuardExector.h"
#import "NEEventTracingReferFuncs.h"

NS_ASSUME_NONNULL_BEGIN

@class NEEventTracingEngine;
@interface NEEventTracingContext : NSObject<NEEventTracingContextBuilder, NEEventTracingContext, NEEventTracingAppLifecycleProcotol> {
    BOOL _started;
    NEEventTracingSentinel *_pgstepSentinel;
    NEEventTracingSentinel *_actseqSentinel;
    
    NSTimeInterval _appStartedTime;
    NSTimeInterval _appLastAtForegroundTime;
    NSTimeInterval _appLastEnterBackgroundTime;
    
    __weak id<NEEventTracingExtraConfigurationProvider> _extraConfigurationProvider;
    NSHashTable<id<NEEventTracingReferObserver>> *_innerReferObservers;
}

@property(nonatomic, weak) NEEventTracingEngine *engine;

@property(nonatomic, copy) dispatch_semaphore_t lock;

@property(nonatomic, assign, getter=isFirstViewControllerAppeared) BOOL firstViewControllerAppeared;
@property(nonatomic, assign, readonly) NSInteger appEnterBackgroundSeq;

@property(nonatomic, strong) NEEventTracingTraverser *traverser;
@property(nonatomic, strong) NEEventTracingTraversalRunner *traversalRunner;
@property(nonatomic, strong) NEEventTracingEventEmitter *eventEmitter;
@property(nonatomic, strong) NEEventTracingEventOutput *eventOutput;
@property(nonatomic, strong, readonly) NEEventTracingParamGuardExector *paramGuardExector;

@property(nonatomic, strong) NSArray<NSString *> *needIncreaseActseqLogEvents;
@property(nonatomic, strong) NSMutableArray<NEEventTracingEventAction *> *stockedEventActions;
@property(nonatomic, strong) NSArray<NSString *> *needStartHsreferOids;

- (void)refreshAppInActiveState;
- (void)markRunState:(BOOL)started;

@end

@interface NEEventTracingContext (Refer)

// pgstep
- (NSUInteger)pgstepIncreased;
- (NSUInteger)actseqIncreased;

@end

NS_ASSUME_NONNULL_END
