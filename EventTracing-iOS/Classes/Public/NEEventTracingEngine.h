//
//  NEEventTracing.h
//  BlocksKit
//
//  Created by dl on 2021/2/4.
//

#import <Foundation/Foundation.h>
#import "NEEventTracingContext.h"
#import "NEEventTracingEventActionConfig.h"
#import "NEEventTracingAppLifecycleProcotol.h"

NS_ASSUME_NONNULL_BEGIN

@interface NEEventTracingEngine : NSObject <NEEventTracingAppLifecycleProcotol>

/// 是否启动
@property(nonatomic, assign, readonly) BOOL started;

/// 是否启用 列表滚动过程中曝光
/// Default: NO
@property(nonatomic, assign, readonly) BOOL incrementalVTreeWhenScrollEnable;
@property(nonatomic, strong, readonly) id<NEEventTracingContext> context;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
+ (instancetype)new UNAVAILABLE_ATTRIBUTE;
+ (instancetype)sharedInstance;

- (void)startWithContextBuilder:(void(^NS_NOESCAPE)(id<NEEventTracingContextBuilder> builder))block;
- (void)stop;

@end

@interface NEEventTracingEngine (Traverse)

/// 打一个遍历标识，在合适的时候会进行遍历
- (void)traverse;

/// 开启 / 关闭 列表滚动中增量VTree
- (void)enableIncrementalVTreeWhenScroll;
- (void)disableIncrementalVTreeWhenScroll;

@end

@interface NEEventTracingEngine (ActionSimple)

/*!
 直接打事件点，并且该事件点跟VTree无关，仅仅对接SDK内部的公参
 这里的参数是 `事件参数`
 
 @param event 事件的名称
 @param params 参数
 */
- (void)logSimplyWithEvent:(NSString *)event params:(NSDictionary * _Nullable)params;

@end

@interface NEEventTracingEngine (ReferEventWithNode)

/// 自定义事件，不挂载节点，也可以参与链路追踪（使用context级别的 actseq & pgstep ）
/// - Parameters:
///   - event: 埋点事件，必填
///   - referType: refer type 必填
///   - params: 参数
- (void)logReferEvent:(NSString *)event
            referType:(NSString *)referType
               params:(NSDictionary * _Nullable)params;

/// 自定义事件，不挂载节点，也可以参与链路追踪（使用context级别的 actseq & pgstep ）
/// - Parameters:
///   - event: 埋点事件，必填
///   - referType: refer type 必填
///   - spm: spm 可选，如果有值，会参与到refer的构建中
///   - scm: scm 可选，如果有值，会参与到refer的构建中（并且scm会判断是否含有特殊字符，如果某一快有特殊字符，会对其进行url_encode加密）
///   - params: 参数
- (void)logReferEvent:(NSString *)event
            referType:(NSString *)referType
             referSPM:(NSString * _Nullable)spm
             referSCM:(NSString * _Nullable)scm
               params:(NSDictionary * _Nullable)params;

@end

@interface NEEventTracingEngine (ActionStructured)

/*!
 业务方可以自定义事件
 @param event 事件的名称
 @param view 被绑定的view
 
 @discussion 业务方的自定义事件，应该绑定在一个view上(该view是一个节点)
 @discussion 如果自定义事件埋点早于VTree构建(`此时该view没有关联的node`)，并且该view可见，则会 sync 形式构建一次VTree
 @discussion view可见 => `view.window != nil && view.hidden != no && view.alpha > CGFLOAT_MIN`
 */
- (void)logWithEvent:(NSString *)event view:(UIView *)view;

/*!
 业务方可以自定义事件
 这里的参数是 `事件参数`
 
 @param event 事件的名称
 @param view 被绑定的view
 @param params 额外一些params，这里可以临时添加一次性的参数
 
 @discussion 业务方的自定义事件，应该绑定在一个view上(该view是一个节点)
 @discussion 如果自定义事件埋点早于VTree构建(`此时该view没有关联的node`)，并且该view可见，则会 sync 形式构建一次VTree
 @discussion view可见 => `view.window != nil && view.hidden != no && view.alpha > CGFLOAT_MIN`
 */
- (void)logWithEvent:(NSString *)event
                view:(UIView *)view
              params:(NSDictionary<NSString *, NSString *> * _Nullable)params;

/*!
 业务方可以自定义事件
 这里的参数是 `事件参数`
 
 @param event 事件的名称
 @param view 被绑定的view
 @param params 额外一些params，这里可以临时添加一次性的参数
 @param block 设置自定义事件的一些特征: 比如该事件参与actseq的自增，用于链路追踪, 或者在本次自定义事件中
 
 @discussion 业务方的自定义事件，应该绑定在一个view上(该view是一个节点)
 */
- (void)logWithEvent:(NSString *)event
                view:(UIView *)view
              params:(NSDictionary<NSString *, NSString *> * _Nullable)params
         eventAction:(void(^ NS_NOESCAPE _Nullable)(NEEventTracingEventActionConfig *config))block;
@end

@interface NEEventTracingEngine (MergeLogForH5)

/*!
 业务方可以自定义事件
 这里的参数是 `事件参数`
 
 @param event 事件的名称
 @param baseNode base 节点
 @param elist 在 base 节点之上的elist
 @param plist 在 base 节点之上的plist
 @param params 额外一些params，这里可以临时添加一次性的参数
 @param block 设置自定义事件的一些特征: 比如该事件参与actseq的自增，用于链路追踪, 或者在本次自定义事件中
 
 @discussion 典型使用场景，跟站内H5结合使用，H5内有局部虚拟树，根native树结合起来使用
 */
- (void)logWithEvent:(NSString *)event
            baseNode:(NEEventTracingVTreeNode *)baseNode
               elist:(NSArray<NSDictionary<NSString *, NSString *> *> * _Nullable)elist
               plist:(NSArray<NSDictionary<NSString *, NSString *> *> * _Nullable)plist
         positionKey:(NSString *)positionKey
              params:(NSDictionary<NSString *, NSString *> * _Nullable)params
         eventAction:(void(^ NS_NOESCAPE _Nullable)(NEEventTracingEventActionConfig *config))block;

@end

@interface NEEventTracingEngine (Params)

/// MARK: 只为本次 active 所使用的公参列表
/// MARK: 典型使用场景，dp 方式打开app，则应该本次app出于active周期内，公参都包含这里的参数
- (void)addCurrentActivePublicParams:(NSDictionary<NSString *, NSString *> *)publicParams;
/// MARK: key => g_dprefer
- (void)addCurrentActiveDeeplinkReferPublicParam:(NSString *)value;

// for event == nil
- (NSDictionary *)publicParamsForView:(UIView * _Nullable)view;
- (NSDictionary *)publicParamsForViewController:(UIViewController * _Nullable)viewController;

// for event == nil
- (NSDictionary *)fulllyParamsForView:(UIView * _Nullable)view;
- (NSDictionary *)fulllyParamsForViewController:(UIViewController * _Nullable)viewController;

@end

// Engine Add/Remove VTreeObserver
@interface NEEventTracingEngine (VTreeObserver)
- (void)addVTreeObserver:(id<NEEventTracingVTreeObserver>)observer;
- (void)removeVTreeObserver:(id<NEEventTracingVTreeObserver>)observer;
@end

NS_ASSUME_NONNULL_END
