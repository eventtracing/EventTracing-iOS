//
//  EventTracingEngine+Traverse.m
//  EventTracing
//
//  Created by dl on 2021/4/13.
//

#import "EventTracingEngine+TraverseAction.h"
#import "EventTracingEngine+Private.h"
#import <BlocksKit/BlocksKit.h>

@implementation EventTracingTraverseAction
@synthesize view = _view;
@synthesize viewIsNil = _viewIsNil;

+ (instancetype)actionWithView:(UIView * _Nullable)view {
    EventTracingTraverseAction *action = [[EventTracingTraverseAction alloc] init];
    action->_view = view;
    action->_viewIsNil = view == nil;
    return action;
}
@end

@implementation EventTracingEngine (TraverseAction)

- (void)traverse:(UIView * _Nullable)view {
    [self traverse:view traverseAction:nil];
}

- (void)traverse:(UIView *)view traverseAction:(void (^ NS_NOESCAPE _Nullable)(EventTracingTraverseAction * _Nonnull))block {
    /// MARK: 后台情况下，直接忽略树的构建
    if (!self.context.isAppInActive) {
        return;
    }
    
    EventTracingTraverseAction *action = [EventTracingTraverseAction actionWithView:view];

    !block ?: block(action);
    
    void(^insertToStockedActions)(void) = ^() {
        /// MARK: 对于同一个view的变动，一个周期内仅需添加一次即可
        if (!action.viewIsNil) {
            BOOL hasAddedThisView = [self.stockedTraverseActions bk_any:^BOOL(EventTracingTraverseAction *action) {
                return action.view == view;
            }];
            if (hasAddedThisView) {
                return;
            }
        }
        
        if (!self.stockedTraverseActions) {
            self.stockedTraverseActions = @[].mutableCopy;
        }
        
        if (action.viewIsNil) {
            [self.stockedTraverseActions insertObject:action atIndex:0];
        } else {
            [self.stockedTraverseActions addObject:action];
        }
    };
    
    ETDispatchMainAsyncSafe(insertToStockedActions);
}

- (void)traverseForScrollView:(UIScrollView *)scrollView {
    if (![scrollView isKindOfClass:UIScrollView.class] || [self.stockedTraverseScrollViews containsObject:scrollView]) {
        return;
    }
    
    if (!self.stockedTraverseScrollViews) {
        self.stockedTraverseScrollViews = [NSHashTable hashTableWithOptions:NSPointerFunctionsWeakMemory];
    }
    
    [self.stockedTraverseScrollViews addObject:scrollView];
}

@end
