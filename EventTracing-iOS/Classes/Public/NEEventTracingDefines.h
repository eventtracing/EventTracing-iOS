//
//  NEEventTracingDefines.h
//  NEEventTracing
//
//  Created by dl on 2021/2/25.
//

#import <Foundation/Foundation.h>

#ifndef NEEventTracingDEFINE_H
#define NEEventTracingDEFINE_H

extern NSUInteger NEEventTracingReferQueueMaxCount;

typedef NS_ENUM(NSUInteger, ETLogLevel) {
    ETLogLevelVerbose,
    ETLogLevelDebug,
    ETLogLevelInfo,
    ETLogLevelSystem,
    ETLogLevelWarning,
    ETLogLevelError
};

extern NSString * const NEEventTracingExeptionErrmsgKey;

// Node 节点不唯一
// Node 节点唯一: node.identifier + node.spm 组合唯一
extern NSInteger const NEEventTracingExceptionCodeNodeNotUnique;                         // 41

// Node 节点的 _spm 不唯一
// 这里尤其针对 cell 复用的时候，业务方漏掉了 position 的设置
extern NSInteger const NEEventTracingExceptionCodeNodeSPMNotUnique;                         // 42

// Node 逻辑挂载死循环
// A -> B, b -> C, c -> A, 造成死循环
extern NSInteger const NEEventTracingExceptionCodeLogicalMountEndlessLoop;               // 43

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
extern NSInteger const NEEventTracingExceptionEventKeyInvalid;                           // 51

// event key 跟内部预埋的event命名冲突
extern NSInteger const NEEventTracingExceptionEventKeyConflictWithEmbedded;              // 52

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
extern NSInteger const NEEventTracingExceptionPublicParamInvalid;                        // 53

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
extern NSInteger const NEEventTracingExceptionUserParamInvalid;                          // 54

// param key 跟内部预埋的 param 命名冲突
extern NSInteger const NEEventTracingExceptionParamConflictWithEmbedded;                 // 55


/// MARK: `UIViewController.view` 的访问，当 `isViewDidLoad==NO` 时，需要作为 exception 抛出
typedef NS_ENUM(NSUInteger, NEETViewControllerDidNotLoadViewExceptionTip) {
    NEETViewControllerDidNotLoadViewExceptionTipNone,       // default
    NEETViewControllerDidNotLoadViewExceptionTipAssert,     // 内部使用 Assert
    NEETViewControllerDidNotLoadViewExceptionTipCostom      // 业务侧可使用 toast
};

typedef NS_ENUM(NSUInteger, NEETExceptionLevel) {
    NEETExceptionLevelWaring,
    NEETExceptionLevelError,
    NEETExceptionLevelFatal
};

typedef NS_ENUM(NSUInteger, NEETNodeVisibleRectCalculateStrategy) {
    NEETNodeVisibleRectCalculateStrategyOnParentNode = 0,             // default: 计算的时候，仅仅以parent node为参照物，直接计算，忽略两个node中间的其他view层级
    NEETNodeVisibleRectCalculateStrategyRecursionOnViewTree,          // 计算的时候，按照view的树的结构，一层层递归向上计算
    NEETNodeVisibleRectCalculateStrategyPassthrough,                  // 节点的可见区域，向上穿透，可以比其父节点更大（即: 当前节点的可见区域只跟自身有关系, 不受父节点可见区域限制）(但是如果父节点不可见，则该子节点也不可见)
};

typedef NS_ENUM(NSUInteger, NEETNodeBuildinEventLogDisableStrategy) {
    NEETNodeBuildinEventLogDisableStrategyNone        = 0,            // SDK内部点击和曝光都做
    NEETNodeBuildinEventLogDisableStrategyClick       = 1 << 0,       // SDK内部仅仅做曝光；备注: 对于虚拟父节点，该值不生效
    NEETNodeBuildinEventLogDisableStrategyImpress     = 1 << 1,       // SDK内部禁止 曝光开始&&曝光结束; 备注: 如果不打曝光开始，则也不会打曝光结束
    NEETNodeBuildinEventLogDisableStrategyImpressend  = 1 << 2,       // SDK内部禁止 曝光结束
    NEETNodeBuildinEventLogDisableStrategyAll         = NEETNodeBuildinEventLogDisableStrategyClick | NEETNodeBuildinEventLogDisableStrategyImpress | NEETNodeBuildinEventLogDisableStrategyImpressend
};

// 优先级高的会在优先级低的上方，即优先级高的可以遮挡优先级低的
// 优先级相同的，后设置的会遮挡先设置的
typedef NS_ENUM(NSUInteger, NEETAutoMountRootPageQueuePriority) {
    NEETAutoMountRootPageQueuePriorityVeryLow             = 100,
    NEETAutoMountRootPageQueuePriorityLow                 = 200,
    NEETAutoMountRootPageQueuePriorityDefault             = 500,
    NEETAutoMountRootPageQueuePriorityHigh                = 800,
    NEETAutoMountRootPageQueuePriorityVeryHigh            = 1000
};


/// `root page pv` 会强制作为兜底
typedef NS_OPTIONS(NSUInteger, NEEventTracingPageReferConsumeOption) {
    NEEventTracingPageReferConsumeOptionNone       = 0L,
    /// 只要该页面会使用 psrefer，即使 `root pv option` 为 0，也是会作为兜底逻辑降级到 root pv
    NEEventTracingPageReferConsumeOptionEventEc    = 1L << 1,
    NEEventTracingPageReferConsumeOptionCustom     = 1L << 2,
    NEEventTracingPageReferConsumeOptionSubPagePV  = 1L << 3,
    /// 一般用于浮层子页面
    NEEventTracingPageReferConsumeOptionExceptSubPagePV = NEEventTracingPageReferConsumeOptionEventEc |
                                                          NEEventTracingPageReferConsumeOptionCustom,
    /// 一般用于需要参与 psrefer 的子页面，比如首页 tab
    NEEventTracingPageReferConsumeOptionAll        = (NSUInteger)(~0L),
};


#pragma mark - Event Id
#define NE_ET_CONST_DEF(_et_name_) FOUNDATION_EXTERN NSString *const _et_name_

/// MARK: Event ids
NE_ET_CONST_DEF(NE_ET_EVENT_ID_APP_ACTIVE);       // _ac:     app激活
NE_ET_CONST_DEF(NE_ET_EVENT_ID_APP_IN);           // _ai:     app进入前台
NE_ET_CONST_DEF(NE_ET_EVENT_ID_APP_OUT);          // _ao:     app进后台
NE_ET_CONST_DEF(NE_ET_EVENT_ID_P_VIEW);           // _pv:     页面曝光
NE_ET_CONST_DEF(NE_ET_EVENT_ID_P_VIEW_END);       // _pd:     页面曝光结束
NE_ET_CONST_DEF(NE_ET_EVENT_ID_E_VIEW);           // _ev:     元素曝光
NE_ET_CONST_DEF(NE_ET_EVENT_ID_E_VIEW_END);       // _ed:     元素曝光结束
NE_ET_CONST_DEF(NE_ET_EVENT_ID_E_CLCK);           // _ec:     元素点击
NE_ET_CONST_DEF(NE_ET_EVENT_ID_E_LONG_CLCK);      // _elc:    元素长按
NE_ET_CONST_DEF(NE_ET_EVENT_ID_E_SLIDE);          // _es:     元素滑动
NE_ET_CONST_DEF(NE_ET_EVENT_ID_P_REFRESH);        // _pgf:    页面[下拉]刷新
NE_ET_CONST_DEF(NE_ET_EVENT_ID_PLV);              // _plv:    播放开始
NE_ET_CONST_DEF(NE_ET_EVENT_ID_PLD);              // _pld:    播放结束

/// MARK: refer 相关的常量值
NE_ET_CONST_DEF(NE_ET_REFER_KEY_S);           // s
NE_ET_CONST_DEF(NE_ET_REFER_KEY_P);           // p
NE_ET_CONST_DEF(NE_ET_REFER_KEY_E);           // e
NE_ET_CONST_DEF(NE_ET_REFER_KEY_SPM);         // _spm
NE_ET_CONST_DEF(NE_ET_REFER_KEY_SCM);         // _scm
NE_ET_CONST_DEF(NE_ET_REFER_KEY_SCM_ER);      // _scm_er
NE_ET_CONST_DEF(NE_ET_REFER_KEY_PGREFER);     // _pgrefer
NE_ET_CONST_DEF(NE_ET_REFER_KEY_PSREFER);     // _psrefer
NE_ET_CONST_DEF(NE_ET_REFER_KEY_PGSTEP);      // _pgstep
NE_ET_CONST_DEF(NE_ET_REFER_KEY_ACTSEQ);      // _actseq
NE_ET_CONST_DEF(NE_ET_REFER_KEY_HSREFER);     // _hsrefer
NE_ET_CONST_DEF(NE_ET_REFER_KEY_SESSID);      // _sessid
NE_ET_CONST_DEF(NE_ET_REFER_KEY_SIDREFER);    // _sidrefer
NE_ET_CONST_DEF(NE_ET_REFER_KEY_RQREFER);     // _rqrefer
NE_ET_CONST_DEF(NE_ET_REFER_KEY_POSITION);    // _position
NE_ET_CONST_DEF(NE_ET_REFER_KEY_DURATION);    // _duration
NE_ET_CONST_DEF(NE_ET_REFER_KEY_RATIO);       // _ratio

/// MARK: 日志输出相关的一些关键字
NE_ET_CONST_DEF(NE_ET_CONST_KEY_OID);         // _oid
NE_ET_CONST_DEF(NE_ET_CONST_KEY_PLIST);       // _plist
NE_ET_CONST_DEF(NE_ET_CONST_KEY_ELIST);       // _elist
NE_ET_CONST_DEF(NE_ET_CONST_KEY_EVENT_CODE);  // _eventcode
NE_ET_CONST_DEF(NE_ET_CONST_KEY_IB);          // _ib
NE_ET_CONST_DEF(NE_ET_CONST_KEY_INVISIBLE);   // _invisible

/// MARK: `position` Params Key
/// MARK: Alert Action场景可以设置 `position`, 则就内置就给该节点增加参数 `s_position` 参数
/// MARK: 以及其他场景，节点params的 `position` 所对应的 key
NE_ET_CONST_DEF(NE_ET_PARAM_CONST_KEY_POSITION);    // s_position

/// MARK: 内部候用
NE_ET_CONST_DEF(NE_ET_REUSE_BIZ_SET);

/// MARK: 节点信息校验相关
NE_ET_CONST_DEF(NE_ET_CONST_VALIDATION_PAGE_TYPE);                  // _valid_page_type => `rootpage/subpage`
NE_ET_CONST_DEF(NE_ET_CONST_VALIDATION_LOGICAL_MOUNT);              // _valid_logical_mount => `auto/mannul`
NE_ET_CONST_DEF(NE_ET_CONST_VALIDATION_IGNORE_REFER_CASCADE);       // _valid_ignore_refer_cascade => `1/0`
NE_ET_CONST_DEF(NE_ET_CONST_VALIDATION_PSREFER_MUTED);              // _valid_psrefer_muted => `1/0`

#undef NE_ET_CONST_DEF

#endif

// 保证在对应的 queue 执行 async
#ifndef NEETDispatchGlobalQueueAsyncSafe
    #define NEETDispatchGlobalQueueAsyncSafe(block)  NEETDispatchQueueAsyncSafe(dispatch_get_global_queue(0, 0), block)
#endif

#ifndef NEETDispatchQueueAsyncSafe
    #define NEETDispatchQueueAsyncSafe(queue, block)\
    if (dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(queue)) {\
        block();\
    } else {\
        dispatch_async(queue, block);\
    }
#endif

// 保证在 main queue 执行 async
#ifndef NEETDispatchMainAsyncSafe
    #define NEETDispatchMainAsyncSafe(block) NEETDispatchQueueAsyncSafe(dispatch_get_main_queue(), block)
#endif
