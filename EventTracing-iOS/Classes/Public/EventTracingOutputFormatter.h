//
//  EventTracingOutputFormatter.h
//  BlocksKit
//
//  Created by dl on 2021/2/4.
//

#import <Foundation/Foundation.h>
#import "EventTracingVTree.h"
#import "EventTracingVTreeNode.h"

NS_ASSUME_NONNULL_BEGIN

/// 日志输出的格式
@protocol EventTracingOutputFormatter <NSObject>

/// 格式化生成日志的格式
/// - Parameters:
///   - event: 埋点的事件
///   - logActionParams: 对象上的事件参数
///   - node: 节点
///   - VTree: 节点对应的VTree
/// - Returns: 日志 Json
- (NSDictionary *)formatWithEvent:(NSString *)event
                  logActionParams:(NSDictionary * _Nullable)logActionParams
                             node:(EventTracingVTreeNode *)node
                          inVTree:(EventTracingVTree *)VTree;

@end

/// 动态公参的注入
@protocol EventTracingOutputPublicDynamicParamsProvider <NSObject>

/// 所有日志输出之前，通过调用该方法动态添加全局公参，返回的公参，仅仅对本次调用生效
/// - Parameters:
///   - event: 埋点事件
///   - node: 节点
///   - VTree: 节点对应的VTree
- (NSDictionary *)outputPublicDynamicParamsForEvent:(NSString *)event
                                               node:(EventTracingVTreeNode * _Nullable)node
                                            inVTree:(EventTracingVTree * _Nullable)VTree;

@end

/// 日志输出到 `OutputChannel` 之前，有一些修改或者监控的能力
@protocol EventTracingOutputParamsFilter <NSObject>

/// 给每一个即将要输出的日志内容，做二次加工
/// - Parameters:
///   - event: 埋点的事件
///   - originalJson: 原始 Json
///   - node: 节点
///   - VTree: 节点对应的VTree
/// - Returns: 修改之后的 Json
- (NSDictionary *)filteredJsonWithEvent:(NSString *)event
                           originalJson:(NSDictionary *)originalJson
                                   node:(EventTracingVTreeNode * _Nullable)node
                                inVTree:(EventTracingVTree * _Nullable)VTree;

@end

/// @brief SCM的格式化配置
/// @discussion 所有的 _xxrefer 的格式中都包含 _scm, 而且是自底向上递归节点的 _nodeSCM 通过 `|` 拼接得来
/// @discussion 默认实现使用 EventTracingReferNodeSCMDefaultFormatter，格式 => s_cid:s_ctype:s_ctraceid:s_ctrp
@protocol EventTracingReferNodeSCMFormatter <NSObject>

/// scm 格式构造方法
/// @param view  节点对应的view对象
/// @param node 节点
/// @param VTree 节点对应的VTree
- (NSString *)nodeSCMWithView:(UIView *)view
                         node:(EventTracingVTreeNode *)node
                      inVTree:(EventTracingVTree *)VTree;

/// 如果cid中有特殊字符，则需要加密
/// @param node 节点
- (BOOL)needsEncodeSCMForNode:(EventTracingVTreeNode *)node;

/// MARK: for H5
/// 对于 H5 场景，H5内部的节点对 Native 不可见，仅仅有 params，对于这个场景，scm的生成就没有 view node 等信息
/// @param params H5 节点的参数
- (NSString *)nodeSCMWithNodeParams:(NSDictionary<NSString *, NSString *> *)params;

/// MARK: for H5
/// 对于 H5 场景，H5内部的节点对 Native 不可见，仅仅有 params，对于这个场景，scm的生成就没有 view node 等信息
/// @param params H5 节点的参数
- (BOOL)needsEncodeSCMForNodeParams:(NSDictionary<NSString *, NSString *> *)params;

@end

NS_ASSUME_NONNULL_END
