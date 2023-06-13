//
//  NEEventTracingVTree.h
//  NEEventTracing
//
//  Created by dl on 2021/2/26.
//

#import <Foundation/Foundation.h>
#import "NEEventTracingVTreeNode.h"
#import "NEEventTracingEventActionConfig.h"

NS_ASSUME_NONNULL_BEGIN

@class NEEventTracingVTree;

// MARK: 可以用来监听VTree的创建，以及VTree中node节点的曝光事件，以及非曝光的其他event事件
@protocol NEEventTracingVTreeObserver <NSObject>

@optional
/*!
 监听VTree的创建
 @param VTree 是 stable==YES 的状态，此时已经做好了遮挡逻辑，是一个稳定的状态，后续不会再修改
 @param lastVTree 上一个VTree，可能是nil
 @param hasChanges 两次VTree是否有变化，如果有变化，就意味着会产生新的 曝光开始/曝光结束
 */
- (void)didGenerateVTree:(NEEventTracingVTree *)VTree lastVTree:(NEEventTracingVTree * _Nullable)lastVTree hasChanges:(BOOL)hasChanges;

/*!
 节点即将曝光开始
 @param VTree 本次的虚拟树
 @param node 需要新曝光的节点
 */
- (void)VTree:(NEEventTracingVTree *)VTree willImpressNode:(NEEventTracingVTreeNode *)node;

/*!
 节点曝光开始
 @param VTree 本次的虚拟树
 @param node 需要新曝光的节点
 */
- (void)VTree:(NEEventTracingVTree *)VTree didImpressNode:(NEEventTracingVTreeNode *)node;

/*!
 节点即将曝光结束
 @param VTree 本次的虚拟树
 @param node 需要曝光结束的节点
 */
- (void)VTree:(NEEventTracingVTree *)VTree willImpressendNode:(NEEventTracingVTreeNode *)node;

/*!
 节点曝光结束
 @param VTree 本次的虚拟树
 @param node 需要曝光结束的节点
 */
- (void)VTree:(NEEventTracingVTree *)VTree didImpressendNode:(NEEventTracingVTreeNode *)node;

/*!
 即将触发节点event事件（非曝光）
 @param VTree 本次的虚拟树
 @param event 事件
 @param node 本次事件所关联的节点
 */
- (void)VTree:(NEEventTracingVTree *)VTree willEmitEvent:(NSString *)event onNode:(NEEventTracingVTreeNode *)node actionConfig:(NEEventTracingEventActionConfig *)actionConfig;

/*!
 触发节点event事件（非曝光）
 @param VTree 本次的虚拟树
 @param event 事件
 @param node 本次事件所关联的节点
 */
- (void)VTree:(NEEventTracingVTree *)VTree didEmitEvent:(NSString *)event onNode:(NEEventTracingVTreeNode *)node actionConfig:(NEEventTracingEventActionConfig *)actionConfig;

@end

/// MARK: VTree
@interface NEEventTracingVTree : NSObject <NSCopying>

// 主线程只是生成一个初步的VTree，子线程会进一步做更新，比如遮挡逻辑等
@property(nonatomic, assign, readonly, getter=isStable) BOOL stable;

// 当app进入后台后生成的VTree，会被标记位 visible==NO (而且后台过程中，会且只会生成这一次)
@property(nonatomic, assign, readonly, getter=isVisible) BOOL visible;

// 树的根节点(该节点是一个虚拟节点)
@property(nonatomic, strong, readonly) NEEventTracingVTreeNode *rootNode;

// 树的根页面节点(rootpage)
@property(nonatomic, strong, readonly, nullable) NEEventTracingVTreeNode *rootPageNode;

- (BOOL)containsNode:(NEEventTracingVTreeNode *)node;

- (void)removeNode:(NEEventTracingVTreeNode *)node;

// 从 node 开始向上查找 root page 节点
- (NEEventTracingVTreeNode * _Nullable)findRootPageNodeFromNode:(NEEventTracingVTreeNode *)node;

// MARK: 右侧广度遍历，找到第一个page节点
- (NEEventTracingVTreeNode * _Nullable)findToppestRightPageNode;

// MARK: 左侧广度遍历，找到第一个page节点
- (NEEventTracingVTreeNode * _Nullable)findToppestLeftPageNode;

/// MARK: 判断两个VTree是否内容上相等
- (BOOL)isEaualToOtherVTree:(NEEventTracingVTree *)otherVTree;
@end

@interface NEEventTracingVTree (Geometry)
/*!
 在整棵树上获取一个 point 位置的节点
 @param point 该位置是在 UIScreen 级别上的绝对位置
 */
- (NEEventTracingVTreeNode * _Nullable)hitTest:(CGPoint)point;
- (NEEventTracingVTreeNode * _Nullable)hitTest:(CGPoint)point pageOnly:(BOOL)pageOnly;

/*!
 通过 spm 或者对应的节点 || view
 */
- (NEEventTracingVTreeNode * _Nullable)nodeForSpm:(NSString *)spm;
- (UIView * _Nullable)nodeViewForSpm:(NSString *)spm;
@end

/// MARK: Debug
@interface NEEventTracingVTree (Debug)
- (NSDictionary *)debugJson;
- (NSString *)debugJsonString;
@end

NS_ASSUME_NONNULL_END
