//
//  NEEventTracingDiffable.h
//  BlocksKit
//
//  Created by dl on 2021/3/16.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol NEEventTracingDiffable <NSObject>

// 节点的id
- (nonnull id<NSObject>)ne_et_diffIdentifier;

// 节点是否相等
- (BOOL)ne_et_isEqualToDiffableObject:(nullable id<NEEventTracingDiffable>)object;

@end

NS_ASSUME_NONNULL_END
