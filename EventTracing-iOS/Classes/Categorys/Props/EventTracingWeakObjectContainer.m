//
//  EventTracingWeakObjectContainer.m
//  EventTracing
//
//  Created by dl on 2021/7/27.
//

#import "EventTracingWeakObjectContainer.h"

@implementation EventTracingWeakObjectContainer
- (instancetype)initWithObject:(id)object {
    return [self initWithTarget:nil object:object];
}

- (instancetype)initWithTarget:(id _Nullable)target object:(id)object {
    if (!(self = [super init]))
        return nil;
    
    _target = target;
    _object = object;
    
    return self;
}
@end
