//
//  UIView+EventTracingNodeImpressObserver.h
//  EventTracing
//
//  Created by dl on 2021/4/25.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

// 在节点(虚拟层节点不支持)层面来 observer impress/impressend 事件，业务侧可以针对这个时候做一些事情
@class EventTracingVTree;
@class EventTracingVTreeNode;
@protocol EventTracingVTreeNodeImpressObserver <NSObject>
@optional

/*!
 一个节点即将曝光的时候被调用
 
 @param view 节点对应的view
 @param event 曝光事件的key => _pv/_ev
 @param node 节点对象
 @param VTree 虚拟树
 */
- (void)view:(UIView *)view willImpressWithEvent:(NSString *)event node:(EventTracingVTreeNode *)node inVTree:(EventTracingVTree *)VTree;

/*!
 @brief一个节点即曝光结束的时候被调用
  在这个时机，可以完整获取各种refer，已经生成好
 
 @param view 节点对应的view
 @param event 曝光事件的key => _pv/_ev
 @param node 节点对象
 @param VTree 虚拟树
 */
- (void)view:(UIView *)view didImpressWithEvent:(NSString *)event node:(EventTracingVTreeNode *)node inVTree:(EventTracingVTree *)VTree;

/*!
 一个节点曝光曝光结束的时候被调用
 
 @param view 节点对应的view
 @param event 曝光事件的key => _pv/_ev
 @param duration 曝光时长, 单位 => ms
 @param node 节点对象
 @param VTree 虚拟树
 */
- (void)view:(UIView *)view didImpressendWithEvent:(NSString *)event duration:(NSTimeInterval)duration node:(EventTracingVTreeNode *)node inVTree:(EventTracingVTree *)VTree;
@end

@interface UIView (EventTracingVTreeObserver)
@property(nonatomic, strong, readonly) NSArray<id<EventTracingVTreeNodeImpressObserver>> *et_impressObservers;

- (void)et_addImpressObserver:(id<EventTracingVTreeNodeImpressObserver>)observer;
- (void)et_removeImpressObserver:(id<EventTracingVTreeNodeImpressObserver>)observer;
- (void)et_removeallImpressObservers;
@end

NS_ASSUME_NONNULL_END
