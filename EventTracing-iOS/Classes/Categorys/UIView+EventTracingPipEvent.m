//
//  UIView+EventTracingPipEvent.m
//  NEEventTracing
//
//  Created by dl on 2021/7/22.
//

#import "UIView+EventTracingPipEvent.h"
#import "UIView+EventTracingPrivate.h"
#import "NEEventTracingReferFuncs.h"
#import "NEEventTracingTraverser.h"
#import "NEEventTracingUIScrollViewAOP.h"

#import <BlocksKit/BlocksKit.h>
#import <objc/runtime.h>

@implementation UIView (EventTracingPipEventInternal)
void *objc_key_ne_et_pipEventViews = &objc_key_ne_et_pipEventViews;
- (NSMutableDictionary<NSString *,NSHashTable<UIView *> *> *)ne_et_pipEventViews {
    return objc_getAssociatedObject(self, objc_key_ne_et_pipEventViews);
}

void *objc_key_ne_et_pipEventToView = &objc_key_ne_et_pipEventToView;
- (NSMapTable<NSString *,UIView *> *)ne_et_pipEventToView {
    return objc_getAssociatedObject(self, objc_key_ne_et_pipEventToView);
}
@end

@implementation UIView (EventTracingPipEvent)

- (void)ne_et_pipEventClickToView:(UIView *)view {
    [self ne_et_pipEvent:NE_ET_EVENT_ID_E_CLCK toView:view];
}
- (void)ne_et_pipEvent:(NSString *)event toView:(UIView *)view {
    if (!NE_ET_isPageOrElement(view) || NE_ET_isPageOrElement(self)) {
        return;
    }
    
    // current view
    [self _lazySetupPipEventToViewIfNeeded];
    [self.ne_et_pipEventToView setObject:view forKey:event];
    
    // target view
    [view _lazySetupPipEventViewsIfNeeded];
    NSHashTable<UIView *> *views = [view.ne_et_pipEventViews objectForKey:event];
    if (!views) {
        views = [NSHashTable hashTableWithOptions:NSPointerFunctionsWeakMemory];
        [view.ne_et_pipEventViews setObject:views forKey:event];
    }
    [views addObject:self];
    
    if ([event isEqualToString:NE_ET_EVENT_ID_E_SLIDE]) {
        [view ne_et_addImpressObserver:[NEEventTracingUIScrollViewAOP AOPInstance]];
    }
}

- (void)ne_et_pipEventClickToAncestorNodeViewOid:(NSString *)oid {
    UIView *view = NE_ET_FindAncestorNodeViewAt(self, oid);
    if (!view) {
        return;
    }
    
    [self ne_et_pipEventClickToView:view];
}
- (void)ne_et_pipEventClickToAncestorNodeView {
    UIView *view = NE_ET_FindAncestorNodeViewAt(self);
    if (!view) {
        return;
    }
    
    [self ne_et_pipEventClickToView:view];
}

- (void)ne_et_pipEvent:(NSString *)event toAncestorNodeViewOid:(NSString *)oid {
    UIView *view = NE_ET_FindAncestorNodeViewAt(self, oid);
    if (!view) {
        return;
    }
    
    [self ne_et_pipEvent:event toView:view];
}
- (void)ne_et_pipEventToAncestorNodeView:(NSString *)event {
    UIView *view = NE_ET_FindAncestorNodeViewAt(self);
    if (!view) {
        return;
    }
    
    [self ne_et_pipEvent:event toView:view];
}

- (void)ne_et_cancelPipEvent {
    [self.ne_et_pipEventToView.keyEnumerator.allObjects enumerateObjectsUsingBlock:^(NSString * _Nonnull event, NSUInteger idx, BOOL * _Nonnull stop) {
        UIView *view = [self.ne_et_pipEventToView objectForKey:event];
        [view.ne_et_pipEventViews.objectEnumerator.allObjects enumerateObjectsUsingBlock:^(NSHashTable<UIView *> * _Nonnull views, NSUInteger idx, BOOL * _Nonnull stop) {
            [views removeObject:view];
            
            if ([event isEqualToString:NE_ET_EVENT_ID_E_SLIDE]) {
                [view ne_et_addImpressObserver:[NEEventTracingUIScrollViewAOP AOPInstance]];
            }
        }];
    }];
    [self.ne_et_pipEventToView removeAllObjects];
}

#pragma setter & getter
- (void)_lazySetupPipEventToViewIfNeeded {
    NSMapTable<NSString *,UIView *> *pipEventToView = [self ne_et_pipEventToView];
    if (!pipEventToView) {
        pipEventToView = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsCopyIn valueOptions:NSPointerFunctionsWeakMemory];
        objc_setAssociatedObject(self, objc_key_ne_et_pipEventToView, pipEventToView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}


- (void)_lazySetupPipEventViewsIfNeeded {
    NSMutableDictionary <NSString *,NSHashTable<UIView *> *> *pipEventViews = [self ne_et_pipEventViews];
    if (!pipEventViews) {
        pipEventViews = @{}.mutableCopy;
        objc_setAssociatedObject(self, objc_key_ne_et_pipEventViews, pipEventViews, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

- (NSDictionary<NSString *,NSArray<UIView *> *> *)ne_et_pipedToMeEventViews {
    NSMutableDictionary *result = @{}.mutableCopy;
    [self.ne_et_pipEventViews enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSHashTable<UIView *> * _Nonnull obj, BOOL * _Nonnull stop) {
        [result setObject:key forKey:obj.allObjects];
    }];
    return result.copy;
}

- (NSDictionary<NSString *,UIView *> *)ne_et_pipTargetEventViews {
    return [self.ne_et_pipEventToView dictionaryRepresentation];
}

@end
