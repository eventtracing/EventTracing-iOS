//
//  EventTracingContext.m
//  BlocksKit
//
//  Created by dl on 2021/2/4.
//

#import "EventTracingContext+Private.h"
#import "EventTracingEventOutput+Private.h"
#import "EventTracingVTreeNode+Private.h"
#import "EventTracingInternalLog.h"
#import "EventTracingReferNodeSCMDefaultFormatter.h"
#import "EventTracingEventReferQueue.h"
#import <BlocksKit/BlocksKit.h>

@implementation EventTracingContext
@synthesize extraConfigurationProvider = _extraConfigurationProvider;
@synthesize internalLogOutputInterface = _internalLogOutputInterface;
@synthesize exceptionInterface = _exceptionInterface;
@synthesize referNodeSCMFormatter = _referNodeSCMFormatter;
@synthesize paramGuardExector = _paramGuardExector;
@synthesize paramGuardEnable = _paramGuardEnable;
@synthesize elementAutoImpressendEnable = _elementAutoImpressendEnable;
@synthesize noneventOutputWithoutPageNodeEnable = _noneventOutputWithoutPageNodeEnable;
@synthesize viewControllerDidNotLoadViewExceptionTip = _viewControllerDidNotLoadViewExceptionTip;
@synthesize started = _started;
@synthesize throttleTolerentDuration = _throttleTolerentDuration;
@synthesize throttleTolerentOffset = _throttleTolerentOffset;
@synthesize sessid = _sessid;
@synthesize sidrefer = _sidrefer;
@synthesize referFormatHasDKeyComponent = _referFormatHasDKeyComponent;
@synthesize appInActive = _appInActive;
@synthesize appStartedTime = _appStartedTime;
@synthesize appLastAtForegroundTime = _appLastAtForegroundTime;
@synthesize appLastEnterBackgroundTime = _appLastEnterBackgroundTime;

#define LOCK        dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
#define UNLOCK      dispatch_semaphore_signal(_lock);

NSString * const kEventTracingSessIdKey = @"kEventTracingSessIdKey";

- (instancetype)init {
    self = [super init];
    if (self) {
        _pgstepSentinel = [EventTracingSentinel sentinel];
        _actseqSentinel = [EventTracingSentinel sentinel];
        _lock = dispatch_semaphore_create(1);
        
        _traverser = [[EventTracingTraverser alloc] init];
        _traversalRunner = [[EventTracingTraversalRunner alloc] init];
        _eventEmitter = [[EventTracingEventEmitter alloc] init];
        
        _eventOutput = [[EventTracingEventOutput alloc] init];
        
        // MARK: # _sessid: [timestap]#[rand]
        // timestap: ms
        // rand: 三位随机数
        // 不包含 []
        unsigned long long time = [NSDate date].timeIntervalSince1970 * 1000;
        uint32_t randomNumber = arc4random() % 900 + 100;
        NSDictionary *appInfo = [[NSBundle mainBundle] infoDictionary];
        NSString *appver = [appInfo objectForKey:@"CFBundleShortVersionString"] ?: @"";
        NSString *buildver = [appInfo objectForKey:(NSString *)kCFBundleVersionKey];
        _sessid = [NSString stringWithFormat:@"%llu#%u#%@#%@", time, randomNumber, appver, buildver];
        _sidrefer = [[NSUserDefaults standardUserDefaults] objectForKey:kEventTracingSessIdKey];
        [[NSUserDefaults standardUserDefaults] setObject:_sessid forKey:kEventTracingSessIdKey];
        
        _referNodeSCMFormatter = [EventTracingReferNodeSCMDefaultFormatter new];
        
        _stockedEventActions = [@[] mutableCopy];
        
        _throttleTolerentDuration = 0.1f;
        _throttleTolerentOffset = CGPointMake(5.f, 5.f);
        
        _elementAutoImpressendEnable = YES;
        _noneventOutputWithoutPageNodeEnable = YES;
        _viewControllerDidNotLoadViewExceptionTip = ETViewControllerDidNotLoadViewExceptionTipNone;
        
        _innerReferObservers = [NSHashTable hashTableWithOptions:NSPointerFunctionsWeakMemory];
    }
    return self;
}

- (void)configScrollThrottleTolerentDuration:(NSTimeInterval)tolerentDuration
                              tolerentOffset:(CGPoint)tolerentOffset {
    _throttleTolerentDuration = tolerentDuration;
    _throttleTolerentOffset = tolerentOffset;
}

- (void)markRunState:(BOOL)started {
    LOCK {
        _started = started;
    } UNLOCK
}

// refer
- (NSUInteger)pgstepIncreased {
    [_pgstepSentinel increase];
    
    return _pgstepSentinel.value;
}

- (NSUInteger)actseqIncreased {
    [_actseqSentinel increase];
    
    return _actseqSentinel.value;
}

#pragma mark - EventTracingContextVTreeObserverBuilder
- (void)addVTreeObserver:(id<EventTracingVTreeObserver>)observer {
    [self.eventEmitter addVTreeObserver:observer];
}

- (void)removeVTreeObserver:(id<EventTracingVTreeObserver>)observer {
    [self.eventEmitter removeVTreeObserver:observer];
}

- (void)removeAllVTreeObservers {
    [self.eventEmitter removeAllVTreeObservers];
}

- (void)setVTreePerformanceObserver:(id<EventTracingContextVTreePerformanceObserver>)VTreePerformanceObserver {
    self.eventEmitter.VTreePerformanceObserver = VTreePerformanceObserver;
}

#pragma - EventTracingContextReferObserverBuilder
- (void)addReferObserver:(id<EventTracingReferObserver>)referObserver {
    [_innerReferObservers addObject:referObserver];
}

#pragma mark - EventTracingContextOutputFormatterBuilder
- (void)registeFormatter:(id<EventTracingOutputFormatter>)formatter {
    [self.eventOutput registeFormatter:formatter];
}

- (void)configReferFormatHasDKeyComponent:(BOOL)hasDKeyComponent {
    _referFormatHasDKeyComponent = hasDKeyComponent;
}

- (void)setupReferNodeSCMFormatter:(id<EventTracingReferNodeSCMFormatter>)referNodeSCMFormatter {
    _referNodeSCMFormatter = referNodeSCMFormatter;
}

- (void)registePublicDynamicParamsProvider:(id<EventTracingOutputPublicDynamicParamsProvider>)publicDynamicParamsProvider {
    [self.eventOutput registePublicDynamicParamsProvider:publicDynamicParamsProvider];
}

- (void)configStaticPublicParams:(NSDictionary<NSString *, NSString *> *)params {
    [self.eventOutput configStaticPublicParams:params];
}

- (void)removeStaticPublicParamForKey:(NSString *)key {
    [self.eventOutput removeStaticPublicParamForKey:key];
}

- (void)addOutputChannel:(id<EventTracingEventOutputChannel>)outputChannel {
    [self.eventOutput addOutputChannel:outputChannel];
}

- (void)removeOutputChannel:(id<EventTracingEventOutputChannel>)outputChannel {
    [self.eventOutput removeOutputChannel:outputChannel];
}

- (void)removeAllOutputChannels {
    [self.eventOutput removeAllOutputChannels];
}

- (void)addParamsFilter:(id<EventTracingOutputParamsFilter>)paramsFilter {
    [self.eventOutput addParamsFilter:paramsFilter];
}

- (void)removeParamsFilter:(id<EventTracingOutputParamsFilter>)paramsFilter {
    [self.eventOutput removeParamsFilter:paramsFilter];
}

- (void)removeAllParamsFilters {
    [self.eventOutput removeAllParamsFilters];
}

#pragma mark - EventTracingAppLifecycleProcotol
- (void)appViewController:(UIViewController *)controller changedToAppear:(BOOL)appear {
    if (appear && !_firstViewControllerAppeared) {
        _firstViewControllerAppeared = YES;
    }
}

- (void)appDidBecomeActive {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _appStartedTime = [NSDate date].timeIntervalSince1970;
    });
    
    if (self.isAppInActive) {
        return;
    }
    
    _appLastAtForegroundTime = [NSDate date].timeIntervalSince1970;
    [self doUpdateAppInActiveState:YES];
    [_eventEmitter.referCollector appWillEnterForeground];
}

- (void)appWillEnterForeground {
    if (self.isAppInActive) {
        return;
    }
    
    _appLastAtForegroundTime = [NSDate date].timeIntervalSince1970;
    [self doUpdateAppInActiveState:YES];
    [_eventEmitter.referCollector appWillEnterForeground];
}

- (void)appDidEnterBackground {
    _appLastEnterBackgroundTime = [NSDate date].timeIntervalSince1970;
    
    if (self.isAppInActive) {
        _appEnterBackgroundSeq ++;
    }
    [self doUpdateAppInActiveState:NO];
}

- (void)appDidTerminate {}

#pragma mark - private methods
- (void)refreshAppInActiveState {
    [self doUpdateAppInActiveState:[UIApplication sharedApplication].applicationState == UIApplicationStateActive];
}

- (void)doUpdateAppInActiveState:(BOOL)inActive {
    LOCK {
        _appInActive = inActive;
    } UNLOCK
}

#pragma mark - getters
- (NSArray<id<EventTracingVTreeObserver>> *)allVTreeObservers {
    return self.eventEmitter.allVTreeObservers;
}

- (NSArray<id<EventTracingReferObserver>> *)allReferObservers {
    return _innerReferObservers.allObjects;
}

- (id<EventTracingContextVTreePerformanceObserver>)VTreePerformanceObserver {
    return self.eventEmitter.VTreePerformanceObserver;
}

- (id<EventTracingParamGuardConfiguration>)paramGuardConfiguration {
    return self.paramGuardExector;
}

- (EventTracingParamGuardExector *)paramGuardExector {
    if (!_paramGuardExector) {
        _paramGuardExector = [EventTracingParamGuardExector new];
    }
    return _paramGuardExector;
}

- (BOOL)isAppInActive {
    BOOL appInActive = NO;
    LOCK {
        appInActive = _appInActive;
    } UNLOCK
    return appInActive;
}

- (BOOL)started {
    BOOL started = NO;
    LOCK {
        started = _started;
    } UNLOCK
    return started;
}

- (NSUInteger)pgstep {
    return _pgstepSentinel.value;
}

- (NSUInteger)actseq {
    return _actseqSentinel.value;
}

- (NSString *)hsrefer {
    return [EventTracingEventReferQueue queue].hsrefer;
}

- (EventTracingVTree *)currentVTree {
    return _eventEmitter.lastVTree;
}

@end
