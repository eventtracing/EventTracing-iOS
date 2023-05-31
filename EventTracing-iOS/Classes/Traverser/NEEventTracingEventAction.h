//
//  NEEventTracingEventAction.h
//  NEEventTracing
//
//  Created by dl on 2021/4/8.
//

#import <Foundation/Foundation.h>
#import "NEEventTracingVTree.h"

NS_ASSUME_NONNULL_BEGIN

@interface NEEventTracingEventAction : NSObject

@property(nonatomic, assign) BOOL increaseActseq;
@property(nonatomic, assign) BOOL useForRefer;

@property(nonatomic, copy, nullable) NSDictionary<NSString *, NSString *> *params;
@property(nonatomic, copy, nullable) NSDictionary<NSString *, NSString *> *contextParams;

@property(nonatomic, copy) NSString *event;
@property(nonatomic, weak) UIView *view;

@property(nonatomic, strong) NEEventTracingVTreeNode *node;
@property(nonatomic, strong) NEEventTracingVTree *VTree;

+ (instancetype)actionWithEvent:(NSString *)event view:(UIView *)view;
- (void)syncFromActionConfig:(NEEventTracingEventActionConfig *)config;

- (void)setupNode:(NEEventTracingVTreeNode *)node VTree:(NEEventTracingVTree *)VTree;

@end

NS_ASSUME_NONNULL_END
