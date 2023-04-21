//
//  EventTracingBuilder.h
//  EventTracing
//
//  Created by dl on 2022/12/6.
//

#import <Foundation/Foundation.h>
#import "EventTracingDefines.h"

NS_ASSUME_NONNULL_BEGIN

/**
 1. 首先需要给一个page/element 设置 _oid [pageId/elementId]:
 @code
 [EventTracingBuilder viewController:self pageId:@"_oid_Main"];
 [EventTracingBuilder view:self.view pageId:@"_oid_Main"];
 [EventTracingBuilder view:btn elementId:@"_oid_Btn"];
 @endcode
 
 2. 该节点需要设置一些节点属性；这个时候也可以顺便一起把业务参数设置好
 @code
 [btn et_build:^(id<EventTracingLogNodeBuilder>  _Nonnull builder) {
     builder.visibleEdgeInsets(UIEdgeInsetsMake(10, 10, 10, 10))
     .buildinEventLogDisableStrategy(ETNodeBuildinEventLogDisableStrategyClick)
     .params
     .set(@"xxx", @"xxx");
 }];
 @endcode
 
 3. 如果不需要设置节点属性，直接给该node节点设置业务参数:
 @code
 [btn et_build:^(id<EventTracingLogNodeBuilder>  _Nonnull builder) {
    builder.params.set(@"key", @"value");
 }];
@endcode
 
 4. 【！！推荐】也可以在设置 _oid 的同时就设置好一些节点自身的节点属性 + 不变参数
 
 @code
 [[EventTracingBuilder viewController:self pageId:@"_oid_Main"] build:^(id<EventTracingLogNodeBuilder>  _Nonnull builder) {
     builder.visibleEdgeInsets(UIEdgeInsetsMake(10, 10, 10, 10))
     .buildinEventLogDisableStrategy(ETNodeBuildinEventLogDisableStrategyClick);
     .params
     .set(@"key", @"value");
 }];
 
 [[EventTracingBuilder viewController:homeVC pageId:@"_oid_Home"] build:^(id<EventTracingLogNodeBuilder>  _Nonnull builder) {
    builder.params.set(@"key", @"value");
 }];
 @endcode
 
 5. 自定义事件
 @code
 [EventTracingBuilder logWithEvent:^(id<EventTracingLogNodeEventActionBuilder>  _Nonnull builder) {
     builder.useForRefer().ec()
     .set(@"key", @"value");
 }];
 @endcode
 
 6. 动态参数 (callback形式)
 @code
 - (void)et_makeDynamicParams:(id<EventTracingLogNodeParamsBuilder>)builder {
     builder.cid(@"xxx").set(@"xxx", @"xxx");
 }
 @endcode
 
 7. cid, ctype, ctraceid
 @code
 [[EventTracingBuilder viewController:self pageId:@"Home"] build:^(id<EventTracingLogNodeBuilder>  _Nonnull builder) {
     builder
     .params
     .pushContent().song(@"cid_xxx").ctraceid(@"ctraceid_xxx").ctrp(@"ctrp_xxx").pop()                              // song 类型
     .pushContent().playlist(@"cid_xxx").ctraceid(@"ctraceid_xxx").ctrp(@"ctrp_xxx").pop()                          // playlist 类型
     .pushContentWithBlock(^(id<EventTracingLogNodeParamContentIdBuilder>  _Nonnull content) {                      // block形式: 自定义类型
         content.cidtype(@"cid_xxx", @"ctype_custom").ctraceid(@"ctraceid_xxx").ctrp(@"ctrp_xxx");
     })
     .set(@"xxx", @"xxx");
 }];
 @endcode
 */

@protocol EventTracingLogNodeParamsBuilder;
@protocol EventTracingLogNodeParamContentIdBuilder <NSObject>

/// MARK: 格式如下
// s_cid_ # type, s_ctype_# type, s_ctraceid_# type, s_ctrp_# type, s_calg_# type
// 其中 type 是纯小写
// 对象标准私参: cid, ctype, ctraceid, ctrp; 会参与 _scm 的生成
@property(nonatomic, readonly) id<EventTracingLogNodeParamContentIdBuilder> (^user)(NSString *_Nullable value);                 // s_cid_user, s_ctype_user, s_ctraceid_user, s_ctrp_user
@property(nonatomic, readonly) id<EventTracingLogNodeParamContentIdBuilder> (^playlist)(NSString *_Nullable value);
@property(nonatomic, readonly) id<EventTracingLogNodeParamContentIdBuilder> (^song)(NSString *_Nullable value);

@property(nonatomic, readonly) id<EventTracingLogNodeParamContentIdBuilder> (^cidtype)(NSString *cid, NSString *ctype);         // s_cid_# ctype #, s_ctype_# ctype, s_ctraceid_# ctype
@property(nonatomic, readonly) id<EventTracingLogNodeParamContentIdBuilder> (^ctraceid)(NSString *_Nullable traceid);           // s_ctraceid_# ctype
@property(nonatomic, readonly) id<EventTracingLogNodeParamContentIdBuilder> (^ctrp)(NSString *_Nullable trp);                   // s_ctrp_# ctype

@property (nonatomic, readonly) id<EventTracingLogNodeParamsBuilder> (^pop)(void);
@end

/// MARK: 总共有三种参数: `对象参数`, `事件参数`, `对象&&事件参数`
/// 1. 对象参数: 参数属于仅仅跟对象有关，跟是什么事件无关; 参数在json中的位置: _elist的对象中;
/// 2. 事件参数: 是事件级别的参数，跟对象无关; 参数在json中的位置: 在json最外层，跟 _eventcode 一个层级;
/// 3. 对象&&事件参数: 指一个事件发生在一个对象上所特有的参数; 参数在json中的位置: _elist的对象中;
@protocol EventTracingLogNodeParamsBuilder <NSObject>
// 万能
@property(nonatomic, readonly) id<EventTracingLogNodeParamsBuilder>(^addParams)(NSDictionary<NSString *, NSString *> *_Nullable json);
@property(nonatomic, readonly) id<EventTracingLogNodeParamsBuilder>(^set)(NSString *key, NSString *_Nullable value);

// cid
@property(nonatomic, readonly) id<EventTracingLogNodeParamsBuilder> (^cid)(NSString *_Nullable decryptedValue);
@property(nonatomic, readonly) id<EventTracingLogNodeParamsBuilder> (^ctype)(NSString *_Nullable value);
@property(nonatomic, readonly) id<EventTracingLogNodeParamsBuilder> (^ctraceid)(NSString *_Nullable value);
@property(nonatomic, readonly) id<EventTracingLogNodeParamsBuilder> (^ctrp)(NSString *_Nullable value);

// 会参与 _spm 的生成
// cell复用的时候，需要业务方设置
// 同时设置了
@property(nonatomic, readonly) id<EventTracingLogNodeParamsBuilder> (^position)(NSUInteger value);

// content: cid, ctype, ctraceid, ctrp
// 重点: cid, ctype, ctraceid, ctrp 组成scm的三个要素，并且参与refer的构建
@property(nonatomic, readonly) id<EventTracingLogNodeParamContentIdBuilder> (^pushContent)(void);
@property(nonatomic, readonly) id<EventTracingLogNodeParamsBuilder> (^pushContentWithBlock)(void (^NS_NOESCAPE block)(id<EventTracingLogNodeParamContentIdBuilder> content));

// basic
@property(nonatomic, readonly) id<EventTracingLogNodeParamsBuilder> (^device)(NSString *_Nullable value);
@property(nonatomic, readonly) id<EventTracingLogNodeParamsBuilder> (^resolution)(NSString *_Nullable value);
@property(nonatomic, readonly) id<EventTracingLogNodeParamsBuilder> (^carrier)(NSString *_Nullable value);
@property(nonatomic, readonly) id<EventTracingLogNodeParamsBuilder> (^network)(NSString *_Nullable value);
@property(nonatomic, readonly) id<EventTracingLogNodeParamsBuilder> (^code)(NSString *_Nullable value);
@property(nonatomic, readonly) id<EventTracingLogNodeParamsBuilder> (^toid)(NSString *_Nullable value);

// 常用
@property(nonatomic, readonly) id<EventTracingLogNodeParamsBuilder> (^module)(NSString *_Nullable value);
@property(nonatomic, readonly) id<EventTracingLogNodeParamsBuilder> (^title)(NSString *_Nullable value);
@property(nonatomic, readonly) id<EventTracingLogNodeParamsBuilder> (^subtitle)(NSString *_Nullable value);
@property(nonatomic, readonly) id<EventTracingLogNodeParamsBuilder> (^label)(NSString *_Nullable value);
@property(nonatomic, readonly) id<EventTracingLogNodeParamsBuilder> (^url)(NSString *_Nullable value);
@property(nonatomic, readonly) id<EventTracingLogNodeParamsBuilder> (^status)(NSString *_Nullable value);
@property(nonatomic, readonly) id<EventTracingLogNodeParamsBuilder> (^name)(NSString *_Nullable value);
@property(nonatomic, readonly) id<EventTracingLogNodeParamsBuilder> (^time_S)(NSTimeInterval value);                    // 对应的key: s_time; 单位: s; 值内部转化为 => ms
@property(nonatomic, readonly) id<EventTracingLogNodeParamsBuilder> (^time_MS)(NSTimeInterval value);                   // 对应的key: s_time; 单位: ms;
@property(nonatomic, readonly) id<EventTracingLogNodeParamsBuilder> (^timeFromStartDate)(NSDate *startDate);            // 内部计算从 startDate 到当前时间的时间差，相当于 .time_S([NSDate date] - startDate)

@property(nonatomic, readonly) NSDictionary<NSString *, NSString *> *params;
@end

/// MARK: 虚拟父节点的 builder
@protocol EventTracingLogVirtualParentNodeBuilder;
typedef void(^ET_BuildVirtualParentBlock)(id<EventTracingLogVirtualParentNodeBuilder> virtualBuilder);
@protocol EventTracingLogVirtualParentNodeBuilder <NSObject>
// 内建埋点策略: impress
// 针对虚拟父节点，click无意义，也不会打
@property(nonatomic, readonly) id<EventTracingLogVirtualParentNodeBuilder> (^buildinEventLogDisableStrategy)(ETNodeBuildinEventLogDisableStrategy strategy);
@property(nonatomic, readonly) id<EventTracingLogVirtualParentNodeBuilder> (^buildinEventLogDisableImpress)(void);
@property(nonatomic, readonly) id<EventTracingLogVirtualParentNodeBuilder> (^buildinEventLogDisableImpressend)(BOOL disable);
@property(nonatomic, readonly) id<EventTracingLogVirtualParentNodeBuilder> (^buildinEventLogDisableAll)(void);

@property(nonatomic, readonly) id<EventTracingLogNodeParamsBuilder> params;
@end

/// MARK: 普通节点的 builder
typedef void(^ET_BuildParamsBlock)(id<EventTracingLogNodeParamsBuilder> params);
typedef void(^ET_BuildParamsCarryEventsBlock)(id<EventTracingLogNodeParamsBuilder> params, NSString *event);
@protocol EventTracingLogNodeBuilder <NSObject>
// 可见性
@property(nonatomic, readonly) id<EventTracingLogNodeBuilder> (^logicalVisible)(BOOL visible);
@property(nonatomic, readonly) id<EventTracingLogNodeBuilder> (^visibleEdgeInsets)(UIEdgeInsets insets);
@property(nonatomic, readonly) id<EventTracingLogNodeBuilder> (^visibleEdgeInsetsTop)(CGFloat insetsTop);
@property(nonatomic, readonly) id<EventTracingLogNodeBuilder> (^visibleEdgeInsetsLeft)(CGFloat insetsLeft);
@property(nonatomic, readonly) id<EventTracingLogNodeBuilder> (^visibleEdgeInsetsBottom)(CGFloat insetsBottom);
@property(nonatomic, readonly) id<EventTracingLogNodeBuilder> (^visibleEdgeInsetsRight)(CGFloat insetsRight);
@property(nonatomic, readonly) id<EventTracingLogNodeBuilder> (^visibleRectCalculateStrategy)(ETNodeVisibleRectCalculateStrategy strategy);   // default: ETNodeVisibleRectCalculateStrategyOnParentNode

/// MARK: 是否穿透父节点的可见区域，常跟`logicalParentSPM`一起用，用在需要将一个比较大的浮层，挂载到一个比较小的按钮上的场景
/// MARK: 相当于调用 visibleRectCalculateStrategy
/// MARK: YES => ETNodeVisibleRectCalculateStrategyPassthrough, NO => ETNodeVisibleRectCalculateStrategyOnParentNode
@property(nonatomic, readonly) id<EventTracingLogNodeBuilder> (^visiblePassthrough)(BOOL passthrough);

// 内建埋点策略: clck | impress
@property(nonatomic, readonly) id<EventTracingLogNodeBuilder> (^buildinEventLogDisableStrategy)(ETNodeBuildinEventLogDisableStrategy strategy);
@property(nonatomic, readonly) id<EventTracingLogNodeBuilder> (^buildinEventLogDisableClick)(void);
@property(nonatomic, readonly) id<EventTracingLogNodeBuilder> (^buildinEventLogDisableImpress)(void);
@property(nonatomic, readonly) id<EventTracingLogNodeBuilder> (^buildinEventLogDisableImpressend)(BOOL disable);
@property(nonatomic, readonly) id<EventTracingLogNodeBuilder> (^buildinEventLogDisableAll)(void);

// 主动 逻辑挂载 && 自动RootPage逻辑挂载
/// MARK: 主动逻辑挂载 && SPM形式逻辑挂载 && 自动逻辑挂载 三者不可同时存在，是互斥的关系
/// MARK: P0 => 主动逻辑挂载，可以挂载到一个非节点上（这里只是修改原始view的上下层级关系）
/// MARK: P1 => SPM形式逻辑挂载，通过指向一个SPM的字符串值，来将一个节点挂载到目标节点上（为了方便代码解耦）
/// MARK: P2 => 自动逻辑挂载，全局可用，目标节点是当前正在展示的 `根节点`
@property(nonatomic, readonly) id<EventTracingLogNodeBuilder> (^logicalParentViewController)(UIViewController * _Nullable viewController);
@property(nonatomic, readonly) id<EventTracingLogNodeBuilder> (^logicalParentView)(UIView * _Nullable view);
@property(nonatomic, readonly) id<EventTracingLogNodeBuilder> (^logicalParentSPM)(NSString * _Nullable spm);
@property(nonatomic, readonly) id<EventTracingLogNodeBuilder> (^autoMountOnCurrentRootPage)(BOOL mount);
@property(nonatomic, readonly) id<EventTracingLogNodeBuilder> (^autoMountOnCurrentRootPageWithPriority)(ETAutoMountRootPageQueuePriority priority);

/// MARK: `页面` 节点是否拥有 `遮挡` 能力，default: YES
// `遮挡`: 可以遮挡父节点名下添加顺序早于自己的其他节点; 遮挡不考虑多节点累加遮挡场景(比如a,b都是页面节点，这俩合起来才可以完整覆盖c节点，单独都不能完成覆盖，则构不成遮挡关系)
@property(nonatomic, readonly) id<EventTracingLogNodeBuilder> (^pageOcclusionEnable)(BOOL enable);

// virtual parent
@property(nonatomic, readonly) id<EventTracingLogNodeBuilder> (^virtualParent)(NSString *elementId, id identifier, ET_BuildVirtualParentBlock NS_NOESCAPE _Nullable builder);
// virtual page parent
@property(nonatomic, readonly) id<EventTracingLogNodeBuilder> (^virtualPageParent)(NSString *pageId, id identifier, ET_BuildVirtualParentBlock NS_NOESCAPE _Nullable builder);

// reuse
/// MARK: 建议使用 model 对象作为参数（则内部使用 data 的内存地址参与生成 identifier）
/// MARK: 如果是使用 model 对象，则尝试通过 `-[NSObject ET_passData]` 获取 id<NENetworkingEventTracingPassData>, 并且取出 traceId 作为 `s_ctraceid` 塞入到对象参数中
/// MARK: 如果业务侧已经先行设置了 `s_ctraceid` 值，则不覆盖
@property(nonatomic, readonly) id<EventTracingLogNodeBuilder> (^bindDataForReuse)(id data);
@property(nonatomic, readonly) id<EventTracingLogNodeBuilder> (^bindDataForReuseWithAutoClassifyIdAppend)(NSString *identifier);

// refer
@property(nonatomic, readonly) id<EventTracingLogNodeBuilder> (^referToid)(NSString *toid);
// 该节点是否忽略refer
// 如果忽略refer，则该节点的事件(比如 _ec 等)不再参与链路追踪，不会在 _pgrefer, _psrefer, eventrefer(_addrefer), _hsrefer, _multirefers 等体现出来，也不会参与 undefined-xpath
// 注意，该配置是级联的，如果某一个父节点(YES), 则其所有子节点都相当于是(YES)
// default: NO
@property(nonatomic, readonly) id<EventTracingLogNodeBuilder> (^ignoreReferCascade)(BOOL value);

/// MARK: 节点不参与 multirefer
@property(nonatomic, readonly) id<EventTracingLogNodeBuilder> (^doNotParticipateMultirefer)(BOOL value);

/// MARK: 子页面是否产生 pv refer，仅对 subpage 生效
@property(nonatomic, readonly) id<EventTracingLogNodeBuilder> (^enableSubPageProducePvRefer)(BOOL value);

/// MARK: 子页面是否消费 all refer，仅对 subpage 生效
@property(nonatomic, readonly) id<EventTracingLogNodeBuilder> (^enableSubPageConsumeAllRefer)(BOOL value);

/// MARK: 子页面是否消费 event refer（除了 subpage pv refer，含`ec`和`自定义事件`的 refer）
/// MARK: 仅对 subpage 生效
@property(nonatomic, readonly) id<EventTracingLogNodeBuilder> (^enableSubPageConsumeEventRefer)(BOOL value);

@property(nonatomic, readonly) id<EventTracingLogNodeParamsBuilder> params;
@property(nonatomic, readonly) id<EventTracingLogNodeParamsBuilder> emptyParams;

/// Block形式的参数添加，优先级最高
/// MARK: 使用时必须要注意，这里的 block 是会被 view 层面强持有，使用的时候，请合理使用 strong/weak
/// MARK: 这里的参数是 `对象参数` 或者 `对象&事件参数`，这两种类型的参数，位于节点内部，_elist或者_plist点内部
@property(nonatomic, readonly) id<EventTracingLogNodeBuilder> (^addParamsCallback)(ET_BuildParamsBlock _Nullable paramsBuilder);             // 纯 `对象参数`
@property(nonatomic, readonly) id<EventTracingLogNodeBuilder> (^addClickParamsCallback)(ET_BuildParamsBlock _Nullable paramsBuilder);        // `对象&事件参数`
@property(nonatomic, readonly) id<EventTracingLogNodeBuilder> (^addLongClickParamsCallback)(ET_BuildParamsBlock _Nullable paramsBuilder);    // `对象&事件参数`
@property(nonatomic, readonly) id<EventTracingLogNodeBuilder> (^addParamsCallbackForEvent)(NSString *event, ET_BuildParamsBlock _Nullable paramsBuilder);    // `对象&事件参数`
@property(nonatomic, readonly) id<EventTracingLogNodeBuilder> (^addParamsCallbackForEvents)(NSArray<NSString *> *events, ET_BuildParamsBlock _Nullable paramsBuilder);   // 对象&事件参数
@property(nonatomic, readonly) id<EventTracingLogNodeBuilder> (^addParamsCarryEventCallbackForEvents)(NSArray<NSString *> *events, ET_BuildParamsCarryEventsBlock _Nullable paramsBuilder); // 纯 `对象参数`，携带事件回调

@end

@protocol EventTracingLogManuallyEventActionBuilder <NSObject>

@property(nonatomic, readonly) id<EventTracingLogNodeParamsBuilder> (^pv)(void);                // ET_EVENT_ID_P_VIEW: _pv
@property(nonatomic, readonly) id<EventTracingLogNodeParamsBuilder> (^pd)(void);                // ET_EVENT_ID_P_VIEW_END: _pvd
@property(nonatomic, readonly) id<EventTracingLogNodeParamsBuilder> (^ev)(void);                // ET_EVENT_ID_E_VIEW: _ev
@property(nonatomic, readonly) id<EventTracingLogNodeParamsBuilder> (^ed)(void);                // ET_EVENT_ID_E_VIEW_END: _evd

@property(nonatomic, readonly) id<EventTracingLogNodeParamsBuilder> (^ec)(void);                // ET_EVENT_ID_E_CLCK: _ec
@property(nonatomic, readonly) id<EventTracingLogNodeParamsBuilder> (^elc)(void);               // ET_EVENT_ID_E_LONG_CLCK: _lec
@property(nonatomic, readonly) id<EventTracingLogNodeParamsBuilder> (^es)(void);                // ET_EVENT_ID_E_SLIDE: _es
@property(nonatomic, readonly) id<EventTracingLogNodeParamsBuilder> (^pgf)(void);               // ET_EVENT_ID_P_REFRESH: _pgf
@property(nonatomic, readonly) id<EventTracingLogNodeParamsBuilder> (^plv)(void);               // ET_EVENT_ID_PLV: _plv
@property(nonatomic, readonly) id<EventTracingLogNodeParamsBuilder> (^pld)(void);               // ET_EVENT_ID_PLD: _pld

@property(nonatomic, readonly) id<EventTracingLogNodeParamsBuilder> (^event)(NSString *event);

@end

@protocol EventTracingLogManuallyUseForReferEventActionBuilder <NSObject>

@property(nonatomic, readonly) id<EventTracingLogManuallyUseForReferEventActionBuilder> (^event)(NSString *event);
@property(nonatomic, readonly) id<EventTracingLogManuallyUseForReferEventActionBuilder> (^referSPM)(NSString *spm);
@property(nonatomic, readonly) id<EventTracingLogManuallyUseForReferEventActionBuilder> (^referSCM)(NSString *scm);

@property(nonatomic, readonly) id<EventTracingLogNodeParamsBuilder> (^referType)(NSString *type);

@end

@protocol EventTracingLogNodeEventActionBuilder <EventTracingLogManuallyEventActionBuilder>

@property(nonatomic, readonly) id<EventTracingLogNodeEventActionBuilder> (^increaseActseq)(BOOL value);
@property(nonatomic, readonly) id<EventTracingLogNodeEventActionBuilder> (^useForRefer)(void);

@end

typedef void(^ET_BuildBlock)(id<EventTracingLogNodeBuilder> builder);
typedef void(^ET_BuildManuallyEventActionBlock)(id<EventTracingLogManuallyEventActionBuilder> builder);
typedef void(^ET_BuildManuallyUseForReferEventActionBlock)(id<EventTracingLogManuallyUseForReferEventActionBuilder> builder);
typedef void(^ET_BuildEventActionBlock)(id<EventTracingLogNodeEventActionBuilder> builder);

@protocol EventTracingLogBuilder <NSObject>
- (void)build:(ET_BuildBlock NS_NOESCAPE)block;
@end

@interface EventTracingBuilder : NSObject

+ (id<EventTracingLogBuilder>)view:(UIView *)view pageId:(NSString *)pageId;
/// MARK: 重要！！！
/// MARK: 该方法调用的时候，`viewController.isViewDidLoad` 需要位YES，即应该晚于viewDidLoad方法之后调用 (该方法内部会调用 -[UIViewController view] 方法，过早调用可能会对业务逻辑有影响)
+ (id<EventTracingLogBuilder>)viewController:(UIViewController *)viewController pageId:(NSString *)pageId;
+ (id<EventTracingLogBuilder>)view:(UIView *)view elementId:(NSString *)elementId;

+ (void)batchBuildParams:(ET_BuildBlock NS_NOESCAPE)block variableViews:(UIView *)view, ... NS_REQUIRES_NIL_TERMINATION;
+ (void)batchBuildViews:(NSArray<UIView *> *)views params:(ET_BuildBlock NS_NOESCAPE)block;

// 业务方自定义事件 构建
// 跟view/VTree有关，是VTree结构化的日志格式
/// MARK: 自定义事件埋点，这里带的参数，是纯`事件参数`，该类型参数跟 _elist, _plist 平级
+ (void)logWithView:(UIView *)view event:(ET_BuildEventActionBlock NS_NOESCAPE)block;

// 业务方自定义事件 构建
// 跟view/VTree无关，埋点格式不是VTree结构化的
+ (void)logManuallyWithBuilder:(ET_BuildManuallyEventActionBlock NS_NOESCAPE)block;

// 业务方自定义事件 构建
// 跟view/VTree无关，但是该埋点可参与链路追踪
+ (void)logManuallyUseForReferWithBuilder:(ET_BuildManuallyUseForReferEventActionBlock NS_NOESCAPE)block;

+ (id<EventTracingLogNodeParamsBuilder>)emptyParamsBuilder;

@end

// 非节点设置虚拟父节点 => 相当于: 该 View 名下所有最上层node节点都设置该虚拟父节点
@interface EventTracingBuilder (VirtualParent)
+ (void)buildVirtualParentNodeForView:(UIView *)view
                            elementId:(NSString *)elementId
                           identifier:(id)identifier
                                block:(ET_BuildVirtualParentBlock NS_NOESCAPE _Nullable)block;

+ (void)buildVirtualParentNodeForView:(UIView *)view
                               pageId:(NSString *)pageId
                           identifier:(id)identifier
                                block:(ET_BuildVirtualParentBlock NS_NOESCAPE _Nullable)block;
@end

/// MARK: 构建 scm
@protocol EventTracingLogSCMComponentBuilder;
@protocol EventTracingLogSCMBuilder <NSObject>
@property(nonatomic, readonly) id<EventTracingLogSCMComponentBuilder> (^pushComponent)(void);
@end

@protocol EventTracingLogSCMComponentBuilder <NSObject>
@property(nonatomic, readonly) id<EventTracingLogSCMComponentBuilder> (^cid)(NSString *_Nullable cid);
@property(nonatomic, readonly) id<EventTracingLogSCMComponentBuilder> (^ctype)(NSString *_Nullable ctype);
@property(nonatomic, readonly) id<EventTracingLogSCMComponentBuilder> (^ctraceid)(NSString *_Nullable traceid);
@property(nonatomic, readonly) id<EventTracingLogSCMComponentBuilder> (^ctrp)(NSString *_Nullable trp);

@property (nonatomic, readonly) id<EventTracingLogSCMBuilder> (^pop)(void);
@end

/**
 示例
 
 BOOL er = NO;
 NSString *scm = [EventTracingBuilder buildSCM:^(id<EventTracingLogSCMBuilder>  _Nonnull builder) {
     builder
         .pushComponent().cid(@"http://www.baidu.com").ctype(@"ctype").pop()
         .pushComponent().cid(@"cid").pop();
 } er:&er];
 */
typedef void(^ET_BuildSCMBlock)(id<EventTracingLogSCMBuilder> builder);
typedef void(^ET_BuildSCMComponentBlock)(id<EventTracingLogSCMComponentBuilder> builder);
@interface EventTracingBuilder (SCM)
+ (NSString *)buildSCM:(ET_BuildSCMBlock NS_NOESCAPE)builder;
+ (NSString *)buildSCM:(ET_BuildSCMBlock NS_NOESCAPE)builder er:(BOOL * _Nullable)er;
@end

@protocol EventTracingLogNodeBuilderProtocol <NSObject>
- (void)et_build:(ET_BuildBlock NS_NOESCAPE)block;
- (void)et_buildParams:(ET_BuildParamsBlock NS_NOESCAPE)block;
@end

@interface UIView (EventTracingBuilder) <EventTracingLogNodeBuilderProtocol>
@end

@interface UIViewController (EventTracingBuilder) <EventTracingLogNodeBuilderProtocol>
@end

// Dynamic Params
@protocol EvevntTracingLogNodeDynamicParamsBuilder <NSObject>
@optional
- (void)et_makeDynamicParams:(id <EventTracingLogNodeParamsBuilder>)builder;
@end

@interface UIView (EventTracingLogNodeDynsmicParams) <EvevntTracingLogNodeDynamicParamsBuilder>
@end
@interface UIViewController (EventTracingLogNodeDynsmicParams) <EvevntTracingLogNodeDynamicParamsBuilder>
@end


/*
 是否开启节点 oid 覆盖检查
 建议业务方在开发环境下开启
 ```
 #ifdef DEBUG
 NEBILogEnableNodeOidOverwriteCheck(true);
 #endif
 ```
 */
extern void EventTracingLogEnableNodeOidOverwriteCheck(bool enable);

/// MARK: 设置参数黑名单，比如在某个app内不可以使用某个参数
/// MARK: 典型 => 暂时阶段，曙光日志，在云音乐内不可以使用 `is_livelog` 参数，该参数是直播标识字段，如果使用了，会导致日志分流到了直播侧
/// MARK: 仅仅在非 appstore 包生效
@interface EventTracingBuilder (BlackListParamKey)

+ (void)addBlackListParamKey:(NSString *)key errorString:(NSString *)errorString;
+ (NSArray<NSString *> *)allBlackListParamKeys;

+ (void)checkForBlackListParamKeys:(NSArray<NSString *> *)paramKeys;

@end

NS_ASSUME_NONNULL_END
