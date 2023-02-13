//
//  EventTracingVTree+Sync.m
//  BlocksKit
//
//  Created by dl on 2021/3/25.
//

#import "EventTracingVTree+Sync.h"
#import "EventTracingVTree+Private.h"
#import "EventTracingVTreeNode+Private.h"

#import "EventTracingDiffable.h"
#import "NSArray+ETEnumerator.h"
#import "UIView+EventTracingPrivate.h"

#import <stack>
#import <unordered_map>
#import <vector>

using namespace std;
/// 记录遍历过程中new old的个数
struct ETVTreeSyncEntry {
    NSInteger fromIdx = NSNotFound;
};

static id<NSObject> ETVTreeSyncTableKey(__unsafe_unretained id<EventTracingDiffable> object) {
    id<NSObject> key = [object et_diffIdentifier];
    NSCAssert(key != nil, @"Cannot use a nil key for the diffIdentifier of object %@", object);
    return key;
}

struct ETVTreeSyncHashID {
    size_t operator()(const id o) const {
        return (size_t)[o hash];
    }
};

struct ETVTreeSyncEqualID {
    bool operator()(const id a, const id b) const {
        return (a == b) || [a isEqual: b];
    }
};

@implementation EventTracingVTree (Sync)

- (void)syncToVTree:(EventTracingVTree *)VTree {
    [self _syncToVTree:VTree matchBlock:^(EventTracingVTreeNode *fromNode, EventTracingVTreeNode *toNode) {
        [fromNode syncToNode:toNode];
    }];
}

- (void)_syncToVTree:(EventTracingVTree *)VTree
          matchBlock:(void(^)(EventTracingVTreeNode *fromNode, EventTracingVTreeNode *toNode))block {
    
    if (!block) {
        return;
    }
    
    NSArray<EventTracingVTreeNode *> *fromNodes = [self flattenNodes];
    NSUInteger fromCount = fromNodes.count;
    if (fromCount == 0) {
        return;
    }
    
    NSArray<EventTracingVTreeNode *> *toNodes = [VTree flattenNodes];
    NSUInteger toCount = toNodes.count;
    if (toCount == 0) {
        return;
    }
    
    unordered_map<id<NSObject>, ETVTreeSyncEntry, ETVTreeSyncHashID, ETVTreeSyncEqualID> table;
    
    for (int i=0; i<fromCount; i++) {
        id<NSObject> key = ETVTreeSyncTableKey(fromNodes[i]);
        ETVTreeSyncEntry &entry = table[key];
        entry.fromIdx = i;
    }
    
    for (int i=0; i<toCount; i++) {
        id<NSObject> key = ETVTreeSyncTableKey(toNodes[i]);
        ETVTreeSyncEntry &entry = table[key];
        
        if (entry.fromIdx != NSNotFound) {
            EventTracingVTreeNode *fromNode = fromNodes[entry.fromIdx];
            EventTracingVTreeNode *toNode = toNodes[i];
            
            block(fromNode, toNode);
        }
    }
}

- (void)syncNodeDynamicParamsForNode:(EventTracingVTreeNode *)node event:(NSString *)event {
    [node enumerateAncestorNodeWithBlock:^(EventTracingVTreeNode * _Nonnull ancestorNode, BOOL * _Nonnull stop) {
        [ancestorNode refreshDynsmicParamsIfNeededForEvent:event];
    }];
}

- (void)increaseActseqFromOtherTree:(EventTracingVTree *)otherTree node:(EventTracingVTreeNode *)node {
    EventTracingVTreeNode *toppestNode = [node findToppestNode:NO];
    
    [self.rootNode.subNodes et_enumerateObjectsUsingBlock:^NSArray<EventTracingVTreeNode *> * _Nonnull(EventTracingVTreeNode * _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj et_isEqualToDiffableObject:toppestNode]) {
            [obj doIncreaseActseq];
            *stop = YES;
        }
        return obj.subNodes;
    }];
}

@end
