//
//  EventTracingClickMonitor.m
//  EventTracing
//
//  Created by dl on 2022/7/14.
//

#import "EventTracingClickMonitor.h"
#import <pthread.h>
#import <BlocksKit/BlocksKit.h>

#define RDLOCK do { pthread_rwlock_rdlock(&self->_lock); } while (0);
#define WRLOCK do { pthread_rwlock_wrlock(&self->_lock); } while (0);
#define UNLOCK do { pthread_rwlock_unlock(&self->_lock); } while (0);

@interface EventTracingClickMonitor () {
    pthread_rwlock_t _lock;
}
@property(nonatomic, strong) NSHashTable<id<EventTracingClickObserver>> *globalObservers;

@property(nonatomic, strong) NSMapTable<UIView *, NSHashTable<id<EventTracingClickObserver>> *> *targetObservers;
@property(nonatomic, strong) NSMapTable<UIView *, NSHashTable<id<EventTracingClickObserver>> *> *viewTargetObservers;

- (void)_doAddTargetObserver:(id<EventTracingClickObserver>)observer forView:(UIView *)view isOnlyView:(BOOL)isOnlyView;
- (void)_doRemoveTargetObserver:(id<EventTracingClickObserver>)observer forView:(UIView *)view isOnlyView:(BOOL)isOnlyView;
@end

@implementation EventTracingClickMonitor

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
    static EventTracingClickMonitor *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[EventTracingClickMonitor alloc] init];
    });
    return instance;
}

- (void)addGlobalObserver:(id<EventTracingClickObserver>)observer {
    WRLOCK {
        [_globalObservers addObject:observer];
    } UNLOCK
}

- (void)removeGlobalObserver:(id<EventTracingClickObserver>)observer {
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

- (NSArray<EventTracingClickObserver> *)allObservers {
    NSMutableArray<EventTracingClickObserver> *observers = @[].mutableCopy;
    
    RDLOCK {
        [observers addObjectsFromArray:self.globalObservers.allObjects];

        [self.targetObservers.objectEnumerator.allObjects enumerateObjectsUsingBlock:^(NSHashTable<id<EventTracingClickObserver>> * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [observers addObjectsFromArray:obj.allObjects];
        }];

        [self.viewTargetObservers.objectEnumerator.allObjects enumerateObjectsUsingBlock:^(NSHashTable<id<EventTracingClickObserver>> * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [observers addObjectsFromArray:obj.allObjects];
        }];
    } UNLOCK
    
    return observers.copy;
}

- (NSArray<EventTracingClickObserver> *)allGlobalObservers {
    NSMutableArray<EventTracingClickObserver> *observers = @[].mutableCopy;
    
    RDLOCK {
        [observers addObjectsFromArray:self.globalObservers.allObjects];
    } UNLOCK
    
    return observers.copy;
}

- (NSArray<id<EventTracingClickObserver>> *)observersForView:(UIView *)view {
    NSMutableArray<id<EventTracingClickObserver>> *observers = @[].mutableCopy;
    
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

- (void)_doAddTargetObserver:(id<EventTracingClickObserver>)observer forView:(UIView *)view isOnlyView:(BOOL)isOnlyView {
    WRLOCK {
        NSHashTable<id<EventTracingClickObserver>> *observers = nil;
        observers = isOnlyView ? [self.viewTargetObservers objectForKey:view] : [self.targetObservers objectForKey:view];
        if (!observers) {
            observers = [NSHashTable weakObjectsHashTable];
        }
        isOnlyView ? [self.viewTargetObservers setObject:observers forKey:view] : [self.targetObservers setObject:observers forKey:view];
        
        [observers addObject:observer];
    } UNLOCK
}

- (void)_doRemoveTargetObserver:(id<EventTracingClickObserver>)observer forView:(UIView *)view isOnlyView:(BOOL)isOnlyView {
    WRLOCK {
        NSHashTable<id<EventTracingClickObserver>> *observers = isOnlyView ? [self.viewTargetObservers objectForKey:view] : [self.targetObservers objectForKey:view];        
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
        [self.globalObservers.objectEnumerator.allObjects enumerateObjectsUsingBlock:^(id<EventTracingClickObserver>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) { \
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

@implementation EventTracingClickMonitor (Control_TouchUpInside)
TargetObservedTargetsMethod(allTouchUpInsideObservedControls, UIControl, targetObservers)
TargetObserversMethod(allControlTouchUpInsideObservers, EventTracingClickControlTouchUpInsideObserver, UIControl, targetObservers)
TargetObserversForTargetMethod(controlTouchUpInsideObserversForControl, EventTracingClickControlTouchUpInsideObserver, UIControl, targetObservers)
@end

@implementation EventTracingClickMonitor (View_SingleTapGesture)
TargetObservedTargetsMethod(allSingleTapObservedViews, UIView, viewTargetObservers)
TargetObserversMethod(allViewSingleTapObservers, EventTracingClickViewSingleTapObserver, UIView, viewTargetObservers)
TargetObserversForTargetMethod(viewSingleTapObserversForView, EventTracingClickViewSingleTapObserver, UIView, viewTargetObservers)
@end

@implementation EventTracingClickMonitor (TableView_CellDidSelected)
TargetObservedTargetsMethod(allCellDidSelectedObservedTableViews, UITableView, targetObservers)
TargetObserversMethod(allTableCellDidSelectedObservers, EventTracingClickTableCellDidSelectedObserver, UITableView, targetObservers)
TargetObserversForTargetMethod(tableCellDidSelectedObserversForTableView, EventTracingClickTableCellDidSelectedObserver, UITableView, targetObservers)
@end

@implementation EventTracingClickMonitor (Collection_CellDidSelected)
TargetObservedTargetsMethod(allCellDidSelectedObservedCollectionViews, UICollectionView, targetObservers)
TargetObserversMethod(allCollectionCellDidSelectedObservers, EventTracingClickControlTouchUpInsideObserver, UICollectionView, targetObservers)
TargetObserversForTargetMethod(tableCellDidSelectedObserversForCollectionView, EventTracingClickControlTouchUpInsideObserver, UICollectionView, targetObservers)
@end

#undef TargetObservedTargetsMethod
#undef TargetObserversMethod
#undef TargetObserversForTargetMethod


@implementation UIControl (AOP_Observer_TouchUpInside)
- (NSArray<id<EventTracingClickControlTouchUpInsideObserver>> *)et_clickObservers {
    return (NSArray<id<EventTracingClickControlTouchUpInsideObserver>> *)[[EventTracingClickMonitor sharedInstance] observersForView:self];
}

- (void)et_addClickObserver:(id<EventTracingClickControlTouchUpInsideObserver>)observer {
    [[EventTracingClickMonitor sharedInstance] _doAddTargetObserver:observer forView:self isOnlyView:NO];
}
- (void)et_removeClickObserver:(id<EventTracingClickControlTouchUpInsideObserver>)observer {
    [[EventTracingClickMonitor sharedInstance] _doRemoveTargetObserver:observer forView:self isOnlyView:NO];
}
@end

@implementation UIView (AOP_Observer_SingleTapGesture)
- (NSArray<id<EventTracingClickViewSingleTapObserver>> *)et_clickObservers {
    return (NSArray<id<EventTracingClickViewSingleTapObserver>> *)[[EventTracingClickMonitor sharedInstance] observersForView:self];
}
- (void)et_addClickObserver:(id<EventTracingClickViewSingleTapObserver>)observer {
    [[EventTracingClickMonitor sharedInstance] _doAddTargetObserver:observer forView:self isOnlyView:YES];
}
- (void)et_removeClickObserver:(id<EventTracingClickViewSingleTapObserver>)observer {
    [[EventTracingClickMonitor sharedInstance] _doRemoveTargetObserver:observer forView:self isOnlyView:YES];
}
@end

@implementation UITableView (AOP_Observer_CellDidSelected)
- (NSArray<id<EventTracingClickTableCellDidSelectedObserver>> *)et_clickObservers {
    return (NSArray<id<EventTracingClickTableCellDidSelectedObserver>> *)[[EventTracingClickMonitor sharedInstance] observersForView:self];
}

- (void)et_addClickObserver:(id<EventTracingClickTableCellDidSelectedObserver>)observer {
    [[EventTracingClickMonitor sharedInstance] _doAddTargetObserver:observer forView:self isOnlyView:NO];
}
- (void)et_removeClickObserver:(id<EventTracingClickTableCellDidSelectedObserver>)observer {
    [[EventTracingClickMonitor sharedInstance] _doRemoveTargetObserver:observer forView:self isOnlyView:NO];
}
@end

@implementation UICollectionView (AOP_Observer_CellDidSelected)
- (NSArray<id<EventTracingClickCollectionCellDidSelectedObserver>> *)et_clickObservers {
    return (NSArray<id<EventTracingClickCollectionCellDidSelectedObserver>> *)[[EventTracingClickMonitor sharedInstance] observersForView:self];
}

- (void)et_addClickObserver:(id<EventTracingClickCollectionCellDidSelectedObserver>)observer {
    [[EventTracingClickMonitor sharedInstance] _doAddTargetObserver:observer forView:self isOnlyView:NO];
}
- (void)et_removeClickObserver:(id<EventTracingClickCollectionCellDidSelectedObserver>)observer {
    [[EventTracingClickMonitor sharedInstance] _doRemoveTargetObserver:observer forView:self isOnlyView:NO];
}
@end
