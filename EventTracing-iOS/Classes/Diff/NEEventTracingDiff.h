//
//  NEEventTracingDiff.h
//  BlocksKit
//
//  Created by dl on 2021/3/16.
//

#import <Foundation/Foundation.h>
#import "NEEventTracingDiffable.h"

NS_ASSUME_NONNULL_BEGIN

@interface NEEventTracingDiffResults : NSObject

/// 是否结果一致
@property (nonatomic, assign, readonly) BOOL hasDiffs;

/// 第二个数组跟第一个比，多了哪些节点
@property(nonatomic, strong, readonly) NSArray<id<NEEventTracingDiffable>> *inserts;

/// 第二个数组跟第一个比，少了哪些节点
@property(nonatomic, strong, readonly) NSArray<id<NEEventTracingDiffable>> *deletes;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

FOUNDATION_EXPORT NEEventTracingDiffResults *NE_ET_DiffBetweenArray(NSArray<id<NEEventTracingDiffable>> *_Nullable newArray,
                                                               NSArray<id<NEEventTracingDiffable>> *_Nullable oldArray);

NS_ASSUME_NONNULL_END
