//
//  NEEventTracingWeakObjectContainer.h
//  NEEventTracing
//
//  Created by dl on 2021/7/27.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NEEventTracingWeakObjectContainer<__covariant ObjectType> : NSObject
@property(nonatomic, readonly, weak, nullable) ObjectType target;
@property(nonatomic, readonly, weak) ObjectType object;

- (instancetype)initWithObject:(id)object;
- (instancetype)initWithTarget:(id _Nullable)target object:(id)object;
@end

NS_ASSUME_NONNULL_END
