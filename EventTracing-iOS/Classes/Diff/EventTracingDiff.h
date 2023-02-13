//
//  EventTracingDiff.h
//  BlocksKit
//
//  Created by dl on 2021/3/16.
//

#import <Foundation/Foundation.h>
#import "EventTracingDiffable.h"

NS_ASSUME_NONNULL_BEGIN

@interface EventTracingDiffResults : NSObject

/// 是否结果一致
@property (nonatomic, assign, readonly) BOOL hasDiffs;

/// 第二个数组跟第一个比，多了哪些节点
@property(nonatomic, strong, readonly) NSArray<id<EventTracingDiffable>> *inserts;

/// 第二个数组跟第一个比，少了哪些节点
@property(nonatomic, strong, readonly) NSArray<id<EventTracingDiffable>> *deletes;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

FOUNDATION_EXPORT EventTracingDiffResults *ET_DiffBetweenArray(NSArray<id<EventTracingDiffable>> *_Nullable newArray,
                                                               NSArray<id<EventTracingDiffable>> *_Nullable oldArray);

NS_ASSUME_NONNULL_END
