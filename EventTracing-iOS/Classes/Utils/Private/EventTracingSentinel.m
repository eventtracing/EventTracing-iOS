//
//  EventTracingSentinel.m
//  BlocksKit
//
//  Created by dl on 2021/3/25.
//

#import "EventTracingSentinel.h"
#import <libkern/OSAtomic.h>

@implementation EventTracingSentinel {
    int32_t _value;
}

+ (instancetype)sentinel {
    return [self sentinelWithInitialValue:0];
}

+ (instancetype)sentinelWithInitialValue:(int32_t)initialValue {
    EventTracingSentinel *s = [EventTracingSentinel new];
    s->_value = initialValue;
    return s;
}

- (int32_t)value {
    return _value;
}
- (int32_t)increase {
    return OSAtomicIncrement32(&_value);
}
@end
