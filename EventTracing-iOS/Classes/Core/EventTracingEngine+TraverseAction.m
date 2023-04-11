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

@interface EventTracingStockedTraverseActionRecord()
@property(nonatomic, strong) NSMutableArray<EventTracingTraverseAction *> *innerActions;
@end
@implementation EventTracingStockedTraverseActionRecord
@synthesize passthrough = _passthrough;

- (instancetype)init {
    self = [super init];
    if (self) {
        _innerActions = [NSMutableArray array];
    }
    return self;
}

- (void)actionDidOccured:(EventTracingTraverseAction *)action {
    if (_passthrough) {
        return;
    }
    
    if (action.viewIsNil) {
        _passthrough = YES;
        [_innerActions removeAllObjects];
        
        return;
    }
    
    [_innerActions addObject:action];
}

- (void)reset {
    _passthrough = NO;
    [_innerActions removeAllObjects];
}

- (NSArray<EventTracingTraverseAction *> *)actions {
    return _innerActions.copy;
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
        if (!self.stockedTraverseActionRecord) {
            self.stockedTraverseActionRecord = [[EventTracingStockedTraverseActionRecord alloc] init];
        }
        
        [self.stockedTraverseActionRecord actionDidOccured:action];
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
