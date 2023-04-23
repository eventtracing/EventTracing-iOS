//
//  EventTracingTraversalRunnerScrollViewOffsetThrottle.m
//  EventTracing
//
//  Created by dl on 2021/4/2.
//

#import "EventTracingTraversalRunnerScrollViewOffsetThrottle.h"

@interface EventTracingTraversalRunnerScrollViewOffsetThrottle () {
    BOOL _throttled;
    __weak id<EventTracingTraversalRunnerThrottleCallback> _callback;
    CGPoint _preContentOffset;
}

@end

@implementation EventTracingTraversalRunnerScrollViewOffsetThrottle
@synthesize throttled = _throttled;
@synthesize paused = _paused;
@synthesize callback = _callback;

- (instancetype)init {
    self = [super init];
    if (self) {
        _tolerentOffset = CGPointMake(5.f, 5.f);
        
        [self reset];
    }
    return self;
}

- (void)reset {
    _throttled = NO;
    _preContentOffset = CGPointZero;
    _paused = NO;
}

- (void)pause {
    _paused = YES;
}

- (void)pushValue:(id _Nullable)value {
    if (_paused) {
        return;
    }
    
    if (![value isKindOfClass:NSValue.class]
        || CGPointEqualToPoint([value CGPointValue], CGPointZero)) {
        
        if (_throttled) {
            [self reset];
        }
        
        return;
    }
    
    CGPoint offset = [value CGPointValue];
    CGPoint preOffset = _preContentOffset;
    
    if (CGPointEqualToPoint(CGPointZero, preOffset)) {
        _preContentOffset = offset;
        
        return;
    }
    
    if (fabs(preOffset.x - offset.x) > fabs(_tolerentOffset.x)
        || fabs(preOffset.y - offset.y) > fabs(_tolerentOffset.y)) {
        
        _preContentOffset = offset;
        [self _finishThrottled];
    }
}

- (void)_finishThrottled {
    _throttled = NO;
    
    if ([self.callback respondsToSelector:@selector(throttle:throttleDidFinished:)]) {
        [self.callback throttle:self throttleDidFinished:_throttled];
    }
}

- (NSString *)name {
    return @"Throttle.ContentOffset";
}

@end
