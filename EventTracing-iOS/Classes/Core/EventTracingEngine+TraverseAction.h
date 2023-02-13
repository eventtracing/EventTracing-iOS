//
//  EventTracingEngine+Traverse.h
//  EventTracing
//
//  Created by dl on 2021/4/13.
//

#import "EventTracingEngine.h"

NS_ASSUME_NONNULL_BEGIN

@interface EventTracingTraverseAction : NSObject
@property(nonatomic, weak, readonly) UIView *view;
@property(nonatomic, assign, readonly) BOOL viewIsNil;

@property(nonatomic, assign) BOOL ignoreViewInvisible;

+ (instancetype)actionWithView:(UIView * _Nullable)view;
@end

@interface EventTracingEngine (TraverseAction)

/*!
 打一个遍历标识，在合适的时候会进行遍历
 @discussion 有条件的遍历，如果该view的变动，不应该引起 traverse, 则不再打遍历标识
    以下几个情况不会打遍历标识:
      1. view自身及其subViews都不是节点(page/element)
 */
- (void)traverse:(UIView * _Nullable)view;
- (void)traverse:(UIView * _Nullable)view
  traverseAction:(void(^ NS_NOESCAPE _Nullable)(EventTracingTraverseAction *action))block;

- (void)traverseForScrollView:(UIScrollView *)scrollView;

@end

NS_ASSUME_NONNULL_END
