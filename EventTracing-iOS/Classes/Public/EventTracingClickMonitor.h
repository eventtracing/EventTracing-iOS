//
//  EventTracingClickMonitor.h
//  EventTracing
//
//  Created by dl on 2022/7/14.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class EventTracingClickMonitor;

/// MARK: 监控点击事件的 的 Base Observer
@protocol EventTracingClickObserver <NSObject>
@end

/// MARK: 监控: UIControl 的子类中 `UIControlEventTouchUpInside` 事件
@protocol EventTracingClickControlTouchUpInsideObserver <EventTracingClickObserver>

/// UIControl 即将调用第一个 target & action 时回调
- (void)clickMonitor:(EventTracingClickMonitor *)clickMonitor willTouchUpInsideControl:(UIControl *)control;
/// UIControl 调用完成最后一个 target & action 时回调
- (void)clickMonitor:(EventTracingClickMonitor *)clickMonitor didTouchUpInsideControl:(UIControl *)control;
@end

/// MARK: 监控: UIView 上添加的 TapGesture 点击手势
@protocol EventTracingClickViewSingleTapObserver <EventTracingClickObserver>

/// view 的 Tap 手势即将被调用
- (void)clickMonitor:(EventTracingClickMonitor *)clickMonitor willTapView:(UIView *)view;
/// view 的 Tap 手势调用结束
- (void)clickMonitor:(EventTracingClickMonitor *)clickMonitor didTapView:(UIView *)view;

@end

/// MARK: UITableViewCell的 `didSelectRowAtIndexPath:` 事件
/// 注意 => will/did 两个方法，indexPath 是相同的，但是对应的cell不一定相同，比如业务侧代码在 handler 内部进行了 reloadData 操作，可能引起了cell复用
@protocol EventTracingClickTableCellDidSelectedObserver <EventTracingClickObserver>

/// UITableView => `tableview:didSelectRowAtIndexPath:` 方法即将被调用
- (void)clickMonitor:(EventTracingClickMonitor *)clickMonitor tableView:(UITableView *)tableView willSelectedRowAtIndexPath:(NSIndexPath *)indexPath;
/// UITableView => `tableview:didSelectRowAtIndexPath:` 方法被调用结束
- (void)clickMonitor:(EventTracingClickMonitor *)clickMonitor tableView:(UITableView *)tableView didSelectedRowAtIndexPath:(NSIndexPath *)indexPath;

@end

/// MARK: UICollectionViewCell 的 `didSelectItemAtIndexPath:` 事件
/// 注意 => will/did 两个方法，indexPath 是相同的，但是对应的cell不一定相同，比如业务侧代码在 handler 内部进行了 reloadData 操作，可能引起了cell复用
@protocol EventTracingClickCollectionCellDidSelectedObserver <EventTracingClickObserver>

/// UICollectionView => `collectionView:didSelectItemAtIndexPath:` 方法即将被调用
- (void)clickMonitor:(EventTracingClickMonitor *)clickMonitor collectionView:(UICollectionView *)collectionView willSelectedItemAtIndexPath:(NSIndexPath *)indexPath;
/// UICollectionView => `collectionView:didSelectItemAtIndexPath:` 方法被调用结束
- (void)clickMonitor:(EventTracingClickMonitor *)clickMonitor collectionView:(UICollectionView *)collectionView didSelectedItemAtIndexPath:(NSIndexPath *)indexPath;

@end

/*!
 * 以AOP的方式，对 `click(单击)` 事件进行监控; 包含以下四种场景:
 *   1. UIControl 的子类中 `UIControlEventTouchUpInside` 事件
 *   2. UIView 上添加的 TapGesture 点击手势
 *   3. UITableViewCell的 `didSelectRowAtIndexPath:` 事件
 *   4. UICollectionViewCell 的 `didSelectItemAtIndexPath:` 事件
 *
 *   @note 所有事件均支持 `pre` & `after` 两个时机
 *   @note 这里添加的是全局 observer，请在使用结束的时候，及时 remove 掉
 */
@interface EventTracingClickMonitor : NSObject

/// MARK: => 所有被监控的 views; 专指 `定向` 到具体 view 的方式来添加 observer
@property(nonatomic, copy, readonly) NSArray<UIView *> *allObservedViews;
@property(nonatomic, copy, readonly) NSArray<EventTracingClickObserver> *allObservers;
@property(nonatomic, copy, readonly) NSArray<EventTracingClickObserver> *allGlobalObservers;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
+ (instancetype)new UNAVAILABLE_ATTRIBUTE;

+(instancetype)sharedInstance;

/// 内部 weak 方式持有
- (void)addGlobalObserver:(id<EventTracingClickObserver>)observer;
- (void)removeGlobalObserver:(id<EventTracingClickObserver>)observer;

/// MARK: => `定向` 到具体 view 的方式添加的 observers
- (NSArray<id<EventTracingClickObserver>> *)observersForView:(UIView *)view;
@end

@interface EventTracingClickMonitor (Control_TouchUpInside)
@property(nonatomic, copy, readonly) NSArray<UIControl *> *allTouchUpInsideObservedControls;
@property(nonatomic, copy, readonly) NSArray<id<EventTracingClickControlTouchUpInsideObserver>> *allControlTouchUpInsideObservers;

- (NSArray<id<EventTracingClickControlTouchUpInsideObserver>> *)controlTouchUpInsideObserversForControl:(UIControl *)control;
@end

@interface EventTracingClickMonitor (View_SingleTapGesture)
@property(nonatomic, copy, readonly) NSArray<UIView *> *allSingleTapObservedViews;
@property(nonatomic, copy, readonly) NSArray<id<EventTracingClickViewSingleTapObserver>> *allViewSingleTapObservers;

- (NSArray<id<EventTracingClickViewSingleTapObserver>> *)viewSingleTapObserversForView:(UIView *)view;
@end

@interface EventTracingClickMonitor (TableView_CellDidSelected)
@property(nonatomic, copy, readonly) NSArray<UITableView *> *allCellDidSelectedObservedTableViews;
@property(nonatomic, copy, readonly) NSArray<id<EventTracingClickTableCellDidSelectedObserver>> *allTableCellDidSelectedObservers;

- (NSArray<id<EventTracingClickTableCellDidSelectedObserver>> *)tableCellDidSelectedObserversForTableView:(UITableView *)tableView;
@end

@interface EventTracingClickMonitor (Collection_CellDidSelected)
@property(nonatomic, copy, readonly) NSArray<UICollectionView *> *allCellDidSelectedObservedCollectionViews;
@property(nonatomic, copy, readonly) NSArray<id<EventTracingClickCollectionCellDidSelectedObserver>> *allCollectionCellDidSelectedObservers;

- (NSArray<id<EventTracingClickTableCellDidSelectedObserver>> *)tableCellDidSelectedObserversForCollectionView:(UICollectionView *)collectionView;
@end

#pragma mark - 下面是 `定向` 的方式来给具体 view 添加 observer
@interface UIControl (AOP_Observer_TouchUpInside)
@property(nonatomic, copy, readonly) NSArray<id<EventTracingClickControlTouchUpInsideObserver>> *et_clickObservers;
- (void)et_addClickObserver:(id<EventTracingClickControlTouchUpInsideObserver>)observer;
- (void)et_removeClickObserver:(id<EventTracingClickControlTouchUpInsideObserver>)observer;
@end

@interface UIView (AOP_Observer_SingleTapGesture)
@property(nonatomic, copy, readonly) NSArray<id<EventTracingClickViewSingleTapObserver>> *et_clickObservers;
- (void)et_addClickObserver:(id<EventTracingClickViewSingleTapObserver>)observer;
- (void)et_removeClickObserver:(id<EventTracingClickViewSingleTapObserver>)observer;
@end

@interface UITableView (AOP_Observer_CellDidSelected)
@property(nonatomic, copy, readonly) NSArray<id<EventTracingClickTableCellDidSelectedObserver>> *et_clickObservers;
- (void)et_addClickObserver:(id<EventTracingClickTableCellDidSelectedObserver>)observer;
- (void)et_removeClickObserver:(id<EventTracingClickTableCellDidSelectedObserver>)observer;
@end

@interface UICollectionView (AOP_Observer_CellDidSelected)
@property(nonatomic, copy, readonly) NSArray<id<EventTracingClickCollectionCellDidSelectedObserver>> *et_clickObservers;
- (void)et_addClickObserver:(id<EventTracingClickCollectionCellDidSelectedObserver>)observer;
- (void)et_removeClickObserver:(id<EventTracingClickCollectionCellDidSelectedObserver>)observer;
@end

NS_ASSUME_NONNULL_END
