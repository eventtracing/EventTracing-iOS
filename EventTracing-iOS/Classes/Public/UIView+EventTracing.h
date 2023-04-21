//
//  UIView+EventTracing.h
//  BlocksKit
//
//  Created by dl on 2021/2/4.
//

#import <UIKit/UIKit.h>
#import "EventTracingVTreeNode.h"

NS_ASSUME_NONNULL_BEGIN

/// 动态参数, 以回调的方式来给节点补充参数
@protocol EventTracingVTreeNodeDynamicParamsProtocol <NSObject>
@optional
/// 可添加一些临时的动态参数
/// 当一个节点需要打点的时候调用
/// 这里是 `对象参数`
- (NSDictionary *)et_dynamicParams;
@end


typedef NSDictionary * _Nonnull (^ET_AddParamsCallback)(void);
typedef NSDictionary * _Nonnull (^ET_AddParamsCarryEventCallback)(NSString *event);

#pragma mark -
#pragma mark - Build Node Params
@protocol EventTracingVTreePageNodeParamsBuildProtocol <NSObject>
// et_pageId不为空，表示该vc是一个page
@property(nonatomic, copy, readonly, nullable) NSString *et_pageId;

// et_pageId不为空，表示该vc是一个page, 此时 et_isPage == YES
@property(nonatomic, assign, readonly) BOOL et_isPage;

/*!
 ！！推荐的做法，构建page的参数
 @param pageId 必填，不能为空，不然构建会失败
 @param params 选填，参数
 @discussion 推荐使用这个方式来统一构建
 */
- (void)et_setPageId:(NSString *)pageId params:(NSDictionary<NSString *, NSString *> * _Nullable)params;

/// MARK: `对象参数` param的增删改
- (void)et_addParams:(NSDictionary<NSString *, NSString *> *)params;
- (void)et_setParamValue:(NSString *)value forKey:(NSString *)key;
- (void)et_removeParamForKey:(NSString *)key;
- (void)et_removeAllParams;

/// MARK: 针对一些自定义事件添加block形式的参数构建(称为: `对象&&事件` 参数 )
/// 这些参数仅仅会在 event 的情况下，才会有;
/// 备注: 不适用于 `曝光` 场景，曝光场景，请使用标准的 `对象参数`
/// MARK: 这里的 callback 会被内部 view 层面强持有，请合理使用 strong/weak
- (void)et_addParamsCallback:(ET_AddParamsCallback)callback;
- (void)et_addParamsCallback:(ET_AddParamsCallback)callback forEvent:(NSString *)event;
- (void)et_addParamsCallback:(ET_AddParamsCallback)callback forEvents:(NSArray<NSString *> *)events;
- (void)et_addParamsCarryEventCallback:(ET_AddParamsCarryEventCallback)callback forEvents:(NSArray<NSString *> *)events;

// position
/// MARK: pos的变化会引起 spm 的变化，变化后，会引起重新曝光逻辑
@property(nonatomic, assign, setter=et_setPosition:) NSUInteger et_position;

// 清除当前节点属性，以及节点上的所有参数
// 注意: 除了清理 `builder` 中的参数，还会清理掉 `pageId` `elementId` 等，所有在该节点上的配置 (以及虚拟父节点信息，也会被清理)
- (void)et_clear;

// 获取设置的params(静态参数)
- (NSDictionary * _Nullable)et_params;

// SDK内置是否打 点击||曝光事件
// default: ETNodebuildinEventLogDisableStrategyAll
@property(nonatomic, assign, setter=et_setBuildinEventLogDisableStrategy:) ETNodeBuildinEventLogDisableStrategy et_buildinEventLogDisableStrategy;

// 针对page节点，设置该节点是root page
// 一个page节点是否是root page，SDK内部会向上查找最顶层的page节点作为root page，如果业务方设置了某个page节点为root page，可能会修改SDK内部查找的结果
// 使用场景: RN有一个容器ViewController，是一个page节点，但是RN内部有导航，可以把RN内部的子页面强行设置为rootpage，这样一来，RN子页面可以有自己的_actseq, _pgrefer/_psrefer逻辑
@property(nonatomic, assign, setter=et_setRootPage:, getter=et_isRootPage) BOOL et_rootPage;

// 如果当前节点是 page 节点，可选择设置该节点是否会参与 `page 遮挡`
// 如果是 `et_pageOcclusionEnable && et_isPage` 则该节点会尝试做遮挡 父节点名下添加顺序位于当前节点之前 的其他节点
// default: YES
@property(nonatomic, assign, setter=et_setPageOcclusitionEnable:) BOOL et_pageOcclusionEnable;

// 该view是否忽略refer(该view可以不是一个节点)
// 如果忽略refer，则该节点的事件(比如 _ec 等)不再参与链路追踪，不会在 _pgrefer, _psrefer, eventrefer(_addrefer), _hsrefer, _multirefers 等体现出来，也不会参与 defined-xpath
// 注意，该配置是级联的，如果某一个父view(YES), 则其所有子view都相当于是(YES)
// default: NO
@property(nonatomic, assign, setter=et_setIgnoreReferCascade:, getter=et_isIgnoreReferCascade) BOOL et_ignoreReferCascade;

// 该节点的psrefer是否静默
// 如果设置为 YES，则该节点的 psrefer 不参与链路追踪，即不会在 multirefers 中出现
// default: NO
@property(nonatomic, assign, setter=et_setPsreferMute:, getter=et_psreferMute) BOOL et_psreferMute;

/// MARK: 子页面，pv曝光埋点，可以生成refer (refer_type == 'subpage_pv')
@property(nonatomic, assign, setter=et_setSubpagePvToReferEnable:, getter=et_subpagePvToReferEnable) BOOL et_subpagePvToReferEnable;

/// MARK: 子页面消费refer的类型
/// 针对 rootpage，该值默认为 "ec|custom"
/// 针对 subpage，该值默认为 "none"
/// 所有可选值: all,  subpage_pv, ec, custom
/// 其中 custom 目前是除了 明确类型的 其他类型
/// all 是全部类型
/// subpage_pv 专指子页面曝光产生的refer
/// 不建议 root page 使用此 API
/// 不建议直接使用此API，建议使用下面3个API
///  - `et_clearSubpageConsumeReferOption`              =>  清空设置
///  - `et_makeSubpageConsumeAllRefer`         =>  适合首页 tab 子页面切换的场景
///  - `et_makeSubpageConsumeEventRefer`     =>  适合浮层弹窗场景，比如首页 alert
@property(nonatomic, assign, setter=et_setSubpageConsumeOption:, getter=et_subpageConsumeOption) EventTracingPageReferConsumeOption et_subpageConsumeOption;

/// MARK: 清空设置
- (void)et_clearSubpageConsumeReferOption;
/// MARK: 适合首页 tab 子页面切换的场景，设置为`NEEventTracingPageReferConsumeOptionAll`
- (void)et_makeSubpageConsumeAllRefer;
/// MARK: 适合浮层弹窗场景，比如首页 alert，设置为`NEEventTracingPageReferConsumeOptionExceptSubPagePV`
- (void)et_makeSubpageConsumeEventRefer;
@end

@protocol EventTracingVTreeNodeParamsBuildProtocol <EventTracingVTreePageNodeParamsBuildProtocol>
// et_elementId不为空，标识该view是一个element
@property(nonatomic, copy, readonly, nullable) NSString *et_elementId;

// et_elementId不为空，标识该view是一个element, 此时 et_isElement == YES
@property(nonatomic, assign, readonly) BOOL et_isElement;
/*!
 ！！推荐的做法，构建element的参数
 @param elementId 必填，不能为空，不然构建会失败
 @discussion 推荐使用这个方式来统一构建
 */
- (void)et_setElementId:(NSString *)elementId params:(NSDictionary<NSString *, NSString *> * _Nullable)params;
@end


@interface UIViewController (EventTracingParams) <EventTracingVTreePageNodeParamsBuildProtocol>
@property(nonatomic, readonly, nullable) EventTracingVTreeNode *et_currentVTreeNode;
@end

@interface UIView (EventTracingParams) <EventTracingVTreeNodeParamsBuildProtocol>
@property(nonatomic, readonly, nullable) EventTracingVTreeNode *et_currentVTreeNode;
@end

@interface UIView (EventTracingVTreeVirtualParentNode)
@property(nonatomic, copy, readonly, nullable) NSString *et_virtualParentElementId;
@property(nonatomic, copy, readonly, nullable) NSString *et_virtualParentPageId;
@property(nonatomic, copy, readonly, nullable) NSString *et_virtualParentOid;
@property(nonatomic, assign, readonly) BOOL et_virtualParentIsPage;

/*!
 给一个节点/非节点向上插入一个虚拟节点
 @param elementId 必填，虚拟节点的 _oid
 @param nodeIdentifier 必填, 虚拟几点的唯一标识; 如果是字符串，则使用该字符串作为id，否则使用该id的内存地址;
 @param params 虚拟节点的业务参数
 
 @discussion 两个场景: 1. 该view是节点；2. 该view不是节点，则该view名下所有最上层的节点都设置该虚拟父节点
 @discussion 双端开发可能存在虚拟树层级很难对齐，可以通过增加虚拟节点的方式来让双端对齐
 @discussion nodeIdentifier参数很重要，多个同层级的节点设置虚拟父节点，如果 nodeIdentifier 相等，则这些同层级别的节点的虚拟父节点会合并成一个
 */
- (void)et_setVirtualParentElementId:(NSString *)elementId
                      nodeIdentifier:(id)nodeIdentifier
                              params:(NSDictionary<NSString *, NSString *> * _Nullable)params;

- (void)et_setVirtualParentPageId:(NSString *)pageId
                   nodeIdentifier:(id)nodeIdentifier
                           params:(NSDictionary<NSString *,NSString *> *)params;

/*!
 给一个节点/非节点向上插入一个虚拟节点
 @param oid 必填，虚拟节点的 _oid
 @param isPage 必填，虚拟节点是否是 page 节点
 @param nodeIdentifier 必填, 虚拟几点的唯一标识; 如果是字符串，则使用该字符串作为id，否则使用该id的内存地址;
 @param position 虚拟父节点也出现出现多次，_spm维度也需要区分
 @param buildinEventLogDisableStrategy 如果全局关闭了元素节点的曝光结束，则这里也需要单独开启
 @param params 虚拟节点的业务参数
*/
- (void)et_setVirtualParentOid:(NSString *)oid
                        isPage:(BOOL)isPage
                nodeIdentifier:(id)nodeIdentifier
                      position:(NSUInteger)position
buildinEventLogDisableStrategy:(ETNodeBuildinEventLogDisableStrategy)buildinEventLogDisableStrategy
                        params:(NSDictionary<NSString *, NSString *> * _Nullable)params;

- (void)et_setVirtualParentElementId:(NSString *)elementId
                      nodeIdentifier:(id)nodeIdentifier
                            position:(NSUInteger)position
      buildinEventLogDisableStrategy:(ETNodeBuildinEventLogDisableStrategy)buildinEventLogDisableStrategy
                              params:(NSDictionary<NSString *, NSString *> * _Nullable)params DEPRECATED_MSG_ATTRIBUTE("废弃, 请使用 `-[UIView et_setVirtualParentOid:isPage:nodeIdentifier:position:buildinEventLogDisableStrategy:params:]`");

@end

#pragma mark -
#pragma mark - Build Logical Mount
@protocol EventTracingVTreeNodeLogicalMountProtocol <NSObject>

/// MARK: 1. 主动挂载(to view)  ==>> 优先级最高
// 逻辑挂载在指定的 `vc/view` 下（修改原始view树的上下层级关系）
// 注: 逻辑挂载一定要注意，避免循环
/// MARK: 目标 `vc.view/view` 可以不是一个节点
@property(nonatomic, weak, setter=et_setLogicalParentViewController:, nullable) UIViewController *et_logicalParentViewController;
@property(nonatomic, weak, setter=et_setLogicalParentView:, nullable) UIView *et_logicalParentView;

/// MARK: 2. 主动挂载(to spm)  ==>> 优先级次之
@property(nonatomic, copy, nullable, setter=et_setLogicalParentSPM:) NSString *et_logicalParentSPM;

/// MARK: 3. 自动挂载  ==>> 优先级最低
/*!
 是否自动挂载到当前正在展示的顶层RootPage节点上（即虚拟树最右侧的顶层根page）
 @discussion 主要针对的是浮层，浮层应该被当做子page来对待，需要将浮层这个子page挂载在当前正在展示的根page下面
 @discussion 跟 et_logicalParentViewController && et_logicalParentView 是冲突的，设置autoMount，会把前面的逻辑挂载清除
 */
@property(nonatomic, assign, readonly) BOOL et_isAutoMountOnCurrentRootPageEnable;
- (void)et_autoMountOnCurrentRootPage;
- (void)et_autoMountOnCurrentRootPageWithPriority:(ETAutoMountRootPageQueuePriority)priority;
- (void)et_cancelAutoMountOnCurrentRootPage;

// 业务方可明确控制节点的 逻辑visible
// 如果节点 逻辑visible 为NO，则该节点直接不可见，忽略其他可见因素
@property(nonatomic, assign, setter=et_setLogicalVisible:) BOOL et_logicalVisible;
// 设置自己的可见区域
// default value:  {top: 0, left: 0, bottom: 0, right: 0}
@property(nonatomic, assign, setter=et_setVisibleEdgeInsets:) UIEdgeInsets et_visibleEdgeInsets;

// 节点的 VisibleRect 计算策略
// 【！！推荐】default: ETNodeVisibleRectCalculateStrategyOnParentNode
@property(nonatomic, assign, setter=et_setVisibleRectCalculateStrategy:) ETNodeVisibleRectCalculateStrategy et_visibleRectCalculateStrategy;
@end

@interface UIViewController (EventTracingVTree) <EventTracingVTreeNodeLogicalMountProtocol>
@end

@interface UIView (EventTracingVTree) <EventTracingVTreeNodeLogicalMountProtocol>
@end


#pragma mark -
#pragma mark - VTree node reuse
@protocol EventTracingVTreeNodeReuseProtocol <NSObject>
// ！！重要: 最终生成的identifier，用于唯一标识该 VTreeNode
@property(nonatomic, strong, readonly, nullable) NSString *et_reuseIdentifier;

// et_bindDataForReuse: 通过参数来生成的identifier
@property(nonatomic, strong, readonly, nullable) NSString *et_bizLeafIdentifier;

// 在指定的标识符后拼接上该视图的唯一类标识符，返回拼接后的结果
@property(nonatomic, readonly, nullable) NSString *(^et_autoClassifyIdAppend)(NSString *identifier);

/*!
 view复用的时候，业务方需要干预，比如cell复用
 @discussion 这里有两个推荐的选择: 1. 【推荐】使用model绑定(内部使用内存地址); 2: 使用业务id
 */
- (void)et_bindDataForReuse:(id)data;

// 如果当前节点已经触发过了曝光，由于数据更新等原因，需要再次曝光，可调用此方法
// 可在任何时候调用
- (void)et_setNeedsImpress;
@end

@interface UIViewController (EventTracingReuse) <EventTracingVTreeNodeReuseProtocol>
@end

@interface UIView (EventTracingReuse) <EventTracingVTreeNodeReuseProtocol>
@end

#pragma mark -
#pragma mark - Tracing Refer
__deprecated_msg("已废弃 toid，设置不会生效")
@interface UIView (EventTracingRefer)
/// 在该view上发生点击事件(或者自定义事件)后，会把该事件以及 et_toid 记录在一个队列中（队列最大保存最近的5个记录）
/// 等下一个root page node曝光的时候，会到这个队列中查找
/// 如果可以通过 toid 的的方式查找到，则将该事件跟 root page node的曝光关联起来
/// 降级: 如果匹配不到，则直接去最近的一次事件
@property(nonatomic, copy, readonly, nullable) NSArray<NSString *> *et_toids;

- (void)et_makeReferToid:(NSString *)toid;
- (void)et_makeReferToids:(NSString *)toid, ...NS_REQUIRES_NIL_TERMINATION;

- (void)et_remakeReferToid:(NSString *)toid;
- (void)et_remakeReferToids:(NSString *)toid, ...NS_REQUIRES_NIL_TERMINATION;

- (void)et_clearReferToids;
@end

#pragma mark - Helper Methods

FOUNDATION_EXPORT void ET_BuildParamsVariableViews(NSDictionary<NSString *, NSString *> *params, UIView *view, ...)NS_REQUIRES_NIL_TERMINATION;
FOUNDATION_EXPORT void ET_BuildParamsMultiViews(NSArray<UIView *> *views, NSDictionary<NSString *, NSString *> *params);

NS_ASSUME_NONNULL_END
