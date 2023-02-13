//
//  UIView+EventTracingPipEvent.h
//  EventTracing
//
//  Created by dl on 2021/7/22.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// MARK: 可以将一个非节点的 event pip 到另外一个节点上
/// 前提条件: 当前view不是一个节点 && 目标view是一个节点
@interface UIView (EventTracingPipEvent)

@property(nonatomic, strong, readonly, nullable) NSDictionary<NSString *, NSArray<UIView *> *> *et_pipedToMeEventViews;
@property(nonatomic, strong, readonly, nullable) NSDictionary<NSString *, UIView *> *et_pipTargetEventViews;

/// 指定 view 进行 pip
- (void)et_pipEventClickToView:(UIView *)view;
- (void)et_pipEvent:(NSString *)event toView:(UIView *)view;

/// 针对 click 事件 pip
///   1. 向上查找最近的匹配oid的节点
///   2. 向上查找最近的(任意)节点
- (void)et_pipEventClickToAncestorNodeViewOid:(NSString *)oid;
- (void)et_pipEventClickToAncestorNodeView;

/// 指定 event 事件 pip
///   1. 向上查找最近的匹配oid的节点
///   2. 向上查找最近的(任意)节点
- (void)et_pipEvent:(NSString *)event toAncestorNodeViewOid:(NSString *)oid;
- (void)et_pipEventToAncestorNodeView:(NSString *)event;

/// 取消到 目标view 的 pipEvent 操作
- (void)et_cancelPipEvent;

@end

NS_ASSUME_NONNULL_END
