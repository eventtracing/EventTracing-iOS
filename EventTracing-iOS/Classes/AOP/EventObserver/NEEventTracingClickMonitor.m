//
//  NEEventTracingClickMonitor.m
//  NEEventTracing
//
//  Created by dl on 2022/7/14.
//

#import "NEEventTracingClickMonitor.h"
#import <pthread.h>
#import <BlocksKit/BlocksKit.h>

#define RDLOCK do { pthread_rwlock_rdlock(&self->_lock); } while (0);
#define WRLOCK do { pthread_rwlock_wrlock(&self->_lock); } while (0);
#define UNLOCK do { pthread_rwlock_unlock(&self->_lock); } while (0);

@interface NEEventTracingClickMonitor () {
    pthread_rwlock_t _lock;
}
@property(nonatomic, strong) NSHashTable<id<NEEventTracingClickObserver>> *globalObservers;

@property(nonatomic, strong) NSMapTable<UIView *, NSHashTable<id<NEEventTracingClickObserver>> *> *targetObservers;
@property(nonatomic, strong) NSMapTable<UIView *, NSHashTable<id<NEEventTracingClickObserver>> *> *viewTargetObservers;

- (void)_doAddTargetObserver:(id<NEEventTracingClickObserver>)observer forView:(UIView *)view isOnlyView:(BOOL)isOnlyView;
- (void)_doRemoveTargetObserver:(id<NEEventTracingClickObserver>)observer forView:(UIView *)view isOnlyView:(BOOL)isOnlyView;
@end

@implementation NEEventTracingClickMonitor

- (instancetype)init {
    self = [super init];
    if (self) {
        _lock = (pthread_rwlock_t)PTHREAD_RWLOCK_INITIALIZER;
        _globalObservers = [NSHashTable hashTableWithOptions:NSPointerFunctionsWeakMemory];
        _targetObservers = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsWeakMemory valueOptions:NSPointerFunctionsStrongMemory];
        _viewTargetObservers = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsWeakMemory valueOptions:NSPointerFunctionsStrongMemory];
    }
    return self;
}

+ (instancetype)sharedInstance {
    static NEEventTracingClickMonitor *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[NEEventTracingClickMonitor alloc] init];
    });
    return instance;
}

- (void)addGlobalObserver:(id<NEEventTracingClickObserver>)observer {
    WRLOCK {
        [_globalObservers addObject:observer];
    } UNLOCK
}

- (void)removeGlobalObserver:(id<NEEventTracingClickObserver>)observer {
    WRLOCK {
        [_globalObservers removeObject:observer];
    } UNLOCK
}

- (NSArray<UIView *> *)allObservedViews {
    NSMutableArray<UIView *> *observedViews = @[].mutableCopy;
    
    RDLOCK {
        [observedViews addObjectsFromArray:self.targetObservers.keyEnumerator.allObjects];
        [observedViews addObjectsFromArray:self.viewTargetObservers.keyEnumerator.allObjects];
    } UNLOCK
    
    return observedViews.copy;
}

- (NSArray<NEEventTracingClickObserver> *)allObservers {
    NSMutableArray<NEEventTracingClickObserver> *observers = @[].mutableCopy;
    
    RDLOCK {
        [observers addObjectsFromArray:self.globalObservers.allObjects];

        [self.targetObservers.objectEnumerator.allObjects enumerateObjectsUsingBlock:^(NSHashTable<id<NEEventTracingClickObserver>> * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [observers addObjectsFromArray:obj.allObjects];
        }];

        [self.viewTargetObservers.objectEnumerator.allObjects enumerateObjectsUsingBlock:^(NSHashTable<id<NEEventTracingClickObserver>> * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [observers addObjectsFromArray:obj.allObjects];
        }];
    } UNLOCK
    
    return observers.copy;
}

- (NSArray<NEEventTracingClickObserver> *)allGlobalObservers {
    NSMutableArray<NEEventTracingClickObserver> *observers = @[].mutableCopy;
    
    RDLOCK {
        [observers addObjectsFromArray:self.globalObservers.allObjects];
    } UNLOCK
    
    return observers.copy;
}

- (NSArray<id<NEEventTracingClickObserver>> *)observersForView:(UIView *)view {
    NSMutableArray<id<NEEventTracingClickObserver>> *observers = @[].mutableCopy;
    
    RDLOCK {
        if ([view isKindOfClass:UIControl.class] || [view isKindOfClass:UITableView.class] || [view isKindOfClass:UICollectionView.class]) {
            [observers addObjectsFromArray:[self.targetObservers objectForKey:view].allObjects];
        } else {
            [observers addObjectsFromArray:[self.viewTargetObservers objectForKey:view].allObjects];
        }
        
        [observers addObjectsFromArray:self.globalObservers.allObjects];
    } UNLOCK
    
    return observers;
}

- (void)_doAddTargetObserver:(id<NEEventTracingClickObserver>)observer forView:(UIView *)view isOnlyView:(BOOL)isOnlyView {
    WRLOCK {
        NSHashTable<id<NEEventTracingClickObserver>> *observers = nil;
        observers = isOnlyView ? [self.viewTargetObservers objectForKey:view] : [self.targetObservers objectForKey:view];
        if (!observers) {
            observers = [NSHashTable weakObjectsHashTable];
        }
        isOnlyView ? [self.viewTargetObservers setObject:observers forKey:view] : [self.targetObservers setObject:observers forKey:view];
        
        [observers addObject:observer];
    } UNLOCK
}

- (void)_doRemoveTargetObserver:(id<NEEventTracingClickObserver>)observer forView:(UIView *)view isOnlyView:(BOOL)isOnlyView {
    WRLOCK {
        NSHashTable<id<NEEventTracingClickObserver>> *observers = isOnlyView ? [self.viewTargetObservers objectForKey:view] : [self.targetObservers objectForKey:view];        
        [observers addObject:observer];
    } UNLOCK
}

@end

#define TargetObservedTargetsMethod(Method, Cls, Property) \
- (NSArray<Cls *> *)Method { \
    NSArray<Cls *> *targets = nil; \
    \
    RDLOCK { \
        targets = (NSArray<Cls *> *)[self.Property.keyEnumerator.allObjects bk_select:^BOOL(UIView *obj) { \
            return [obj isKindOfClass:Cls.class]; \
        }]; \
    } UNLOCK \
    \
    return targets; \
}

#define TargetObserversMethod(Method, Protocol, Cls, Property) \
- (NSArray<id<Protocol>> *)Method { \
    NSMutableArray<id<Protocol>> *observers = @[].mutableCopy; \
    \
    RDLOCK { \
        [[self.Property.keyEnumerator.allObjects bk_select:^BOOL(UIView *obj) { \
            return [obj isKindOfClass:Cls.class]; \
        }] enumerateObjectsUsingBlock:^(UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) { \
            NSHashTable<id<Protocol>> *obs = (NSHashTable<id<Protocol>> *)[self.Property objectForKey:obj]; \
            [observers addObjectsFromArray:obs.allObjects]; \
        }]; \
        \
        [self.globalObservers.objectEnumerator.allObjects enumerateObjectsUsingBlock:^(id<NEEventTracingClickObserver>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) { \
            if ([obj conformsToProtocol:@protocol(Protocol)]) { \
                [observers addObject:(id<Protocol>)obj]; \
            } \
        }]; \
    } UNLOCK \
    \
    return observers.copy; \
}

#define TargetObserversForTargetMethod(Method, Protocol, Cls, Property) \
- (NSArray<id<Protocol>> *)Method:(Cls *)target { \
    NSArray<id<Protocol>> *observers = nil; \
    \
    RDLOCK { \
        observers = (NSArray<id<Protocol>> *)[self.Property objectForKey:target].allObjects; \
    } UNLOCK \
    \
    return nil; \
}

@implementation NEEventTracingClickMonitor (Control_TouchUpInside)
TargetObservedTargetsMethod(allTouchUpInsideObservedControls, UIControl, targetObservers)
TargetObserversMethod(allControlTouchUpInsideObservers, NEEventTracingClickControlTouchUpInsideObserver, UIControl, targetObservers)
TargetObserversForTargetMethod(controlTouchUpInsideObserversForControl, NEEventTracingClickControlTouchUpInsideObserver, UIControl, targetObservers)
@end

@implementation NEEventTracingClickMonitor (View_SingleTapGesture)
TargetObservedTargetsMethod(allSingleTapObservedViews, UIView, viewTargetObservers)
TargetObserversMethod(allViewSingleTapObservers, NEEventTracingClickViewSingleTapObserver, UIView, viewTargetObservers)
TargetObserversForTargetMethod(viewSingleTapObserversForView, NEEventTracingClickViewSingleTapObserver, UIView, viewTargetObservers)
@end

@implementation NEEventTracingClickMonitor (TableView_CellDidSelected)
TargetObservedTargetsMethod(allCellDidSelectedObservedTableViews, UITableView, targetObservers)
TargetObserversMethod(allTableCellDidSelectedObservers, NEEventTracingClickTableCellDidSelectedObserver, UITableView, targetObservers)
TargetObserversForTargetMethod(tableCellDidSelectedObserversForTableView, NEEventTracingClickTableCellDidSelectedObserver, UITableView, targetObservers)
@end

@implementation NEEventTracingClickMonitor (Collection_CellDidSelected)
TargetObservedTargetsMethod(allCellDidSelectedObservedCollectionViews, UICollectionView, targetObservers)
TargetObserversMethod(allCollectionCellDidSelectedObservers, NEEventTracingClickControlTouchUpInsideObserver, UICollectionView, targetObservers)
TargetObserversForTargetMethod(tableCellDidSelectedObserversForCollectionView, NEEventTracingClickControlTouchUpInsideObserver, UICollectionView, targetObservers)
@end

#undef TargetObservedTargetsMethod
#undef TargetObserversMethod
#undef TargetObserversForTargetMethod


@implementation UIControl (AOP_Observer_TouchUpInside)
- (NSArray<id<NEEventTracingClickControlTouchUpInsideObserver>> *)ne_et_clickObservers {
    return (NSArray<id<NEEventTracingClickControlTouchUpInsideObserver>> *)[[NEEventTracingClickMonitor sharedInstance] observersForView:self];
}

- (void)ne_et_addClickObserver:(id<NEEventTracingClickControlTouchUpInsideObserver>)observer {
    [[NEEventTracingClickMonitor sharedInstance] _doAddTargetObserver:observer forView:self isOnlyView:NO];
}
- (void)ne_et_removeClickObserver:(id<NEEventTracingClickControlTouchUpInsideObserver>)observer {
    [[NEEventTracingClickMonitor sharedInstance] _doRemoveTargetObserver:observer forView:self isOnlyView:NO];
}
@end

@implementation UIView (AOP_Observer_SingleTapGesture)
- (NSArray<id<NEEventTracingClickViewSingleTapObserver>> *)ne_et_clickObservers {
    return (NSArray<id<NEEventTracingClickViewSingleTapObserver>> *)[[NEEventTracingClickMonitor sharedInstance] observersForView:self];
}
- (void)ne_et_addClickObserver:(id<NEEventTracingClickViewSingleTapObserver>)observer {
    [[NEEventTracingClickMonitor sharedInstance] _doAddTargetObserver:observer forView:self isOnlyView:YES];
}
- (void)ne_et_removeClickObserver:(id<NEEventTracingClickViewSingleTapObserver>)observer {
    [[NEEventTracingClickMonitor sharedInstance] _doRemoveTargetObserver:observer forView:self isOnlyView:YES];
}
@end

@implementation UITableView (AOP_Observer_CellDidSelected)
- (NSArray<id<NEEventTracingClickTableCellDidSelectedObserver>> *)ne_et_clickObservers {
    return (NSArray<id<NEEventTracingClickTableCellDidSelectedObserver>> *)[[NEEventTracingClickMonitor sharedInstance] observersForView:self];
}

- (void)ne_et_addClickObserver:(id<NEEventTracingClickTableCellDidSelectedObserver>)observer {
    [[NEEventTracingClickMonitor sharedInstance] _doAddTargetObserver:observer forView:self isOnlyView:NO];
}
- (void)ne_et_removeClickObserver:(id<NEEventTracingClickTableCellDidSelectedObserver>)observer {
    [[NEEventTracingClickMonitor sharedInstance] _doRemoveTargetObserver:observer forView:self isOnlyView:NO];
}
@end

@implementation UICollectionView (AOP_Observer_CellDidSelected)
- (NSArray<id<NEEventTracingClickCollectionCellDidSelectedObserver>> *)ne_et_clickObservers {
    return (NSArray<id<NEEventTracingClickCollectionCellDidSelectedObserver>> *)[[NEEventTracingClickMonitor sharedInstance] observersForView:self];
}

- (void)ne_et_addClickObserver:(id<NEEventTracingClickCollectionCellDidSelectedObserver>)observer {
    [[NEEventTracingClickMonitor sharedInstance] _doAddTargetObserver:observer forView:self isOnlyView:NO];
}
- (void)ne_et_removeClickObserver:(id<NEEventTracingClickCollectionCellDidSelectedObserver>)observer {
    [[NEEventTracingClickMonitor sharedInstance] _doRemoveTargetObserver:observer forView:self isOnlyView:NO];
}
@end
