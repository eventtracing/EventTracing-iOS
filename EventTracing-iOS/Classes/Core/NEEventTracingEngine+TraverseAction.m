//
//  NEEventTracingEngine+Traverse.m
//  NEEventTracing
//
//  Created by dl on 2021/4/13.
//

#import "NEEventTracingEngine+TraverseAction.h"
#import "NEEventTracingEngine+Private.h"
#import <BlocksKit/BlocksKit.h>

@implementation NEEventTracingTraverseAction
@synthesize view = _view;
@synthesize viewIsNil = _viewIsNil;

+ (instancetype)actionWithView:(UIView * _Nullable)view {
    NEEventTracingTraverseAction *action = [[NEEventTracingTraverseAction alloc] init];
    action->_view = view;
    action->_viewIsNil = view == nil;
    return action;
}
@end

@interface NEEventTracingStockedTraverseActionRecord()
@property(nonatomic, strong) NSMutableArray<NEEventTracingTraverseAction *> *innerActions;
@end
@implementation NEEventTracingStockedTraverseActionRecord
@synthesize passthrough = _passthrough;

- (instancetype)init {
    self = [super init];
    if (self) {
        _innerActions = [NSMutableArray array];
    }
    return self;
}

- (void)actionDidOccured:(NEEventTracingTraverseAction *)action {
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

- (NSArray<NEEventTracingTraverseAction *> *)actions {
    return _innerActions.copy;
}

@end

@implementation NEEventTracingEngine (TraverseAction)

- (void)traverse:(UIView * _Nullable)view {
    [self traverse:view traverseAction:nil];
}

- (void)traverse:(UIView *)view traverseAction:(void (^ NS_NOESCAPE _Nullable)(NEEventTracingTraverseAction * _Nonnull))block {
    /// MARK: 后台情况下，直接忽略树的构建
    if (!self.context.isAppInActive) {
        return;
    }
    
    NEEventTracingTraverseAction *action = [NEEventTracingTraverseAction actionWithView:view];
    !block ?: block(action);
    
    void(^insertToStockedActions)(void) = ^() {
        if (!self.stockedTraverseActionRecord) {
            self.stockedTraverseActionRecord = [[NEEventTracingStockedTraverseActionRecord alloc] init];
        }
        
        [self.stockedTraverseActionRecord actionDidOccured:action];
    };
    
    NEETDispatchMainAsyncSafe(insertToStockedActions);
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
