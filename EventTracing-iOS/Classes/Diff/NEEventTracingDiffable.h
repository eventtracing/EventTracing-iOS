//
//  EventTracingDiffable.h
//  BlocksKit
//
//  Created by dl on 2021/3/16.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol EventTracingDiffable <NSObject>

// 节点的id
- (nonnull id<NSObject>)et_diffIdentifier;

// 节点是否相等
- (BOOL)et_isEqualToDiffableObject:(nullable id<EventTracingDiffable>)object;

@end

NS_ASSUME_NONNULL_END
