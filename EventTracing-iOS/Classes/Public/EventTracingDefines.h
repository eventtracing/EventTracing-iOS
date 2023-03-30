//
//  EventTracingDefines.h
//  EventTracing
//
//  Created by dl on 2021/2/25.
//

#import <Foundation/Foundation.h>

#ifndef EventTracingDEFINE_H
#define EventTracingDEFINE_H

// 内部 refer 队列保存的最大个数 => 5
extern NSUInteger EventTracingReferQueueMaxCount;

// 日志等级
typedef NS_ENUM(NSUInteger, ETLogLevel) {
    ETLogLevelVerbose,
    ETLogLevelDebug,
    ETLogLevelInfo,
    ETLogLevelSystem,
    ETLogLevelWarning,
    ETLogLevelError
};

// => "errmsg"
extern NSString * const EventTracingExeptionErrmsgKey;

// Node 节点不唯一
// Node 节点唯一: node.identifier + node.spm 组合唯一
extern NSInteger const EventTracingExceptionCodeNodeNotUnique;                         // 41

// Node 节点的 _spm 不唯一
// 这里尤其针对 cell 复用的时候，业务方漏掉了 position 的设置
extern NSInteger const EventTracingExceptionCodeNodeSPMNotUnique;                         // 42

// Node 逻辑挂载死循环
// A -> B, b -> C, c -> A, 造成死循环
extern NSInteger const EventTracingExceptionCodeLogicalMountEndlessLoop;               // 43

// event 命名不规范
// - 正则: `^(_)[a-z]+(?:[-_][a-z]+)*$`
// - 正则解读:
//     - [必选]以 `_` 开头
//     - [可选]后面是字符(小写) 或 下划线(_) 组合的字符串
//     - 下划线(_) 不能连续出现
//     - 下划线(_) 不能出现在末尾
// - 举例
//     - OK: _pv, _pf_d
//     - Failed: _Pv, _pv_, __pv
extern NSInteger const EventTracingExceptionEventKeyInvalid;                           // 51

// event key 跟内部预埋的event命名冲突
extern NSInteger const EventTracingExceptionEventKeyConflictWithEmbedded;              // 52

// 公参 命名不规范
// - 正则: `^(g_)[a-z][^\W_]+[^\W_]*(?:[-_][^\W_]+)*$`
// - 正则解读:
//     - [必选]以 `g_` 开头
//     - [必选]紧跟着一个 lowercase 字符, 并且该字符后必须跟着 英文字母或者数字
//     - [可选]再后面是字符(大小写) 或者 数字 或 中划线(-) 或 下划线(_) 组合的字符串
//     - 中划线(-) 下划线(_) 不能连续出现
//     - 中划线(-) 下划线(_) 不能出现在末尾
// - 举例
//     - OK: g_network, g_net-work, g_nET_worK
//     - Failed: g__network, g_s_network, g_Network, g_network_, g_network-
extern NSInteger const EventTracingExceptionPublicParamInvalid;                        // 53

// 用户级别的参数 命名不规范
// - 通用参数正则: `^s_[a-z][^\W_]+[^\W_]*(?:[-_][^\W_]+)*$`
// - 其他用户自定义参数正则: `^[a-z][^\W_]+[^\W_]*(?:[-_][^\W_]+)*$`
// - 正则解读:
//     - [通用参数必选]以 `s_` || `_` 开头, 其他单个字符开头+下划线均不可
//     - [必选]紧跟着一个 lowercase 字符, 并且该字符后必须跟着 英文字母或者数字
// - [可选]再后面是字符(大小写) 或者 数字 或 中划线(-) 或 下划线(_) 组合的字符串
//     - 中划线(-) 下划线(_) 不能连续出现
//     - 中划线(-) 下划线(_) 不能出现在末尾
// - 举例
//     - OK: s_id, s_cid_User, network, net-work, net_work
//     - Failed: s_Id, s_cid_, _network, r_network, net_work_
extern NSInteger const EventTracingExceptionUserParamInvalid;                          // 54

// param key 跟内部预埋的 param 命名冲突
extern NSInteger const EventTracingExceptionParamConflictWithEmbedded;                 // 55


/// MARK: `UIViewController.view` 的访问，当 `isViewDidLoad==NO` 时，需要作为 exception 抛出
typedef NS_ENUM(NSUInteger, ETViewControllerDidNotLoadViewExceptionTip) {
    ETViewControllerDidNotLoadViewExceptionTipNone,       // default
    ETViewControllerDidNotLoadViewExceptionTipAssert,     // 内部使用 Assert
    ETViewControllerDidNotLoadViewExceptionTipCostom      // 业务侧可使用 toast
};

typedef NS_ENUM(NSUInteger, ETExceptionLevel) {
    ETExceptionLevelWaring,
    ETExceptionLevelError,
    ETExceptionLevelFatal
};

typedef NS_ENUM(NSUInteger, ETNodeVisibleRectCalculateStrategy) {
    ETNodeVisibleRectCalculateStrategyOnParentNode = 0,             // default: 计算的时候，仅仅以parent node为参照物，直接计算，忽略两个node中间的其他view层级
    ETNodeVisibleRectCalculateStrategyRecursionOnViewTree,          // 计算的时候，按照view的树的结构，一层层递归向上计算
    ETNodeVisibleRectCalculateStrategyPassthrough,                  // 节点的可见区域，向上穿透，可以比其父节点更大（即: 当前节点的可见区域只跟自身有关系, 不受父节点可见区域限制）(但是如果父节点不可见，则该子节点也不可见)
};

typedef NS_ENUM(NSUInteger, ETNodeBuildinEventLogDisableStrategy) {
    ETNodeBuildinEventLogDisableStrategyNone        = 0,            // SDK内部点击和曝光都做
    ETNodeBuildinEventLogDisableStrategyClick       = 1 << 0,       // SDK内部仅仅做曝光；备注: 对于虚拟父节点，该值不生效
    ETNodeBuildinEventLogDisableStrategyImpress     = 1 << 1,       // SDK内部禁止 曝光开始&&曝光结束; 备注: 如果不打曝光开始，则也不会打曝光结束
    ETNodeBuildinEventLogDisableStrategyImpressend  = 1 << 2,       // SDK内部禁止 曝光结束
    ETNodeBuildinEventLogDisableStrategyAll         = ETNodeBuildinEventLogDisableStrategyClick | ETNodeBuildinEventLogDisableStrategyImpress | ETNodeBuildinEventLogDisableStrategyImpressend
};

// 优先级高的会在优先级低的上方，即优先级高的可以遮挡优先级低的
// 优先级相同的，后设置的会遮挡先设置的
typedef NS_ENUM(NSUInteger, ETAutoMountRootPageQueuePriority) {
    ETAutoMountRootPageQueuePriorityVeryLow             = 100,
    ETAutoMountRootPageQueuePriorityLow                 = 200,
    ETAutoMountRootPageQueuePriorityDefault             = 500,
    ETAutoMountRootPageQueuePriorityHigh                = 800,
    ETAutoMountRootPageQueuePriorityVeryHigh            = 1000
};

#pragma mark - Event Id
#define ET_CONST_DEF(_et_name_) FOUNDATION_EXTERN NSString *const _et_name_

/// MARK: Event ids
ET_CONST_DEF(ET_EVENT_ID_APP_ACTIVE);       // _ac:     app激活
ET_CONST_DEF(ET_EVENT_ID_APP_IN);           // _ai:     app进入前台
ET_CONST_DEF(ET_EVENT_ID_APP_OUT);          // _ao:     app进后台
ET_CONST_DEF(ET_EVENT_ID_P_VIEW);           // _pv:     页面曝光
ET_CONST_DEF(ET_EVENT_ID_P_VIEW_END);       // _pd:     页面曝光结束
ET_CONST_DEF(ET_EVENT_ID_E_VIEW);           // _ev:     元素曝光
ET_CONST_DEF(ET_EVENT_ID_E_VIEW_END);       // _ed:     元素曝光结束
ET_CONST_DEF(ET_EVENT_ID_E_CLCK);           // _ec:     元素点击
ET_CONST_DEF(ET_EVENT_ID_E_LONG_CLCK);      // _elc:    元素长按
ET_CONST_DEF(ET_EVENT_ID_E_SLIDE);          // _es:     元素滑动
ET_CONST_DEF(ET_EVENT_ID_P_REFRESH);        // _pgf:    页面[下拉]刷新
ET_CONST_DEF(ET_EVENT_ID_PLV);              // _plv:    播放开始
ET_CONST_DEF(ET_EVENT_ID_PLD);              // _pld:    播放结束

/// MARK: refer 相关的常量值
ET_CONST_DEF(ET_REFER_KEY_S);           // s
ET_CONST_DEF(ET_REFER_KEY_P);           // p
ET_CONST_DEF(ET_REFER_KEY_E);           // e
ET_CONST_DEF(ET_REFER_KEY_SPM);         // _spm
ET_CONST_DEF(ET_REFER_KEY_SCM);         // _scm
ET_CONST_DEF(ET_REFER_KEY_SCM_ER);      // _scm_er
ET_CONST_DEF(ET_REFER_KEY_PGREFER);     // _pgrefer
ET_CONST_DEF(ET_REFER_KEY_PSREFER);     // _psrefer
ET_CONST_DEF(ET_REFER_KEY_PGSTEP);      // _pgstep
ET_CONST_DEF(ET_REFER_KEY_ACTSEQ);      // _actseq
ET_CONST_DEF(ET_REFER_KEY_HSREFER);     // _hsrefer
ET_CONST_DEF(ET_REFER_KEY_SESSID);      // _sessid
ET_CONST_DEF(ET_REFER_KEY_SIDREFER);    // _sidrefer
ET_CONST_DEF(ET_REFER_KEY_RQREFER);     // _rqrefer
ET_CONST_DEF(ET_REFER_KEY_POSITION);    // _position
ET_CONST_DEF(ET_REFER_KEY_DURATION);    // _duration
ET_CONST_DEF(ET_REFER_KEY_RATIO);       // _ratio

/// MARK: 日志输出相关的一些关键字
ET_CONST_DEF(ET_CONST_KEY_OID);         // _oid
ET_CONST_DEF(ET_CONST_KEY_PLIST);       // _plist
ET_CONST_DEF(ET_CONST_KEY_ELIST);       // _elist
ET_CONST_DEF(ET_CONST_KEY_EVENT_CODE);  // _eventcode
ET_CONST_DEF(ET_CONST_KEY_IB);          // _ib
ET_CONST_DEF(ET_CONST_KEY_INVISIBLE);   // _invisible

/// MARK: `position` Params Key
/// MARK: Alert Action场景可以设置 `position`, 则就内置就给该节点增加参数 `s_position` 参数
/// MARK: 以及其他场景，节点params的 `position` 所对应的 key
ET_CONST_DEF(ET_PARAM_CONST_KEY_POSITION);    // s_position

/// MARK: 内部候用
ET_CONST_DEF(ET_REUSE_BIZ_SET);

#undef ET_CONST_DEF

#endif

// 保证在对应的 queue 执行 async
#ifndef ETDispatchGlobalQueueAsyncSafe
    #define ETDispatchGlobalQueueAsyncSafe(block)  ETDispatchQueueAsyncSafe(dispatch_get_global_queue(0, 0), block)
#endif

#ifndef ETDispatchQueueAsyncSafe
    #define ETDispatchQueueAsyncSafe(queue, block)\
    if (dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(queue)) {\
        block();\
    } else {\
        dispatch_async(queue, block);\
    }
#endif

// 保证在 main queue 执行 async
#ifndef ETDispatchMainAsyncSafe
    #define ETDispatchMainAsyncSafe(block) ETDispatchQueueAsyncSafe(dispatch_get_main_queue(), block)
#endif

FOUNDATION_EXTERN NSString * const kEventTracingSessIdKey;
FOUNDATION_EXTERN NSString * const ETParamKeyGuardEvent;
FOUNDATION_EXTERN NSString * const ETParamKeyGuardPublicParam;
FOUNDATION_EXTERN NSString * const ETParamKeyGuardUserParam;
