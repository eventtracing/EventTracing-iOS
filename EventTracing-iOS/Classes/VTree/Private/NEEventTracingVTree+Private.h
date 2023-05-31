//
//  NEEventTracingVTree+Private.h
//  NEEventTracing
//
//  Created by dl on 2021/3/12.
//

#import "NEEventTracingVTree.h"

NS_ASSUME_NONNULL_BEGIN

#define LOCK        dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
#define UNLOCK      dispatch_semaphore_signal(_lock);

@interface NEEventTracingVTree ()

@property(nonnull, strong) dispatch_semaphore_t lock;
@property(nonatomic, copy) NSString *identifier;

@property(nonatomic, strong, readonly) NSArray<NEEventTracingVTreeNode *> *flattenNodes;

+ (instancetype)emptyVTree;
- (void)VTreeDidBecomeStable;
- (void)VTreeMarkUnStable;
- (void)markVTreeVisible:(BOOL)visible;
- (void)regenerateVTreeIdentifier;

- (void)pushNode:(NEEventTracingVTreeNode *)node parentNode:(NEEventTracingVTreeNode * _Nullable)parentNode ignoreParentValid:(BOOL)ignoreParentValid;
- (void)removeNode:(NEEventTracingVTreeNode *)node;

// 自动逻辑挂载
- (NEEventTracingVTreeNode * _Nullable)findNodeByDiffIdentifier:(id<NSObject>)diffIdentifier;

@end

NS_ASSUME_NONNULL_END
