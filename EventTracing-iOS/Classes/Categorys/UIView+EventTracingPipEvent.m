//
//  UIView+EventTracingPipEvent.m
//  EventTracing
//
//  Created by dl on 2021/7/22.
//

#import "UIView+EventTracingPipEvent.h"
#import "UIView+EventTracingPrivate.h"
#import "EventTracingReferFuncs.h"
#import "EventTracingTraverser.h"
#import "EventTracingUIScrollViewAOP.h"

#import <BlocksKit/BlocksKit.h>
#import <objc/runtime.h>

@implementation UIView (EventTracingPipEventInternal)
void *objc_key_et_pipEventViews = &objc_key_et_pipEventViews;
- (NSMutableDictionary<NSString *,NSHashTable<UIView *> *> *)et_pipEventViews {
    return objc_getAssociatedObject(self, objc_key_et_pipEventViews);
}

void *objc_key_et_pipEventToView = &objc_key_et_pipEventToView;
- (NSMapTable<NSString *,UIView *> *)et_pipEventToView {
    return objc_getAssociatedObject(self, objc_key_et_pipEventToView);
}
@end

@implementation UIView (EventTracingPipEvent)

- (void)et_pipEventClickToView:(UIView *)view {
    [self et_pipEvent:ET_EVENT_ID_E_CLCK toView:view];
}
- (void)et_pipEvent:(NSString *)event toView:(UIView *)view {
    if (!ET_isPageOrElement(view) || ET_isPageOrElement(self)) {
        return;
    }
    
    // current view
    [self _lazySetupPipEventToViewIfNeeded];
    [self.et_pipEventToView setObject:view forKey:event];
    
    // target view
    [view _lazySetupPipEventViewsIfNeeded];
    NSHashTable<UIView *> *views = [view.et_pipEventViews objectForKey:event];
    if (!views) {
        views = [NSHashTable hashTableWithOptions:NSPointerFunctionsWeakMemory];
        [view.et_pipEventViews setObject:views forKey:event];
    }
    [views addObject:self];
    
    if ([event isEqualToString:ET_EVENT_ID_E_SLIDE]) {
        [view et_addImpressObserver:[EventTracingUIScrollViewAOP AOPInstance]];
    }
}

- (void)et_pipEventClickToAncestorNodeViewOid:(NSString *)oid {
    UIView *view = ET_FindAncestorNodeViewAt(self, oid);
    if (!view) {
        return;
    }
    
    [self et_pipEventClickToView:view];
}
- (void)et_pipEventClickToAncestorNodeView {
    UIView *view = ET_FindAncestorNodeViewAt(self);
    if (!view) {
        return;
    }
    
    [self et_pipEventClickToView:view];
}

- (void)et_pipEvent:(NSString *)event toAncestorNodeViewOid:(NSString *)oid {
    UIView *view = ET_FindAncestorNodeViewAt(self, oid);
    if (!view) {
        return;
    }
    
    [self et_pipEvent:event toView:view];
}
- (void)et_pipEventToAncestorNodeView:(NSString *)event {
    UIView *view = ET_FindAncestorNodeViewAt(self);
    if (!view) {
        return;
    }
    
    [self et_pipEvent:event toView:view];
}

- (void)et_cancelPipEvent {
    [self.et_pipEventToView.keyEnumerator.allObjects enumerateObjectsUsingBlock:^(NSString * _Nonnull event, NSUInteger idx, BOOL * _Nonnull stop) {
        UIView *view = [self.et_pipEventToView objectForKey:event];
        [view.et_pipEventViews.objectEnumerator.allObjects enumerateObjectsUsingBlock:^(NSHashTable<UIView *> * _Nonnull views, NSUInteger idx, BOOL * _Nonnull stop) {
            [views removeObject:view];
            
            if ([event isEqualToString:ET_EVENT_ID_E_SLIDE]) {
                [view et_addImpressObserver:[EventTracingUIScrollViewAOP AOPInstance]];
            }
        }];
    }];
    [self.et_pipEventToView removeAllObjects];
}

#pragma setter & getter
- (void)_lazySetupPipEventToViewIfNeeded {
    NSMapTable<NSString *,UIView *> *pipEventToView = [self et_pipEventToView];
    if (!pipEventToView) {
        pipEventToView = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsCopyIn valueOptions:NSPointerFunctionsWeakMemory];
        objc_setAssociatedObject(self, objc_key_et_pipEventToView, pipEventToView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}


- (void)_lazySetupPipEventViewsIfNeeded {
    NSMutableDictionary <NSString *,NSHashTable<UIView *> *> *pipEventViews = [self et_pipEventViews];
    if (!pipEventViews) {
        pipEventViews = @{}.mutableCopy;
        objc_setAssociatedObject(self, objc_key_et_pipEventViews, pipEventViews, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

- (NSDictionary<NSString *,NSArray<UIView *> *> *)et_pipedToMeEventViews {
    NSMutableDictionary *result = @{}.mutableCopy;
    [self.et_pipEventViews enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSHashTable<UIView *> * _Nonnull obj, BOOL * _Nonnull stop) {
        [result setObject:key forKey:obj.allObjects];
    }];
    return result.copy;
}

- (NSDictionary<NSString *,UIView *> *)et_pipTargetEventViews {
    return [self.et_pipEventToView dictionaryRepresentation];
}

@end
