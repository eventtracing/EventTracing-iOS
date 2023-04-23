//
//  EventTracingEventAction.h
//  EventTracing
//
//  Created by dl on 2021/4/8.
//

#import <Foundation/Foundation.h>
#import "EventTracingVTree.h"

NS_ASSUME_NONNULL_BEGIN

@interface EventTracingEventAction : NSObject

@property(nonatomic, assign) BOOL increaseActseq;
@property(nonatomic, assign) BOOL useForRefer;

@property(nonatomic, copy, nullable) NSDictionary<NSString *, NSString *> *params;
@property(nonatomic, copy, nullable) NSDictionary<NSString *, NSString *> *contextParams;

@property(nonatomic, copy) NSString *event;
@property(nonatomic, weak) UIView *view;

@property(nonatomic, strong) EventTracingVTreeNode *node;
@property(nonatomic, strong) EventTracingVTree *VTree;

+ (instancetype)actionWithEvent:(NSString *)event view:(UIView *)view;
- (void)syncFromActionConfig:(EventTracingEventActionConfig *)config;

- (void)setupNode:(EventTracingVTreeNode *)node VTree:(EventTracingVTree *)VTree;

@end

NS_ASSUME_NONNULL_END
