//
//  NEEventTracingSentinel.m
//  BlocksKit
//
//  Created by dl on 2021/3/25.
//

#import "NEEventTracingSentinel.h"
#import <libkern/OSAtomic.h>

@implementation NEEventTracingSentinel {
    int32_t _value;
}

+ (instancetype)sentinel {
    return [self sentinelWithInitialValue:0];
}

+ (instancetype)sentinelWithInitialValue:(int32_t)initialValue {
    NEEventTracingSentinel *s = [NEEventTracingSentinel new];
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
