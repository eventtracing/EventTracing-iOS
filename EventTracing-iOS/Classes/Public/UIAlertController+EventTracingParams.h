//
//  UIAlertController+EventTracingParams.h
//  NEEventTracing
//
//  Created by dl on 2021/4/25.
//

#import <UIKit/UIKit.h>
#import "NEEventTracingDefines.h"
#import "NEEventTracingEventActionConfig.h"

NS_ASSUME_NONNULL_BEGIN

/// MARK: UIAlertControler 中的点击事件，默认 useForRefer == NO

/// 对 `UIAlertController` 层面做一些特制的扩展
@interface UIAlertAction (EventTracingParams)

/// Alert 上按钮的 oid
@property(nonatomic, copy, readonly) NSString *ne_et_elementId;

/// Alert 按钮的position
@property(nonatomic, assign, readonly) NSUInteger ne_et_position;

/// 判断该 Alert 按钮是否是一个 元素节点
@property(nonatomic, assign, readonly) BOOL ne_et_isElement;

/// 当把该 AlertAction 应用到 AlertController 上时，会关联 `UIAlertController` 对象到这里
@property(nonatomic, weak, readonly) UIAlertController *ne_et_alertController;

/// 给按钮设置 元素oid
/// - Parameters:
///   - elementId: 元素 oid
///   - params: 按钮的 参数
- (void)ne_et_setElementId:(NSString *)elementId
                    params:(NSDictionary<NSString *, NSString *> * _Nullable)params;

/// 给按钮设置 元素 oid，同时指定position
/// - Parameters:
///   - elementId: 元素oid
///   - position: 位置信息
///   - params: 按钮的 参数
- (void)ne_et_setElementId:(NSString *)elementId
                  position:(NSUInteger)position
                    params:(NSDictionary<NSString *, NSString *> * _Nullable)params;

/// 给按钮设置 元素 oid，同时配置按钮点击时的一些特点
/// - Parameters:
///   - elementId: 元素 oid
///   - params: 按钮的 参数
///   - block: 按钮点击的一些配置
- (void)ne_et_setElementId:(NSString *)elementId
                    params:(NSDictionary<NSString *, NSString *> * _Nullable)params
               eventAction:(void(^ NS_NOESCAPE _Nullable)(NEEventTracingEventActionConfig *config))block;

/// 给按钮设置 元素 oid，同时指定position，以及配置按钮点击时的一些特点
/// - Parameters:
///   - elementId: 元素 oid
///   - position: 位置信息
///   - params: 按钮的 参数
///   - block: 按钮点击的一些配置
- (void)ne_et_setElementId:(NSString *)elementId
                  position:(NSUInteger)position
                    params:(NSDictionary<NSString *, NSString *> * _Nullable)params
               eventAction:(void(^ NS_NOESCAPE _Nullable)(NEEventTracingEventActionConfig *config))block;
@end

/// MARK: 默认 Alert 会自动挂载到当前根page节点，并且设置自动挂载优先级为`最高`，放置被遮挡
@interface UIAlertController (EventTracingParams)

/// MARK: 在UIView维度，该值是默认为NO，在Alert场景，该值默认是 YES
@property(nonatomic, assign, setter=ne_et_setIgnoreReferCascade:, getter=ne_et_isIgnoreReferCascade) BOOL ne_et_ignoreReferCascade;

// MARK: 在UIView维度，该值是默认为NO，在Alert场景，该值默认是 YES
@property(nonatomic, assign, setter=ne_et_setPsreferMute:, getter=ne_et_psreferMute) BOOL ne_et_psreferMute;

/// MARK: 子页面，pv曝光埋点，可以生成refer (refer_type == 'subpage_pv')
@property(nonatomic, assign, setter=ne_et_setSubpagePvToReferEnable:, getter=ne_et_subpagePvToReferEnable) BOOL ne_et_subpagePvToReferEnable;

/// MARK: 子页面消费refer的类型
/// 针对 rootpage，该值默认为 "ec|custom"
/// 针对 subpage，该值默认为 "none"
/// 所有可选值: all,  subpage_pv, ec, custom
/// 其中 custom 目前是除了 明确类型的 其他类型
/// all 是全部类型
/// subpage_pv 专指子页面曝光产生的refer
/// 不建议 root page 使用此 API
/// 不建议直接使用此API，建议使用下面3个API
///  - `ne_et_clearSubpageConsumeReferOption`              =>  清空设置
///  - `ne_et_makeSubpageConsumeAllRefer`         =>  适合首页 tab 子页面切换的场景
///  - `ne_et_makeSubpageConsumeEventRefer`     =>  适合浮层弹窗场景，比如首页 alert
@property(nonatomic, assign, setter=ne_et_setSubpageConsumeOption:, getter=ne_et_subpageConsumeOption) NEEventTracingPageReferConsumeOption ne_et_subpageConsumeOption;

/// MARK: 清空设置
- (void)ne_et_clearSubpageConsumeReferOption;
/// MARK: 适合首页 tab 子页面切换的场景，设置为`NEEventTracingPageReferConsumeOptionAll`
- (void)ne_et_makeSubpageConsumeAllRefer;
/// MARK: 适合浮层弹窗场景，比如首页 alert，设置为`NEEventTracingPageReferConsumeOptionExceptSubPagePV`
- (void)ne_et_makeSubpageConsumeEventRefer;

/// 给刚刚添加进来的 `UIAlertAction` 做节点配置
/// - Parameters:
///   - elementId: 元素 oid
///   - params: 按钮的 参数
- (void)ne_et_configLastestActionWithElementId:(NSString *)elementId
                                        params:(NSDictionary<NSString *, NSString *> * _Nullable)params;

/// 给刚刚添加进来的 `UIAlertAction` 做节点配置，同时指定按钮位置
/// - Parameters:
///   - elementId: 元素 oid
///   - position: 位置信息
///   - params: 按钮的 参数
- (void)ne_et_configLastestActionWithElementId:(NSString *)elementId
                                      position:(NSUInteger)position
                                        params:(NSDictionary<NSString *, NSString *> * _Nullable)params;

/// 给刚刚添加进来的 `UIAlertAction` 做节点配置，以及配置按钮点击时的一些特点
/// - Parameters:
///   - elementId: 元素 oid
///   - params: 按钮的 参数
///   - block: 按钮点击的一些配置
- (void)ne_et_configLastestActionWithElementId:(NSString *)elementId
                                        params:(NSDictionary<NSString *, NSString *> * _Nullable)params
                                   eventAction:(void(^ NS_NOESCAPE _Nullable)(NEEventTracingEventActionConfig *config))block;

/// 给按钮设置 元素 oid，同时指定position，以及配置按钮点击时的一些特点
/// - Parameters:
///   - elementId: 元素 oid
///   - position: 位置信息
///   - params: 按钮的 参数
///   - block: 按钮点击的一些配置
- (void)ne_et_configLastestActionWithElementId:(NSString *)elementId
                                      position:(NSUInteger)position
                                        params:(NSDictionary<NSString *, NSString *> * _Nullable)params
                                   eventAction:(void(^ NS_NOESCAPE _Nullable)(NEEventTracingEventActionConfig *config))block;
@end

NS_ASSUME_NONNULL_END
