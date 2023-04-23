//
//  EventTracingSentinel.m
//  BlocksKit
//
//  Created by dl on 2021/3/25.
//

#import "EventTracingSentinel.h"
#import <stdatomic.h>

@implementation EventTracingSentinel {
    atomic_int _value;
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
    return atomic_load_explicit(&_value, memory_order_acquire);
}
- (int32_t)increase {
    return atomic_fetch_add_explicit(&_value, 1u, memory_order_acq_rel);
}
@end
