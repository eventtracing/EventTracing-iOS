//
//  EventTracingTraversalRunner.m
//  BlocksKit
//
//  Created by dl on 2021/2/4.
//

#import "EventTracingTraversalRunner.h"
#import "EventTracingTraversalRunnerDurationThrottle.h"

@interface EventTracingTraversalRunner () <EventTracingTraversalRunnerThrottleCallback> {
    CFRunLoopObserverRef _runloopObserver;
}
@property(nonatomic, assign, direct) CFTimeInterval currentLoopEntryTime;
@property(nonatomic, strong, direct) EventTracingTraversalRunnerDurationThrottle *throtte;

- (void)_runloopDidEntry __attribute__((objc_direct));
- (void)_needRunTask __attribute__((objc_direct));
@end

__attribute__((objc_direct_members))
@implementation EventTracingTraversalRunner
@synthesize running = _running;
@synthesize paused = _paused;
@synthesize currentRunMode = _currentRunMode;

- (void)dealloc {
    CFRelease(_runloopObserver);
}

- (void) run {
    [self runWithRunloopMode:NSDefaultRunLoopMode];
}

- (void) runWithRunloopMode:(NSRunLoopMode)runloopMode {
    if (_running || _runloopObserver != NULL) {
        return;
    }
    
    _currentRunMode = runloopMode;
    _running = YES;
    _paused = YES;
    
    _throtte = [[EventTracingTraversalRunnerDurationThrottle alloc] init];
    /// 至少间隔 0.1s 才做一次
    _throtte.tolerentDuration = 0.1f;
    _throtte.callback = self;

    CFRunLoopObserverContext context = {0, (__bridge void *) self, NULL, NULL, NULL};
    const CFIndex CFIndexMax = LONG_MAX;
    _runloopObserver = CFRunLoopObserverCreate(kCFAllocatorDefault, kCFRunLoopAllActivities, YES, CFIndexMax, &ETRunloopObserverCallback, &context);
    
    [self resume];
}

- (void) stop {
    _running = NO;
    
    [self pause];
    if (_runloopObserver) {
        CFRelease(_runloopObserver);
        _runloopObserver = NULL;
    }
}

- (void)pause {
    if (!_running || _paused) {
        return;
    }
    
    _paused = YES;
    CFRunLoopRemoveObserver([[NSRunLoop currentRunLoop] getCFRunLoop], _runloopObserver, kCFRunLoopCommonModes);
}

- (void)resume {
    if (!_running || !_paused) {
        return;
    }
    
    _paused = NO;
    CFRunLoopAddObserver([[NSRunLoop currentRunLoop] getCFRunLoop], _runloopObserver, kCFRunLoopCommonModes);
}

#pragma mark - EventTracingTraversalRunnerThrottleCallback
- (void)throttle:(id<EventTracingTraversalRunnerThrottle>)throttle throttleDidFinished:(BOOL)throttled {
    [self _needRunTask];
}

#pragma mark - Private methods
- (void)_runloopDidEntry {
    _currentLoopEntryTime = CACurrentMediaTime() * 1000.f;
}

- (void)_needRunTask {
    CFTimeInterval now = CACurrentMediaTime() * 1000.f;
    
    // 如果本次主线程的runloop已经使用了了超过 16.7/2.f 毫秒，则本次runloop不再遍历，放在下个runloop的beforWaiting中
    // 按照目前手机一秒60帧的场景，一帧需要1/60也就是16.7ms的时间来执行代码，主线程不能被卡住超过16.7ms
    // 特别是针对 iOS 15 之后，iPhone 13 Pro Max 帧率可以设置到 120hz
    static CFTimeInterval frameMaxAvaibleTime = 0.f;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSInteger maximumFramesPerSecond = 60;
        if (@available(iOS 10.3, *)) {
            maximumFramesPerSecond = [UIScreen mainScreen].maximumFramesPerSecond;
        }
        frameMaxAvaibleTime = 1.f / maximumFramesPerSecond * 1000.f / 3.f;
    });
    
    if (now - _currentLoopEntryTime > frameMaxAvaibleTime) {
//        NSLog(@"## RunLoopRunner ##, wont Run becase has exec time(%@) in current runloop, more than (%@)ms", @(now - _currentLoopEntryTime), @(frameMaxAvaibleTime));
        return;
    }
    
    BOOL runModeMatched = [[NSRunLoop mainRunLoop].currentMode isEqualToString:(NSString *) self.currentRunMode];
    
    if ([self.delegate respondsToSelector:@selector(traversalRunner:runWithRunModeMatched:)]) {
        [self.delegate traversalRunner:self runWithRunModeMatched:runModeMatched];
    }
}

#pragma mark - Runloop Observer cb
void ETRunloopObserverCallback(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info) {
    EventTracingTraversalRunner *runner = (__bridge EventTracingTraversalRunner *)info;
    switch (activity) {
        case kCFRunLoopEntry:
            [runner _runloopDidEntry];
            break;
            
        case kCFRunLoopBeforeWaiting:
            [runner.throtte pushValue:nil];
            break;
            
        case kCFRunLoopAfterWaiting:
            [runner _runloopDidEntry];
            break;
            
        default:
            break;
    }
}

@end
