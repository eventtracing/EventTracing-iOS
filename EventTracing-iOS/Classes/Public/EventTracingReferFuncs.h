//
//  EventTracingReferFuncs.h
//  Pods
//
//  Created by dl on 2021/6/8.
//

#import <UIKit/UIKit.h>
#import "EventTracingEventRefer.h"

#ifndef EventTracingReferFuncs_h
#define EventTracingReferFuncs_h

NS_ASSUME_NONNULL_BEGIN

/// MARK: find view (注：查找链路遵循原始的view树，忽略逻辑挂载)
// 1. 基于当前 view 向上查找，找到第一个 节点 即返回
//    没有性能问题，推荐使用
__attribute__((overloadable))
FOUNDATION_EXPORT UIView * _Nullable ET_FindAncestorNodeViewAt(UIView *view);

/// MARK: find view (注：查找链路遵循原始的view树，忽略逻辑挂载)
// 2. 基于当前 view 向上查找，找到第一个 oid 相等的即返回
//    没有性能问题，推荐使用
FOUNDATION_EXPORT UIView * _Nullable ET_FindAncestorNodeViewAt(UIView *view, NSString *oid);

// 3. 基于当前 view 向下查找，找到第一个 oid 相等的即返回
//    右侧深度遍历，不太建议使用
FOUNDATION_EXPORT UIView * _Nullable ET_FindSubNodeViewAt(UIView *view, NSString *oid);
// 4. 全局查找
//    右侧深度遍历，不推荐使用
FOUNDATION_EXPORT UIView * _Nullable ET_FindNodeViewGlobally(NSString *oid);

// 5. 获取 view/vc 的spm
//    过早的调用该方法可能获取不到(此时虚拟树未生成, _spm无法计算得出)
//    使用场景: 做一些自定义事件的时候使用，这个时候view树已经处于稳定状态，虚拟树也已经生成好了的，这个时候是可以获取到spm的
FOUNDATION_EXPORT NSString * _Nullable ET_spmForView(UIView *v);
FOUNDATION_EXPORT NSString * _Nullable ET_spmForViewController(UIViewController *vc);

// 6.1 获取 event refer
//     指定了view，可防止取错
// event refer:
//      其中, _spm 业务方可以自定义formatter: EventTracingEventReferFormatter
//      _spm默认: 取值 node.spm
__attribute__((overloadable))
FOUNDATION_EXPORT NSString * _Nullable ET_eventReferForView(UIView *v);

// 6.2 获取 evnet refer
//  如果后面即将在 `view` 上触发一个event，可以采用 `预取` 的方式来获取下次点击的 event refer
FOUNDATION_EXPORT NSString * _Nullable ET_eventReferForView(UIView *v, BOOL useNextActseq);

// 7. 获取 event refer
//    没有指定view，默认取上次在任何一个view上发生了 event事件 时的refer
//    特点:
//      1. AOP内的点击事件，在业务方点击事件handler触发之前，SDK内部push一个该view的event refer
//      2. 业务方点击事件handler之后，执行SDK内置的埋点
//      3. 如果是自定义事件的埋点，埋点代码需要放在业务handler取refer逻辑代码之前执行
//    使用场景:
//      1. 业务方的点击事件处理代码中，可直接取 event refer
//      2. 业务方可以在业务模块内封装，这样可以对业务开发人员透明了 (典型场景: router层面)
FOUNDATION_EXPORT id<EventTracingEventRefer> _Nullable ET_lastestAutoEventRefer(void);           // 默认是带 [sessid] 的refer格式【！！！如果需要持久化，则需要带上sessid】
FOUNDATION_EXPORT id<EventTracingEventRefer> _Nullable ET_lastestAutoEventNoSessidRefer(void);

FOUNDATION_EXPORT id<EventTracingEventRefer> _Nullable ET_lastestAutoEventReferForEvent(NSString *event);    // 默认是带 [sessid] 的refer格式【！！！如果需要持久化，则需要带上sessid】
FOUNDATION_EXPORT id<EventTracingEventRefer> _Nullable ET_lastestAutoEventNoSessidReferForEvent(NSString *event);

// 8. 获取 AOP点击事件的 event refer
//   跟上面俩方法的区别: 只要是SDK内部AOP的点击事件，都会生成
//   生成的 refer 不再包含VTree结构，而是纯正根据 view 层级来构建
//   SDK内AOP分为:
//      1. UITableViewCell 的点击
//      2. UICollectionViewCell 的点击
//      3. UIControl target-action 形式的点击
//      4. UIView tap gesture 形式的点击
FOUNDATION_EXPORT id<EventTracingEventRefer> _Nullable ET_lastestUndefinedXpathRefer(void);

NS_ASSUME_NONNULL_END
#endif /* EventTracingReferFuncs_h */
