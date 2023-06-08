//
//  NEEventTracingVTreeNode.h
//  NEEventTracing
//
//  Created by dl on 2021/2/26.
//

#import <Foundation/Foundation.h>
#import "NEEventTracingDiffable.h"
#import "NEEventTracingDefines.h"

NS_ASSUME_NONNULL_BEGIN

@class NEEventTracingVTree;
@interface NEEventTracingVTreeNode : NSObject <NSCopying, NEEventTracingDiffable>

@property(nonatomic, weak, readonly) NEEventTracingVTree *VTree;
@property(nonatomic, assign, readonly, getter=isRoot) BOOL root;
@property(nonatomic, assign, readonly, getter=isVirtualNode) BOOL virtualNode;
@property(nonatomic, assign, readonly) NSInteger depth;     // 节点在VTree中的深度

@property(nonatomic, copy, readonly) NSString *identifier;
@property(nonatomic, weak, readonly) UIView *view;      // 虚拟节点，view==nil
@property(nonatomic, assign, readonly) NEETNodeBuildinEventLogDisableStrategy buildinEventLogDisableStrategy;

/// MARK: 该节点曝光的最大比例, 取值范围 [0,1]
// 随着一个节点曝光之后持续的展示，最大曝光比例可能会增大，这里只取最大值
@property(nonatomic, assign, readonly) CGFloat impressMaxRatio;

/// MARK: # refer
@property(nonatomic, copy, readonly) NSString *spm;
@property(nonatomic, copy, readonly) NSString *scm;
@property(nonatomic, assign, readonly, getter=isSCMNeedsER) BOOL scmNeedsER;
@property(nonatomic, copy, readonly) NSString *oid;
@property(nonatomic, assign, readonly) NSUInteger position;
@property(nonatomic, assign, readonly) BOOL ignoreRefer;            // 该节点是否忽略refer链路（包括undefined-xpath）
@property(nonatomic, strong, readonly, nullable) NSArray<NSString *> *toids DEPRECATED_MSG_ATTRIBUTE("已废弃toids，设置不会生效");
@property(nonatomic, copy, readonly, nullable) NSString *pgrefer;
// 页面第一次创建的时候的取的 pgrefer，后续不会随着页面的反复退出进入而修改
// node equal的情况下，该值会被同步到后续的节点上
@property(nonatomic, copy, readonly, nullable) NSString *psrefer;

/// MARK: for page node
// 当前页面的页面深度: 页面曝光的时候，会+1
// 主线程也会访问，只需要保证访问是原子性即可
@property(atomic, assign, readonly) NSUInteger pgstep;

// 1. 当前节点向上递归，取root page节点的 actseqSentinel.value 值
// 2. 如果该节点向上找不到 page node，则取 toppest node（非root node）
// 3. 埋点的时候，携带 actseq 的时机等价于 actseq 自增的时机 => event事件(内置click事件，以及业务方自定义事件&明确指明需要自增actseq的)
@property(nonatomic, assign, readonly) NSUInteger actseq;

// 曝光开始时间
@property(nonatomic, assign, readonly) NSTimeInterval beginTime;

@property(nonatomic, assign, readonly) BOOL isPageNode;
@property(nonatomic, weak, readonly, nullable) NEEventTracingVTreeNode *parentNode;
@property(nonatomic, strong, readonly) NSArray<NEEventTracingVTreeNode *> *subNodes;

// 被遮挡的场景, visible是NO
@property(nonatomic, assign, readonly, getter=isVisible) BOOL visible;
@property(nonatomic, assign, readonly, getter=isBlockedBySubPage) BOOL blockedBySubPage;         // 被子page遮挡

// MARK: # Geometry
// 是基于 UIScreen 的可见区域
// 计算可见区域的时候，是依赖parentNode节点的可见区域的
@property(nonatomic, assign, readonly) CGRect visibleRect;
@property(nonatomic, assign, readonly) NEETNodeVisibleRectCalculateStrategy visibleRectCalculateStrategy;
// 根据 visibleRect 计算出的相对于 paremtNode 的可见区域
@property(nonatomic, assign, readonly) CGRect visibleFrame;

// 如果当前节点是页面节点，该节点是否会参与做 `page 遮挡`
@property(nonatomic, assign, readonly) BOOL pageOcclusionEnable;

// psrefer 静默表示节点不参与 multirefer
@property(nonatomic, assign, readonly) BOOL psreferMute;

/// 子页面，pv曝光埋点，可以生成refer (refer_type == 'subpage_pv')
@property(nonatomic, assign, readonly) BOOL subpagePvToReferEnable;

/// 针对 rootpage，该值默认为 "ec|custom"
/// 针对 subpage，该值默认为 "none"
/// 所有可选值: all, subpage_pv, ec, custom
/// 其中 custom 目前是除了 明确类型的 其他类型
/// all 是全部类型
/// subpage_pv 专指子页面曝光产生的refer
@property(nonatomic, assign, readonly) NEEventTracingPageReferConsumeOption pageReferConsumeOption;

@end

@interface NEEventTracingVTreeNode (Enumerater)
// 当前节点向上找第一个page节点(从当前节点开始算起)
- (NEEventTracingVTreeNode * _Nullable)firstAncestorPageNode;

// 便捷方法: 向上遍历祖先节点(从当前节点开始算起)
- (void)enumerateAncestorNodeWithBlock:(void(NS_NOESCAPE ^ _Nonnull)(NEEventTracingVTreeNode *ancestorNode, BOOL * _Nonnull stop))block;

/// 从当前 VTree 找 `最顶层` && `最右侧` 的页面节点
/// 等同于查找当前 `rootPage` 
- (NEEventTracingVTreeNode * _Nullable)findToppestNode:(BOOL)onlyPageNode;
@end

// MARK: Geometry
@interface NEEventTracingVTreeNode (Geometry)
- (NEEventTracingVTreeNode * _Nullable)hitTest:(CGPoint)point;
- (NEEventTracingVTreeNode * _Nullable)hitTest:(CGPoint)point pageOnly:(BOOL)pageOnly;
@end

@interface NEEventTracingVTreeNode (Params)
// Params
- (NSDictionary<NSString *, NSString *> *)nodeParams;
- (NSDictionary<NSString *, NSString *> *)nodeStaticParams;
- (NSDictionary<NSString *, NSString *> *)nodeDynamicParams;
- (NSDictionary<NSString *, NSString *> *)nodeCallbackParamsForEvent:(NSString *)event;
- (NSDictionary<NSString *, NSString *> *)nodeParamsForEvent:(NSString *)event;
@end

/// MARK: Debug
@interface NEEventTracingVTreeNode (Debug)
- (NSDictionary *)debugJson;
- (NSString *)debugJsonString;
- (NSDictionary *)debugSelfJson;
@end

@interface NEEventTracingVTreeNode (Deprecated)

/// MARK: # 曝光限定
@property(nonatomic, assign, readonly) CGFloat impressRatioThreshold DEPRECATED_MSG_ATTRIBUTE("已废弃曝光限定");
@property(nonatomic, assign, readonly) NSTimeInterval impressIntervalThreshold DEPRECATED_MSG_ATTRIBUTE("已废弃曝光限定");

/// MARK: 已经废弃
// 如果当前页面还没有埋点，则该节点先临时挂载到 `parentId` 名下，否则挂载到 rootPage 名下
@property(nonatomic, assign, readonly, getter=isAutoMountParentWaring) BOOL autoMountParentWaring DEPRECATED_MSG_ATTRIBUTE("方法已废弃, return NO");
@end

NS_ASSUME_NONNULL_END
