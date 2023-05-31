//
//  NEEventTracingEventAction.m
//  NEEventTracing
//
//  Created by dl on 2021/4/8.
//

#import "NEEventTracingEventAction.h"

@implementation NEEventTracingEventAction

+ (instancetype) actionWithEvent:(NSString *)event view:(UIView *)view {
    NEEventTracingEventAction *action = [[NEEventTracingEventAction alloc] init];
    action.event = event;
    action.view = view;
    return action;
}

- (void)syncFromActionConfig:(NEEventTracingEventActionConfig *)config {
    self.increaseActseq = config.increaseActseq;
    self.useForRefer = config.useForRefer;
}

- (void)setupNode:(NEEventTracingVTreeNode *)node VTree:(NEEventTracingVTree *)VTree {
    self.node = node;
    self.VTree = VTree;
}

@end
