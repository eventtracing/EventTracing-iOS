//
//  NEEventTracingEngine+Traverse.h
//  NEEventTracing
//
//  Created by dl on 2021/4/13.
//

#import "NEEventTracingEngine.h"

NS_ASSUME_NONNULL_BEGIN

@interface NEEventTracingTraverseAction : NSObject
@property(nonatomic, weak, readonly) UIView *view;
@property(nonatomic, assign, readonly) BOOL viewIsNil;

@property(nonatomic, assign) BOOL ignoreViewInvisible;

+ (instancetype)actionWithView:(UIView * _Nullable)view;
@end

// 1. 如果存在 action.view 为 nil 的UI变动事件，则直接表明需要 `traverse`，忽略后面的所有UI变动事件; 否则 => 2
// 2. 将action添加进来，供后面CPU空闲时，判断是否需要真正的 `traverse` 使用
@interface NEEventTracingStockedTraverseActionRecord : NSObject
@property(nonatomic, assign, readonly) BOOL passthrough;      // 如果存在 action.view 等于nil的，即为 yes
@property(nonatomic, strong, readonly) NSArray<NEEventTracingTraverseAction *> *actions;

- (void)actionDidOccured:(NEEventTracingTraverseAction *)action;
- (void)reset;
@end

@interface NEEventTracingEngine (TraverseAction)

/*!
 打一个遍历标识，在合适的时候会进行遍历
 @discussion 有条件的遍历，如果该view的变动，不应该引起 traverse, 则不再打遍历标识
    以下几个情况不会打遍历标识:
      1. view自身及其subViews都不是节点(page/element)
 */
- (void)traverse:(UIView * _Nullable)view;
- (void)traverse:(UIView * _Nullable)view
  traverseAction:(void(^ NS_NOESCAPE _Nullable)(NEEventTracingTraverseAction *action))block;

- (void)traverseForScrollView:(UIScrollView *)scrollView;

@end

NS_ASSUME_NONNULL_END
