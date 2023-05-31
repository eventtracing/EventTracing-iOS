//
//  NEEventTracingTraversalRunnerDurationThrottle.m
//  NEEventTracing
//
//  Created by dl on 2021/4/2.
//

#import "NEEventTracingTraversalRunnerDurationThrottle.h"

@interface NEEventTracingTraversalRunnerDurationThrottle () {
    BOOL _throttled;
    __weak id<NEEventTracingTraversalRunnerThrottleCallback> _callback;
    
    NSTimeInterval _preTime;
}
@end

@implementation NEEventTracingTraversalRunnerDurationThrottle
@synthesize throttled = _throttled;
@synthesize paused = _paused;
@synthesize callback = _callback;

- (instancetype)init {
    self = [super init];
    if (self) {
        _tolerentDuration = .1f;
        
        [self reset];
    }
    return self;
}

- (void)reset {
    _preTime = [NSDate date].timeIntervalSince1970;
    _throttled = NO;
    _paused = NO;
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (void)pause {
    _paused = YES;
}

- (void)pushValue:(id _Nullable)value {
    if (_paused) {
        return;
    }
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    NSTimeInterval now = [NSDate date].timeIntervalSince1970;
    
    if (_preTime >= now) {
        _preTime = now;
    }
    
    if (now - self.tolerentDuration >= _preTime) {
        [self _finishThrottled];
    } else {
        NSTimeInterval diff = self.tolerentDuration - (now - _preTime);
        _throttled = YES;
        
        [self performSelector:@selector(_finishThrottled) withObject:nil afterDelay:diff];
    }
}

- (void)_finishThrottled {
    _preTime = [NSDate date].timeIntervalSince1970;
    _throttled = NO;
    
    if ([self.callback respondsToSelector:@selector(throttle:throttleDidFinished:)]) {
        [self.callback throttle:self throttleDidFinished:_throttled];
    }
}

- (NSString *)name {
    return @"Throttle.Duration";
}

@end
