//
//  NSArray+ETEnumerator.m
//  EventTracing
//
//  Created by dl on 2021/3/18.
//

#import "NSArray+ETEnumerator.h"
#include <vector>
#include <stack>

@implementation NSArray (ETEnumerator)

- (void)et_enumerateObjectsUsingBlock:(NSArray<id> * _Nonnull (NS_NOESCAPE ^)(id _Nonnull obj, BOOL * _Nonnull stop))block {
    [self et_enumerateObjectsWithType:EventTracingEnumeratorTypeBFS usingBlock:block];
}

- (void)et_enumerateObjectsWithType:(EventTracingEnumeratorType)type usingBlock:(NSArray<id> * _Nonnull (NS_NOESCAPE ^)(id _Nonnull obj, BOOL * _Nonnull stop))block {
    if (!block) {
        return;
    }
    
    if (type == EventTracingEnumeratorTypeBFS) {
        [self _et_enumerateObjectsBFSUsingBlock:block];
    } else if (type == EventTracingEnumeratorTypeBFSRight) {
        [self _et_enumerateObjectsBFSWithReverse:YES usingBlock:block];
    } else if (type == EventTracingEnumeratorTypeDFS) {
        [self _et_enumerateObjectsDFSUsingBlock:block];
    } else if (type == EventTracingEnumeratorTypeDFSRight) {
        [self _et_enumerateObjectsDFSWithReverse:YES UsingBlock:block];
    }
}

- (void) _et_enumerateObjectsBFSUsingBlock:(NSArray * _Nonnull (^)(id _Nonnull obj, BOOL * _Nonnull stop))block {
    [self _et_enumerateObjectsBFSWithReverse:NO usingBlock:block];
}

- (void) _et_enumerateObjectsBFSWithReverse:(BOOL)reverse usingBlock:(NSArray * _Nonnull (^)(id _Nonnull obj, BOOL * _Nonnull stop))block {
    __block std::vector<id> vector;
    
    void(^pushVectorObjects)(NSArray *) = ^(NSArray *objects){
        [objects enumerateObjectsWithOptions:(reverse ? NSEnumerationReverse : 0) usingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            vector.insert(vector.begin(), obj);
        }];
    };
    pushVectorObjects(self);
    
    __block BOOL stop = NO;
    while (!vector.empty() && !stop) {
        id obj = vector.back();
        
        NSArray *result = block(obj, &stop);
        
        vector.pop_back();
        
        pushVectorObjects(result);
    }
}

- (void) _et_enumerateObjectsDFSUsingBlock:(NSArray * _Nonnull (^)(id _Nonnull obj, BOOL * _Nonnull stop))block {
    [self _et_enumerateObjectsDFSWithReverse:NO UsingBlock:block];
}

- (void) _et_enumerateObjectsDFSWithReverse:(BOOL)reverse UsingBlock:(NSArray * _Nonnull (^)(id _Nonnull obj, BOOL * _Nonnull stop))block {
    __block std::stack<id> stack;
    
    void(^pushStackObjects)(NSArray *) = ^(NSArray *objects){
        [objects enumerateObjectsWithOptions:(reverse ? 0 : NSEnumerationReverse) usingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            stack.push(obj);
        }];
    };
    
    pushStackObjects(self);
    
    __block BOOL stop = NO;
    while (!stack.empty() && !stop) {
        id obj = stack.top();
        
        NSArray *result = block(obj, &stop);
        
        stack.pop();
        
        pushStackObjects(result);
    }
}

@end
