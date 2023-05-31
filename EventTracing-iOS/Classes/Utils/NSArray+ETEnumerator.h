//
//  NSArray+ETEnumerator.h
//  NEEventTracing
//
//  Created by dl on 2021/3/18.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, NEEventTracingEnumeratorType) {
    NEEventTracingEnumeratorTypeDFS,          // 深度优先遍历
    NEEventTracingEnumeratorTypeDFSRight,     // 深度优先遍历, 优先遍历右节点
    NEEventTracingEnumeratorTypeBFS,          // 广度优先遍历
    NEEventTracingEnumeratorTypeBFSRight      // 广度优先遍历, 优先遍历右节点
};

@interface NSArray<__covariant ObjectType> (ETEnumerator)

- (void)ne_et_enumerateObjectsUsingBlock:(NSArray<ObjectType>* (NS_NOESCAPE ^)(ObjectType obj, BOOL *stop))block;

- (void)ne_et_enumerateObjectsWithType:(NEEventTracingEnumeratorType)type
                         usingBlock:(NSArray<ObjectType>* (NS_NOESCAPE ^)(ObjectType obj, BOOL *stop))block;

@end

NS_ASSUME_NONNULL_END
