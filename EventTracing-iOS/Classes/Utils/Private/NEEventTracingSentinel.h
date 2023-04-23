//
//  EventTracingSentinel.h
//  BlocksKit
//
//  Created by dl on 2021/3/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// a thread safe incrementing counter.
@interface EventTracingSentinel : NSObject

@property(atomic, readonly) int32_t value;

+ (instancetype)sentinel;
+ (instancetype)sentinelWithInitialValue:(int32_t)initialValue;

- (int32_t)increase;

@end

NS_ASSUME_NONNULL_END
