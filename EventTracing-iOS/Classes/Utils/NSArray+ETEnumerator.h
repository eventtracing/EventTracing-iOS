//
//  NSArray+ETEnumerator.h
//  EventTracing
//
//  Created by dl on 2021/3/18.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, EventTracingEnumeratorType) {
    EventTracingEnumeratorTypeDFS,          // 深度优先遍历
    EventTracingEnumeratorTypeDFSRight,     // 深度优先遍历, 优先遍历右节点
    EventTracingEnumeratorTypeBFS,          // 广度优先遍历
    EventTracingEnumeratorTypeBFSRight      // 广度优先遍历, 优先遍历右节点
};

@interface NSArray<__covariant ObjectType> (ETEnumerator)

- (void)et_enumerateObjectsUsingBlock:(NSArray<ObjectType>* (NS_NOESCAPE ^)(ObjectType obj, BOOL *stop))block;

- (void)et_enumerateObjectsWithType:(EventTracingEnumeratorType)type
                         usingBlock:(NSArray<ObjectType>* (NS_NOESCAPE ^)(ObjectType obj, BOOL *stop))block;

@end

NS_ASSUME_NONNULL_END
