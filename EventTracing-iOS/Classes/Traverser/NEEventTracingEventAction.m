//
//  EventTracingEventAction.m
//  EventTracing
//
//  Created by dl on 2021/4/8.
//

#import "EventTracingEventAction.h"

@implementation EventTracingEventAction

+ (instancetype) actionWithEvent:(NSString *)event view:(UIView *)view {
    EventTracingEventAction *action = [[EventTracingEventAction alloc] init];
    action.event = event;
    action.view = view;
    return action;
}

- (void)syncFromActionConfig:(EventTracingEventActionConfig *)config {
    self.increaseActseq = config.increaseActseq;
    self.useForRefer = config.useForRefer;
}

- (void)setupNode:(EventTracingVTreeNode *)node VTree:(EventTracingVTree *)VTree {
    self.node = node;
    self.VTree = VTree;
}

@end
