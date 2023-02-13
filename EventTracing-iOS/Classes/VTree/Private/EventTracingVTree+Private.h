//
//  EventTracingVTree+Private.h
//  EventTracing
//
//  Created by dl on 2021/3/12.
//

#import "EventTracingVTree.h"

NS_ASSUME_NONNULL_BEGIN

#define LOCK        dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
#define UNLOCK      dispatch_semaphore_signal(_lock);

@interface EventTracingVTree ()

@property(nonnull, strong) dispatch_semaphore_t lock;
@property(nonatomic, copy) NSString *identifier;

@property(nonatomic, strong, readonly) NSArray<EventTracingVTreeNode *> *flattenNodes;

+ (instancetype)emptyVTree;
- (void)VTreeDidBecomeStable;
- (void)VTreeMarkUnStable;
- (void)markVTreeVisible:(BOOL)visible;
- (void)regenerateVTreeIdentifier;

- (void)pushNode:(EventTracingVTreeNode *)node parentNode:(EventTracingVTreeNode * _Nullable)parentNode ignoreParentValid:(BOOL)ignoreParentValid;
- (void)removeNode:(EventTracingVTreeNode *)node;

// 自动逻辑挂载
- (EventTracingVTreeNode * _Nullable)findNodeByDiffIdentifier:(id<NSObject>)diffIdentifier;

@end

NS_ASSUME_NONNULL_END
