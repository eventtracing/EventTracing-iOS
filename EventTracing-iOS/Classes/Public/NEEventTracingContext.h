//
//  NEEventTracingContext.h
//  BlocksKit
//
//  Created by dl on 2021/2/4.
//

#import <Foundation/Foundation.h>
#import "NEEventTracingOutputFormatter.h"
#import "NEEventTracingEventOutputChannel.h"
#import "NEEventTracingInternalLogOutputInterface.h"
#import "NEEventTracingParamGuardConfiguration.h"
#import "NEEventTracingExceptionDelegate.h"
#import "NEEventTracingReferObserver.h"

#import "NEEventTracingVTree.h"
#import "UIView+EventTracing.h"

NS_ASSUME_NONNULL_BEGIN

/// MARK: 一些额外配置
@protocol NEEventTracingExtraConfigurationProvider <NSObject>
@optional
/// 在 action key 维度设置一个event是否都设置自增 actseq
- (NSArray<NSString *> *)needIncreaseActseqLogEvents;

/// 需要开始更新 _hsrefer 的oids列表
- (NSArray<NSString *> *)needStartHsreferOids;

/// 需要打 _multiRefers 参数的事件，半角逗号隔开，前后不要有空格，默认 "_pv,_ec"
/// 示例："_pv,_ec,_ai"
- (NSString *)multiReferAppliedEventList;

/// multiRefers 的最大数量限制，默认 5
- (NSInteger)multiReferMaxItemCount;
@end

/// @brief 性能调试数据
/// @discussion Debug 使用，Release 模式建议关闭
/// @discussion Default NO
@protocol NEEventTracingContextVTreePerformanceObserver <NSObject>
/// 每次生成一个VTree，就会回调该方法，供开发期间统计一些性能数据
/// @param VTree VTree对象
/// @param tag 标识VTree是全量构建，还是增量构建，可取值: IncrementalVTree, TotalVTree
/// @param idx 构建的VTree的序号
/// @param cost 本次耗时
/// @param ave 平均耗时
/// @param min 最小耗时
/// @param max 最大耗时
- (void)didGenerateVTree:(NEEventTracingVTree *)VTree
                     tag:(NSString *)tag
                     idx:(NSUInteger)idx
                    cost:(NSTimeInterval)cost
                     ave:(NSTimeInterval)ave
                     min:(NSTimeInterval)min
                     max:(NSTimeInterval)max;
@end

/// MARK: VTree Observer
// 可以用来监听VTree的创建，以及VTree中node节点的曝光事件，以及非曝光的其他event事件
@protocol NEEventTracingContextVTreeObserverBuilder <NSObject>
// => ！！！弱持有
- (void)addVTreeObserver:(id<NEEventTracingVTreeObserver>)observer;
- (void)removeVTreeObserver:(id<NEEventTracingVTreeObserver>)observer;
- (void)removeAllVTreeObservers;

// => ！！！弱持有
- (void)setVTreePerformanceObserver:(id<NEEventTracingContextVTreePerformanceObserver>)VTreePerformanceObserver;
@end

/// MARK: refer Observer
@protocol NEEventTracingContextReferObserverBuilder <NSObject>
- (void)addReferObserver:(id<NEEventTracingReferObserver>)referObserver;
@end

/// MARK: Output formatter
@protocol NEEventTracingContextOutputFormatterBuilder <NSObject>
// 注册一个 formatter，规范期间，建议大家直接使用内置的formatter
// 默认启动的时候就启用了 NEEventTracingOutputFlattenFormatter
// => ！！！强持有
- (void)registeFormatter:(id<NEEventTracingOutputFormatter>)formatter;

/// MARK: 这里处理动态公参
- (void)registePublicDynamicParamsProvider:(id<NEEventTracingOutputPublicDynamicParamsProvider>)publicDynamicParamsProvider;

/// MARK: 这里注入静态公参
- (void)configStaticPublicParams:(NSDictionary<NSString *, NSString *> *)params;
- (void)removeStaticPublicParamForKey:(NSString *)key;

/// MARK: channel
// => ！！！强持有
- (void)addOutputChannel:(id<NEEventTracingEventOutputChannel>)outputChannel;
- (void)removeOutputChannel:(id<NEEventTracingEventOutputChannel>)outputChannel;
- (void)removeAllOutputChannels;

@optional
// refer _scm 部分node级别的的formatter
// => ！！！强持有
- (void)setupReferNodeSCMFormatter:(id<NEEventTracingReferNodeSCMFormatter>)referNodeSCMFormatter;
@end

/// MARK: 全局维度，对params进行过滤，加工
@protocol NEEventTracingContextOutputParamsFilterBuilder <NSObject>
// => ！！！强持有
- (void)addParamsFilter:(id<NEEventTracingOutputParamsFilter>)paramsFilter;
- (void)removeParamsFilter:(id<NEEventTracingOutputParamsFilter>)paramsFilter;
- (void)removeAllParamsFilters;
@end

@protocol NEEventTracingContextBuilder
<
NEEventTracingContextVTreeObserverBuilder,
NEEventTracingContextReferObserverBuilder,
NEEventTracingContextOutputFormatterBuilder,
NEEventTracingContextOutputParamsFilterBuilder
>

/// @brief 一些额外的配置
@property(nonatomic, weak, nullable) id<NEEventTracingExtraConfigurationProvider> extraConfigurationProvider;

/// @brief SDK内部的一些日志输出到这里
/// @discussion Debug 使用，Release 模式建议关闭
@property(nonatomic, weak, nullable) id<NEEventTracingInternalLogOutputInterface> internalLogOutputInterface;

/// @brief 运行期间会有一些自我检测能力，遇到的一些异常，会在这里抛出来
/// @discussion Debug 使用，Release 模式建议关闭
@property(nonatomic, weak, nullable) id<NEEventTracingExceptionDelegate> exceptionInterface;

/// @brief 参数校验能力的正表达式配置
/// @discussion 在 `paramGuardEnable == YES` 时生效
@property(nonatomic, strong, readonly, nullable) id<NEEventTracingParamGuardConfiguration> paramGuardConfiguration;

// 滚动模式下，做局部数生成，配置 最小滑动间隔时长 && 最小滑动间隔距离
// default: 0.05f, CGPoint(5.f, 5.f)
- (void)configScrollThrottleTolerentDuration:(NSTimeInterval)tolerentDuration
                              tolerentOffset:(CGPoint)tolerentOffset;

/// @brief 是否在 refer 格式中，包含 `_dkey` 内容
/// @discussion refer 格式比较复杂，`option` 内容是位运算，开发期间为了方便理解内容，可以开启
/// @discussion Debug 使用，Release 模式建议关闭
/// @discussion Default NO
- (void)configReferFormatHasDKeyComponent:(BOOL)hasDKeyComponent;

/// @brief 开启参数校验 `守护` 能力, 可以指定一些规范，比如 `oid` 的命名规范等, 具体支持的列表见 `NEEventTracingParamGuardConfiguration`
/// @discussion Debug 使用，Release 模式建议关闭
/// @discussion Default NO
@property(nonatomic, assign, getter=isParamGuardEnable) BOOL paramGuardEnable;

/// @brief 针对 element, 可以选择是否开启自动打曝光结束点
/// @discussion 由于元素的曝光是巨量的，建议非必要，元素的曝光结束埋点就不要输出，按需来开启
/// @discussion Default YES
@property(nonatomic, assign, getter=isNodeInfoValidationEnable) BOOL nodeInfoValidationEnable;

/// 针对 element, 可以选择是否开启自动打曝光结束点
/// defalut: YES
@property(nonatomic, assign, getter=isElementAutoImpressendEnable) BOOL elementAutoImpressendEnable;

/// @brief 如果一个节点，向上查找，找不到 page 节点，则可以选择配置这个场景是否允许打点
/// @discussion 由于建议大家做到 view 节点内聚的方式编写代码，但是对于一些比较常用的UI组件，可能会出现在任何页面（即使该页面还没有埋点），会造成一些莫名的 SPM 值埋点
/// @discussion Default YES
@property(nonatomic, assign, getter=isNoneventOutputWithoutPageNodeEnable) BOOL noneventOutputWithoutPageNodeEnable;

/// @brief UIViewController.view 的访问，如果 `isViewDidLoad==NO` 时，可以选择做一些 tip 提示
/// @discussion 不能仅仅因为给一个 `UIViewController` 设置 oid 而导致 `-[UIViewController viewDidLoad]` 的调用，这样可能是非预期的 vc 生命周期
/// @discussion Debug 使用，Release 模式建议关闭
/// @discussion default: `NEETViewControllerDidNotLoadViewExceptionTipNone`
@property(nonatomic, assign) NEETViewControllerDidNotLoadViewExceptionTip viewControllerDidNotLoadViewExceptionTip;

/// 参与 _multiRefers 链路追踪的事件类型，半角逗号隔开，前后不要有空格，默认 "_pv,_ec"
/// 示例："_pv,_ec,_ai"
@property(nonatomic, copy, readonly) NSString * multiReferAppliedEventList;

/// multirefer 最大数量，默认 5
@property(nonatomic, assign, readonly) NSInteger multiReferMaxItemCount;

/// - 如果为 YES 则表示使用外部的APP生命周期事件，此时需要外部在适当的时机调用下面的方法
/// ```
///  [[NEEventTracingEngine sharedInstance] appDidBecomeActive];
///  [[NEEventTracingEngine sharedInstance] appWillEnterForeground];
///  [[NEEventTracingEngine sharedInstance] appDidEnterBackground];
/// ```
/// - 默认：NO，使用 UIApplicationDidBecomeActiveNotification,UIApplicationWillEnterForegroundNotification,UIApplicationDidEnterBackgroundNotification
/// ```
///  UIApplicationDidBecomeActiveNotification      => [[NEEventTracingEngine sharedInstance] appDidBecomeActive];
///  UIApplicationWillEnterForegroundNotification  => [[NEEventTracingEngine sharedInstance] appWillEnterForeground];
///  UIApplicationDidEnterBackgroundNotification   => [[NEEventTracingEngine sharedInstance] appDidEnterBackground];
/// ```
@property(nonatomic, assign, getter=isUseCustomAppLifeCycle) BOOL useCustomAppLifeCycle;

/// 外部传入build 版本号
/// 默认使用 `[[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleVersionKey]`
@property (nonatomic, copy) NSString * appBuildVersion;

/// MARK: 已废弃
// 全局设定的最小曝光判定时间: 单位ms
- (void)configDeaultImpressIntervalThreshold:(NSTimeInterval)intervalThreshold DEPRECATED_MSG_ATTRIBUTE("已经废弃曝光限定");
// 已废弃，不再起作用
@property(nonatomic, assign, getter=isAutoMountParentWaringEnable) BOOL autoMountParentWaringEnable DEPRECATED_MSG_ATTRIBUTE("方法已废弃，不起任何作用");
@end

@protocol NEEventTracingContext <NSObject>

/// 是否已经开启
@property(nonatomic, assign, readonly) BOOL started;

/// 当前的 VTree 对象
@property(nonatomic, strong, readonly, nullable) NEEventTracingVTree *currentVTree;

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

@property(nonatomic, weak, readonly, nullable) id<NEEventTracingExtraConfigurationProvider> extraConfigurationProvider;

/// VTree 所有的 observers
/// 可以用来监听VTree的创建，以及VTree中node节点的曝光事件，以及非曝光的其他event事件
@property(nonatomic, strong, readonly, nullable) NSArray<id<NEEventTracingVTreeObserver>> *allVTreeObservers;

/// refer Observer
@property(nonatomic, strong, readonly, nullable) NSArray<id<NEEventTracingReferObserver>> *allReferObservers;

/// MARK: 以下均属于 Debug 能力
/// @brief 监控每一次 VTree 生成构建的耗时
/// @discussion Debug 使用，Release 模式建议关闭
@property(nonatomic, weak, readonly, nullable) id<NEEventTracingContextVTreePerformanceObserver> VTreePerformanceObserver;

/// @brief SDK内部的一些日志输出到这里
@property(nonatomic, weak, readonly, nullable) id<NEEventTracingInternalLogOutputInterface> internalLogOutputInterface;
@property(nonatomic, strong, readonly, nullable) id<NEEventTracingReferNodeSCMFormatter> referNodeSCMFormatter;

/// @brief 运行期间会有一些自我检测能力，遇到的一些异常，会在这里抛出来
@property(nonatomic, weak, readonly, nullable) id<NEEventTracingExceptionDelegate> exceptionInterface;

@property(nonatomic, strong, readonly, nullable) id<NEEventTracingParamGuardConfiguration> paramGuardConfiguration;

/// - 如果为 YES 则表示使用外部的APP生命周期事件，此时需要外部在适当的时机调用下面的方法
/// ```
///  [[EventTracingEngine sharedInstance] appDidBecomeActive];
///  [[EventTracingEngine sharedInstance] appWillEnterForeground];
///  [[EventTracingEngine sharedInstance] appDidEnterBackground];
/// ```
/// - 默认：NO，使用 UIApplicationDidBecomeActiveNotification,UIApplicationWillEnterForegroundNotification,UIApplicationDidEnterBackgroundNotification
/// ```
///  UIApplicationDidBecomeActiveNotification      => [[EventTracingEngine sharedInstance] appDidBecomeActive];
///  UIApplicationWillEnterForegroundNotification  => [[EventTracingEngine sharedInstance] appWillEnterForeground];
///  UIApplicationDidEnterBackgroundNotification   => [[EventTracingEngine sharedInstance] appDidEnterBackground];
/// ```
@property(nonatomic, assign, getter=isUseCustomAppLifeCycle) BOOL useCustomAppLifeCycle;

/// @brief 开启参数校验 `守护` 能力, 可以指定一些规范，比如 `oid` 的命名规范等, 具体支持的列表见 `EventTracingParamGuardConfiguration`
@property(nonatomic, assign, readonly, getter=isParamGuardEnable) BOOL paramGuardEnable;
@property(nonatomic, assign, readonly, getter=isNodeInfoValidationEnable) BOOL nodeInfoValidationEnable;
@property(nonatomic, assign, readonly, getter=isAutoMountParentWaringEnable) BOOL autoMountParentWaringEnable DEPRECATED_MSG_ATTRIBUTE("方法已废弃，不起任何作用");
@property(nonatomic, assign, readonly, getter=isElementAutoImpressendEnable) BOOL elementAutoImpressendEnable;
@property(nonatomic, assign, readonly, getter=isNoneventOutputWithoutPageNodeEnable) BOOL noneventOutputWithoutPageNodeEnable;

/// @brief UIViewController.view 的访问，如果 `isViewDidLoad==NO` 时，可以选择做一些 tip 提示
/// @discussion 不能仅仅因为给一个 `UIViewController` 设置 oid 而导致 `-[UIViewController viewDidLoad]` 的调用，这样可能是非预期的 vc 生命周期
@property(nonatomic, assign, readonly) NEETViewControllerDidNotLoadViewExceptionTip viewControllerDidNotLoadViewExceptionTip;

/// MARK: 已废弃
// 全局的 element 节点的最小曝光时长; Default: 0
@property(nonatomic, assign, readonly) NSTimeInterval defaultImpressIntervalThreshold DEPRECATED_MSG_ATTRIBUTE("已经废弃曝光限定");

@end

NS_ASSUME_NONNULL_END
