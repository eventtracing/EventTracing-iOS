//
//  NEEventTracingClickMonitor.h
//  NEEventTracing
//
//  Created by dl on 2022/7/14.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class NEEventTracingClickMonitor;

/// MARK: 监控点击事件的 的 Base Observer
@protocol NEEventTracingClickObserver <NSObject>
@end

/// MARK: 监控: UIControl 的子类中 `UIControlEventTouchUpInside` 事件
@protocol NEEventTracingClickControlTouchUpInsideObserver <NEEventTracingClickObserver>

/// UIControl 即将调用第一个 target & action 时回调
- (void)clickMonitor:(NEEventTracingClickMonitor *)clickMonitor willTouchUpInsideControl:(UIControl *)control;
/// UIControl 调用完成最后一个 target & action 时回调
- (void)clickMonitor:(NEEventTracingClickMonitor *)clickMonitor didTouchUpInsideControl:(UIControl *)control;
@end

/// MARK: 监控: UIView 上添加的 TapGesture 点击手势
@protocol NEEventTracingClickViewSingleTapObserver <NEEventTracingClickObserver>

/// view 的 Tap 手势即将被调用
- (void)clickMonitor:(NEEventTracingClickMonitor *)clickMonitor willTapView:(UIView *)view;
/// view 的 Tap 手势调用结束
- (void)clickMonitor:(NEEventTracingClickMonitor *)clickMonitor didTapView:(UIView *)view;

@end

/// MARK: UITableViewCell的 `didSelectRowAtIndexPath:` 事件
/// 注意 => will/did 两个方法，indexPath 是相同的，但是对应的cell不一定相同，比如业务侧代码在 handler 内部进行了 reloadData 操作，可能引起了cell复用
@protocol NEEventTracingClickTableCellDidSelectedObserver <NEEventTracingClickObserver>

/// UITableView => `tableview:didSelectRowAtIndexPath:` 方法即将被调用
- (void)clickMonitor:(NEEventTracingClickMonitor *)clickMonitor tableView:(UITableView *)tableView willSelectedRowAtIndexPath:(NSIndexPath *)indexPath;
/// UITableView => `tableview:didSelectRowAtIndexPath:` 方法被调用结束
- (void)clickMonitor:(NEEventTracingClickMonitor *)clickMonitor tableView:(UITableView *)tableView didSelectedRowAtIndexPath:(NSIndexPath *)indexPath;

@end

/// MARK: UICollectionViewCell 的 `didSelectItemAtIndexPath:` 事件
/// 注意 => will/did 两个方法，indexPath 是相同的，但是对应的cell不一定相同，比如业务侧代码在 handler 内部进行了 reloadData 操作，可能引起了cell复用
@protocol NEEventTracingClickCollectionCellDidSelectedObserver <NEEventTracingClickObserver>

/// UICollectionView => `collectionView:didSelectItemAtIndexPath:` 方法即将被调用
- (void)clickMonitor:(NEEventTracingClickMonitor *)clickMonitor collectionView:(UICollectionView *)collectionView willSelectedItemAtIndexPath:(NSIndexPath *)indexPath;
/// UICollectionView => `collectionView:didSelectItemAtIndexPath:` 方法被调用结束
- (void)clickMonitor:(NEEventTracingClickMonitor *)clickMonitor collectionView:(UICollectionView *)collectionView didSelectedItemAtIndexPath:(NSIndexPath *)indexPath;

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
@interface NEEventTracingClickMonitor : NSObject

/// MARK: => 所有被监控的 views; 专指 `定向` 到具体 view 的方式来添加 observer
@property(nonatomic, copy, readonly) NSArray<UIView *> *allObservedViews;
@property(nonatomic, copy, readonly) NSArray<NEEventTracingClickObserver> *allObservers;
@property(nonatomic, copy, readonly) NSArray<NEEventTracingClickObserver> *allGlobalObservers;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
+ (instancetype)new UNAVAILABLE_ATTRIBUTE;

+(instancetype)sharedInstance;

/// 内部 weak 方式持有
- (void)addGlobalObserver:(id<NEEventTracingClickObserver>)observer;
- (void)removeGlobalObserver:(id<NEEventTracingClickObserver>)observer;

/// MARK: => `定向` 到具体 view 的方式添加的 observers
- (NSArray<id<NEEventTracingClickObserver>> *)observersForView:(UIView *)view;
@end

@interface NEEventTracingClickMonitor (Control_TouchUpInside)
@property(nonatomic, copy, readonly) NSArray<UIControl *> *allTouchUpInsideObservedControls;
@property(nonatomic, copy, readonly) NSArray<id<NEEventTracingClickControlTouchUpInsideObserver>> *allControlTouchUpInsideObservers;

- (NSArray<id<NEEventTracingClickControlTouchUpInsideObserver>> *)controlTouchUpInsideObserversForControl:(UIControl *)control;
@end

@interface NEEventTracingClickMonitor (View_SingleTapGesture)
@property(nonatomic, copy, readonly) NSArray<UIView *> *allSingleTapObservedViews;
@property(nonatomic, copy, readonly) NSArray<id<NEEventTracingClickViewSingleTapObserver>> *allViewSingleTapObservers;

- (NSArray<id<NEEventTracingClickViewSingleTapObserver>> *)viewSingleTapObserversForView:(UIView *)view;
@end

@interface NEEventTracingClickMonitor (TableView_CellDidSelected)
@property(nonatomic, copy, readonly) NSArray<UITableView *> *allCellDidSelectedObservedTableViews;
@property(nonatomic, copy, readonly) NSArray<id<NEEventTracingClickTableCellDidSelectedObserver>> *allTableCellDidSelectedObservers;

- (NSArray<id<NEEventTracingClickTableCellDidSelectedObserver>> *)tableCellDidSelectedObserversForTableView:(UITableView *)tableView;
@end

@interface NEEventTracingClickMonitor (Collection_CellDidSelected)
@property(nonatomic, copy, readonly) NSArray<UICollectionView *> *allCellDidSelectedObservedCollectionViews;
@property(nonatomic, copy, readonly) NSArray<id<NEEventTracingClickCollectionCellDidSelectedObserver>> *allCollectionCellDidSelectedObservers;

- (NSArray<id<NEEventTracingClickTableCellDidSelectedObserver>> *)tableCellDidSelectedObserversForCollectionView:(UICollectionView *)collectionView;
@end

#pragma mark - 下面是 `定向` 的方式来给具体 view 添加 observer
@interface UIControl (AOP_Observer_TouchUpInside)
@property(nonatomic, copy, readonly) NSArray<id<NEEventTracingClickControlTouchUpInsideObserver>> *ne_et_clickObservers;
- (void)ne_et_addClickObserver:(id<NEEventTracingClickControlTouchUpInsideObserver>)observer;
- (void)ne_et_removeClickObserver:(id<NEEventTracingClickControlTouchUpInsideObserver>)observer;
@end

@interface UIView (AOP_Observer_SingleTapGesture)
@property(nonatomic, copy, readonly) NSArray<id<NEEventTracingClickViewSingleTapObserver>> *ne_et_clickObservers;
- (void)ne_et_addClickObserver:(id<NEEventTracingClickViewSingleTapObserver>)observer;
- (void)ne_et_removeClickObserver:(id<NEEventTracingClickViewSingleTapObserver>)observer;
@end

@interface UITableView (AOP_Observer_CellDidSelected)
@property(nonatomic, copy, readonly) NSArray<id<NEEventTracingClickTableCellDidSelectedObserver>> *ne_et_clickObservers;
- (void)ne_et_addClickObserver:(id<NEEventTracingClickTableCellDidSelectedObserver>)observer;
- (void)ne_et_removeClickObserver:(id<NEEventTracingClickTableCellDidSelectedObserver>)observer;
@end

@interface UICollectionView (AOP_Observer_CellDidSelected)
@property(nonatomic, copy, readonly) NSArray<id<NEEventTracingClickCollectionCellDidSelectedObserver>> *ne_et_clickObservers;
- (void)ne_et_addClickObserver:(id<NEEventTracingClickCollectionCellDidSelectedObserver>)observer;
- (void)ne_et_removeClickObserver:(id<NEEventTracingClickCollectionCellDidSelectedObserver>)observer;
@end

NS_ASSUME_NONNULL_END
