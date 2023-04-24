//
//  NEEventTracingContext.m
//  BlocksKit
//
//  Created by dl on 2021/2/4.
//

#import "NEEventTracingContext+Private.h"
#import "NEEventTracingEventOutput+Private.h"
#import "NEEventTracingVTreeNode+Private.h"
#import "NEEventTracingInternalLog.h"
#import "NEEventTracingReferNodeSCMDefaultFormatter.h"
#import "NEEventTracingEventReferQueue.h"
#import <BlocksKit/BlocksKit.h>

@implementation NEEventTracingContext
@synthesize extraConfigurationProvider = _extraConfigurationProvider;
@synthesize internalLogOutputInterface = _internalLogOutputInterface;
@synthesize exceptionInterface = _exceptionInterface;
@synthesize referNodeSCMFormatter = _referNodeSCMFormatter;
@synthesize paramGuardExector = _paramGuardExector;
@synthesize paramGuardEnable = _paramGuardEnable;
@synthesize nodeInfoValidationEnable = _nodeInfoValidationEnable;
@synthesize autoMountParentWaringEnable = _autoMountParentWaringEnable;
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
@synthesize useCustomAppLifeCycle = _useCustomAppLifeCycle;
@synthesize appBuildVersion = _appBuildVersion;

#define LOCK        dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
#define UNLOCK      dispatch_semaphore_signal(_lock);

NSString * const kEventTracingSessIdKey = @"kEventTracingSessIdKey";

- (instancetype)init {
    self = [super init];
    if (self) {
        _pgstepSentinel = [NEEventTracingSentinel sentinel];
        _actseqSentinel = [NEEventTracingSentinel sentinel];
        _lock = dispatch_semaphore_create(1);
        
        _traverser = [[NEEventTracingTraverser alloc] init];
        _traversalRunner = [[NEEventTracingTraversalRunner alloc] init];
        _eventEmitter = [[NEEventTracingEventEmitter alloc] init];
        
        _eventOutput = [[NEEventTracingEventOutput alloc] init];
        
        // MARK: # _sessid: [timestap]#[rand]
        // timestap: ms
        // rand: 三位随机数
        // 不包含 []
        unsigned long long time = [NSDate date].timeIntervalSince1970 * 1000;
        uint32_t randomNumber = arc4random() % 900 + 100;
        NSDictionary *appInfo = [[NSBundle mainBundle] infoDictionary];
        NSString *appver = [appInfo objectForKey:@"CFBundleShortVersionString"] ?: @"";
        NSString *buildver;
        if (self.appBuildVersion.length > 0) {
            buildver = self.appBuildVersion;
        } else {
            buildver = [appInfo objectForKey:(NSString *)kCFBundleVersionKey];
        }
        _sessid = [NSString stringWithFormat:@"%llu#%u#%@#%@", time, randomNumber, appver, buildver];
        _sidrefer = [[NSUserDefaults standardUserDefaults] objectForKey:kEventTracingSessIdKey];
        [[NSUserDefaults standardUserDefaults] setObject:_sessid forKey:kEventTracingSessIdKey];
        
        _referNodeSCMFormatter = [NEEventTracingReferNodeSCMDefaultFormatter new];
        
        _stockedEventActions = [@[] mutableCopy];
        
        _throttleTolerentDuration = 0.1f;
        _throttleTolerentOffset = CGPointMake(5.f, 5.f);
        
        _elementAutoImpressendEnable = YES;
        _noneventOutputWithoutPageNodeEnable = YES;
        _viewControllerDidNotLoadViewExceptionTip = NEETViewControllerDidNotLoadViewExceptionTipNone;
        
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

#pragma mark - NEEventTracingContextVTreeObserverBuilder
- (void)addVTreeObserver:(id<NEEventTracingVTreeObserver>)observer {
    [self.eventEmitter addVTreeObserver:observer];
}

- (void)removeVTreeObserver:(id<NEEventTracingVTreeObserver>)observer {
    [self.eventEmitter removeVTreeObserver:observer];
}

- (void)removeAllVTreeObservers {
    [self.eventEmitter removeAllVTreeObservers];
}

- (void)setVTreePerformanceObserver:(id<NEEventTracingContextVTreePerformanceObserver>)VTreePerformanceObserver {
    self.eventEmitter.VTreePerformanceObserver = VTreePerformanceObserver;
}

#pragma - NEEventTracingContextReferObserverBuilder
- (void)addReferObserver:(id<NEEventTracingReferObserver>)referObserver {
    [_innerReferObservers addObject:referObserver];
}

#pragma mark - NEEventTracingContextOutputFormatterBuilder
- (void)registeFormatter:(id<NEEventTracingOutputFormatter>)formatter {
    [self.eventOutput registeFormatter:formatter];
}

- (void)configReferFormatHasDKeyComponent:(BOOL)hasDKeyComponent {
    _referFormatHasDKeyComponent = hasDKeyComponent;
}

- (void)setupReferNodeSCMFormatter:(id<NEEventTracingReferNodeSCMFormatter>)referNodeSCMFormatter {
    _referNodeSCMFormatter = referNodeSCMFormatter;
}

- (void)registePublicDynamicParamsProvider:(id<NEEventTracingOutputPublicDynamicParamsProvider>)publicDynamicParamsProvider {
    [self.eventOutput registePublicDynamicParamsProvider:publicDynamicParamsProvider];
}

- (void)configStaticPublicParams:(NSDictionary<NSString *, NSString *> *)params {
    [self.eventOutput configStaticPublicParams:params];
}

- (void)removeStaticPublicParamForKey:(NSString *)key {
    [self.eventOutput removeStaticPublicParamForKey:key];
}

- (void)addOutputChannel:(id<NEEventTracingEventOutputChannel>)outputChannel {
    [self.eventOutput addOutputChannel:outputChannel];
}

- (void)removeOutputChannel:(id<NEEventTracingEventOutputChannel>)outputChannel {
    [self.eventOutput removeOutputChannel:outputChannel];
}

- (void)removeAllOutputChannels {
    [self.eventOutput removeAllOutputChannels];
}

- (void)addParamsFilter:(id<NEEventTracingOutputParamsFilter>)paramsFilter {
    [self.eventOutput addParamsFilter:paramsFilter];
}

- (void)removeParamsFilter:(id<NEEventTracingOutputParamsFilter>)paramsFilter {
    [self.eventOutput removeParamsFilter:paramsFilter];
}

- (void)removeAllParamsFilters {
    [self.eventOutput removeAllParamsFilters];
}

#pragma mark - NEEventTracingAppLifecycleProcotol
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
- (NSArray<id<NEEventTracingVTreeObserver>> *)allVTreeObservers {
    return self.eventEmitter.allVTreeObservers;
}

- (NSArray<id<NEEventTracingReferObserver>> *)allReferObservers {
    return _innerReferObservers.allObjects;
}

- (id<NEEventTracingContextVTreePerformanceObserver>)VTreePerformanceObserver {
    return self.eventEmitter.VTreePerformanceObserver;
}

- (id<NEEventTracingParamGuardConfiguration>)paramGuardConfiguration {
    return self.paramGuardExector;
}

- (NEEventTracingParamGuardExector *)paramGuardExector {
    if (!_paramGuardExector) {
        _paramGuardExector = [NEEventTracingParamGuardExector new];
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
    return [NEEventTracingEventReferQueue queue].hsrefer;
}

- (NEEventTracingVTree *)currentVTree {
    return _eventEmitter.lastVTree;
}

#pragma mark - Deprecated
- (void)configDeaultImpressIntervalThreshold:(NSTimeInterval)intervalThreshold {}

- (NSTimeInterval)defaultImpressIntervalThreshold {
    return 0;
}

@end
