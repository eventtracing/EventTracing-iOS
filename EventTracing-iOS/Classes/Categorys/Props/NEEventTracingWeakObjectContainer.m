//
//  NEEventTracingWeakObjectContainer.m
//  NEEventTracing
//
//  Created by dl on 2021/7/27.
//

#import "NEEventTracingWeakObjectContainer.h"

@implementation NEEventTracingWeakObjectContainer
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
