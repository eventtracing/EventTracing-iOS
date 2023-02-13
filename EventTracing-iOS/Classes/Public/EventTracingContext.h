//
//  EventTracingContext.h
//  BlocksKit
//
//  Created by dl on 2021/2/4.
//

#import <Foundation/Foundation.h>
#import "EventTracingOutputFormatter.h"
#import "EventTracingEventOutputChannel.h"
#import "EventTracingInternalLogOutputInterface.h"
#import "EventTracingParamGuardConfiguration.h"
#import "EventTracingExceptionDelegate.h"
#import "EventTracingReferObserver.h"

#import "EventTracingVTree.h"
#import "UIView+EventTracing.h"

NS_ASSUME_NONNULL_BEGIN

/// 一些额外配置
@protocol EventTracingExtraConfigurationProvider <NSObject>
@optional

/// 在 action key 维度设置一个event是否都设置自增 actseq
- (NSArray<NSString *> *)needIncreaseActseqLogEvents;

/// 需要开始更新 _hsrefer 的oids列表
- (NSArray<NSString *> *)needStartHsreferOids;
@end

/// @brief 性能调试数据
/// @discussion Debug 使用，Release 模式建议关闭
/// @discussion Default NO
@protocol EventTracingContextVTreePerformanceObserver <NSObject>

/// 每次生成一个VTree，就会回调该方法，供开发期间统计一些性能数据
/// @param VTree VTree对象
/// @param tag 标识VTree是全量构建，还是增量构建，可取值: IncrementalVTree, TotalVTree
/// @param idx 构建的VTree的序号
/// @param cost 本次耗时
/// @param ave 平均耗时
/// @param min 最小耗时
/// @param max 最大耗时
- (void)didGenerateVTree:(EventTracingVTree *)VTree
                     tag:(NSString *)tag
                     idx:(NSUInteger)idx
                    cost:(NSTimeInterval)cost
                     ave:(NSTimeInterval)ave
                     min:(NSTimeInterval)min
                     max:(NSTimeInterval)max;
@end

/// MARK: VTree Observer
// 可以用来监听VTree的创建，以及VTree中node节点的曝光事件，以及非曝光的其他event事件
@protocol EventTracingContextVTreeObserverBuilder <NSObject>
// => ！！！弱持有
- (void)addVTreeObserver:(id<EventTracingVTreeObserver>)observer;
- (void)removeVTreeObserver:(id<EventTracingVTreeObserver>)observer;
- (void)removeAllVTreeObservers;

/// @brief 监控每一次 VTree 生成构建的耗时
/// @discussion Debug 使用，Release 模式建议关闭
/// => ！！！弱持有
- (void)setVTreePerformanceObserver:(id<EventTracingContextVTreePerformanceObserver>)VTreePerformanceObserver;
@end

/// MARK: refer Observer
@protocol EventTracingContextReferObserverBuilder <NSObject>
- (void)addReferObserver:(id<EventTracingReferObserver>)referObserver;
@end

/// MARK: Output formatter
@protocol EventTracingContextOutputFormatterBuilder <NSObject>
/// 注册一个 formatter，规范期间，建议大家直接使用内置的formatter
/// 默认使用 `EventTracingOutputFlattenFormatter`
/// => ！！！强持有
- (void)registeFormatter:(id<EventTracingOutputFormatter>)formatter;

/// 动态的公参
/// 每次日志产生，都会调用该 provider 的方法
- (void)registePublicDynamicParamsProvider:(id<EventTracingOutputPublicDynamicParamsProvider>)publicDynamicParamsProvider;

/// MARK: 这里注入静态公参
- (void)configStaticPublicParams:(NSDictionary<NSString *, NSString *> *)params;
- (void)removeStaticPublicParamForKey:(NSString *)key;

/// MARK: channel
// => ！！！强持有
- (void)addOutputChannel:(id<EventTracingEventOutputChannel>)outputChannel;
- (void)removeOutputChannel:(id<EventTracingEventOutputChannel>)outputChannel;
- (void)removeAllOutputChannels;

@optional
// refer _scm 部分node级别的的formatter
// => ！！！强持有
- (void)setupReferNodeSCMFormatter:(id<EventTracingReferNodeSCMFormatter>)referNodeSCMFormatter;
@end

/// 日志输出到 `OutputChannel` 之前，有一些修改或者监控的能力
@protocol EventTracingContextOutputParamsFilterBuilder <NSObject>
// => ！！！强持有
- (void)addParamsFilter:(id<EventTracingOutputParamsFilter>)paramsFilter;
- (void)removeParamsFilter:(id<EventTracingOutputParamsFilter>)paramsFilter;
- (void)removeAllParamsFilters;
@end

@protocol EventTracingContextBuilder
<
EventTracingContextVTreeObserverBuilder,
EventTracingContextReferObserverBuilder,
EventTracingContextOutputFormatterBuilder,
EventTracingContextOutputParamsFilterBuilder
>

/// @brief 一些额外的配置
@property(nonatomic, weak, nullable) id<EventTracingExtraConfigurationProvider> extraConfigurationProvider;

/// @brief SDK内部的一些日志输出到这里
/// @discussion Debug 使用，Release 模式建议关闭
@property(nonatomic, weak, nullable) id<EventTracingInternalLogOutputInterface> internalLogOutputInterface;

/// @brief 运行期间会有一些自我检测能力，遇到的一些异常，会在这里抛出来
/// @discussion Debug 使用，Release 模式建议关闭
@property(nonatomic, weak, nullable) id<EventTracingExceptionDelegate> exceptionInterface;

/// @brief 参数校验能力的正表达式配置
/// @discussion 在 `paramGuardEnable == YES` 时生效
@property(nonatomic, strong, readonly, nullable) id<EventTracingParamGuardConfiguration> paramGuardConfiguration;

// 滚动模式下，做局部数生成，配置 最小滑动间隔时长 && 最小滑动间隔距离
// default: 0.05f, CGPoint(5.f, 5.f)
- (void)configScrollThrottleTolerentDuration:(NSTimeInterval)tolerentDuration
                              tolerentOffset:(CGPoint)tolerentOffset;

/// @brief 是否在 refer 格式中，包含 `_dkey` 内容
/// @discussion refer 格式比较复杂，`option` 内容是位运算，开发期间为了方便理解内容，可以开启
/// @discussion Debug 使用，Release 模式建议关闭
/// @discussion Default NO
- (void)configReferFormatHasDKeyComponent:(BOOL)hasDKeyComponent;

/// @brief 开启参数校验 `守护` 能力, 可以指定一些规范，比如 `oid` 的命名规范等, 具体支持的列表见 `EventTracingParamGuardConfiguration`
/// @discussion Debug 使用，Release 模式建议关闭
/// @discussion Default NO
@property(nonatomic, assign, getter=isParamGuardEnable) BOOL paramGuardEnable;

/// @brief 针对 element, 可以选择是否开启自动打曝光结束点
/// @discussion 由于元素的曝光是巨量的，建议非必要，元素的曝光结束埋点就不要输出，按需来开启
/// @discussion Default YES
@property(nonatomic, assign, getter=isElementAutoImpressendEnable) BOOL elementAutoImpressendEnable;

/// @brief 如果一个节点，向上查找，找不到 page 节点，则可以选择配置这个场景是否允许打点
/// @discussion 由于建议大家做到 view 节点内聚的方式编写代码，但是对于一些比较常用的UI组件，可能会出现在任何页面（即使该页面还没有埋点），会造成一些莫名的 SPM 值埋点
/// @discussion Default YES
@property(nonatomic, assign, getter=isNoneventOutputWithoutPageNodeEnable) BOOL noneventOutputWithoutPageNodeEnable;

/// @brief UIViewController.view 的访问，如果 `isViewDidLoad==NO` 时，可以选择做一些 tip 提示
/// @discussion 不能仅仅因为给一个 `UIViewController` 设置 oid 而导致 `-[UIViewController viewDidLoad]` 的调用，这样可能是非预期的 vc 生命周期
/// @discussion Debug 使用，Release 模式建议关闭
/// @discussion default: `ETViewControllerDidNotLoadViewExceptionTipNone`
@property(nonatomic, assign) ETViewControllerDidNotLoadViewExceptionTip viewControllerDidNotLoadViewExceptionTip;
@end

/// SDK 的 context 信息
@protocol EventTracingContext <NSObject>

/// 是否已经开启
@property(nonatomic, assign, readonly) BOOL started;

/// 当前的 VTree 对象
@property(nonatomic, strong, readonly, nullable) EventTracingVTree *currentVTree;

/// @brief 滚动模式下，局部生成树，配置 最小滑动间隔时长
/// @discussion 滚动模式限流 => 滑动最小间隔时长 & 滑动最小间隔距离
/// @discussion default: 0.05f
@property(nonatomic, assign, readonly) NSTimeInterval throttleTolerentDuration;

/// @brief 滚动模式下，局部生成树，配置 最小滑动间隔距离
/// @discussion 滚动模式限流 => 滑动最小间隔时长 & 滑动最小间隔距离
/// @discussion CGPoint(5.f, 5.f)
@property(nonatomic, assign, readonly) CGPoint throttleTolerentOffset;

/// sessid && sidrefer
@property(nonatomic, copy, readonly) NSString *sessid;
@property(nonatomic, copy, readonly, nullable) NSString *sidrefer;

/// @brief 是否在 refer 格式中，包含 `_dkey` 内容
/// @discussion refer 格式比较复杂，`option` 内容是位运算，开发期间为了方便理解内容，可以开启
@property(nonatomic, assign, readonly) BOOL referFormatHasDKeyComponent;

/// 当前页面的页面深度: 页面曝光的时候，会+1
/// 每次冷启动，会从 `0` 开始
@property(nonatomic, assign, readonly) NSUInteger pgstep;

/// 不挂节点的自定义事件，参与链路追踪时，actseq的自增序列
@property(nonatomic, assign, readonly) NSUInteger actseq;

/// 当前的hsrefer值
@property(nonatomic, copy, readonly, nullable) NSString *hsrefer;

/// app 是否处于活跃状态
/// MARK: willEnterForeground 即修改为 YES
@property(nonatomic, assign, readonly, getter=isAppInActive) BOOL appInActive;

/// App 启动时间
@property(nonatomic, assign, readonly) NSTimeInterval appStartedTime;

/// 最后一次app进入前台的时间
@property(nonatomic, assign, readonly) NSTimeInterval appLastAtForegroundTime;

/// 最后一次app进入后台的时间
@property(nonatomic, assign, readonly) NSTimeInterval appLastEnterBackgroundTime;

@property(nonatomic, weak, readonly, nullable) id<EventTracingExtraConfigurationProvider> extraConfigurationProvider;

/// VTree 所有的 observers
/// 可以用来监听VTree的创建，以及VTree中node节点的曝光事件，以及非曝光的其他event事件
@property(nonatomic, strong, readonly, nullable) NSArray<id<EventTracingVTreeObserver>> *allVTreeObservers;

/// refer Observer
@property(nonatomic, strong, readonly, nullable) NSArray<id<EventTracingReferObserver>> *allReferObservers;

/// refer _scm 部分node级别的的formatter
@property(nonatomic, strong, readonly, nullable) id<EventTracingReferNodeSCMFormatter> referNodeSCMFormatter;

/// MARK: 以下均属于 Debug 能力
/// @brief 监控每一次 VTree 生成构建的耗时
/// @discussion Debug 使用，Release 模式建议关闭
@property(nonatomic, weak, readonly, nullable) id<EventTracingContextVTreePerformanceObserver> VTreePerformanceObserver;

/// @brief SDK内部的一些日志输出到这里
@property(nonatomic, weak, readonly, nullable) id<EventTracingInternalLogOutputInterface> internalLogOutputInterface;

/// @brief 运行期间会有一些自我检测能力，遇到的一些异常，会在这里抛出来
@property(nonatomic, weak, readonly, nullable) id<EventTracingExceptionDelegate> exceptionInterface;

/// @brief 开启参数校验 `守护` 能力, 可以指定一些规范，比如 `oid` 的命名规范等, 具体支持的列表见 `EventTracingParamGuardConfiguration`
@property(nonatomic, assign, readonly, getter=isParamGuardEnable) BOOL paramGuardEnable;

@property(nonatomic, assign, readonly, getter=isElementAutoImpressendEnable) BOOL elementAutoImpressendEnable;
@property(nonatomic, assign, readonly, getter=isNoneventOutputWithoutPageNodeEnable) BOOL noneventOutputWithoutPageNodeEnable;

/// @brief UIViewController.view 的访问，如果 `isViewDidLoad==NO` 时，可以选择做一些 tip 提示
/// @discussion 不能仅仅因为给一个 `UIViewController` 设置 oid 而导致 `-[UIViewController viewDidLoad]` 的调用，这样可能是非预期的 vc 生命周期
@property(nonatomic, assign, readonly) ETViewControllerDidNotLoadViewExceptionTip viewControllerDidNotLoadViewExceptionTip;

@end

NS_ASSUME_NONNULL_END
