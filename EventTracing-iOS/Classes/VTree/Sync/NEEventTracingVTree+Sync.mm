//
//  NEEventTracingVTree+Sync.m
//  BlocksKit
//
//  Created by dl on 2021/3/25.
//

#import "NEEventTracingVTree+Sync.h"
#import "NEEventTracingVTree+Private.h"
#import "NEEventTracingVTreeNode+Private.h"

#import "NEEventTracingDiffable.h"
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

static id<NSObject> ETVTreeSyncTableKey(__unsafe_unretained id<NEEventTracingDiffable> object) {
    id<NSObject> key = [object ne_et_diffIdentifier];
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

@implementation NEEventTracingVTree (Sync)

- (void)syncToVTree:(NEEventTracingVTree *)VTree {
    [self _syncToVTree:VTree matchBlock:^(NEEventTracingVTreeNode *fromNode, NEEventTracingVTreeNode *toNode) {
        [fromNode syncToNode:toNode];
    }];
}

- (void)_syncToVTree:(NEEventTracingVTree *)VTree
          matchBlock:(void(^)(NEEventTracingVTreeNode *fromNode, NEEventTracingVTreeNode *toNode))block {
    
    if (!block) {
        return;
    }
    
    NSArray<NEEventTracingVTreeNode *> *fromNodes = [self flattenNodes];
    NSUInteger fromCount = fromNodes.count;
    if (fromCount == 0) {
        return;
    }
    
    NSArray<NEEventTracingVTreeNode *> *toNodes = [VTree flattenNodes];
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
            NEEventTracingVTreeNode *fromNode = fromNodes[entry.fromIdx];
            NEEventTracingVTreeNode *toNode = toNodes[i];
            
            block(fromNode, toNode);
        }
    }
}

- (void)syncNodeDynamicParamsForNode:(NEEventTracingVTreeNode *)node event:(NSString *)event {
    [node enumerateAncestorNodeWithBlock:^(NEEventTracingVTreeNode * _Nonnull ancestorNode, BOOL * _Nonnull stop) {
        [ancestorNode refreshDynsmicParamsIfNeededForEvent:event];
    }];
}

- (void)increaseActseqFromOtherTree:(NEEventTracingVTree *)otherTree node:(NEEventTracingVTreeNode *)node {
    NEEventTracingVTreeNode *toppestNode = [node findToppestNode:NO];
    
    [self.rootNode.subNodes ne_et_enumerateObjectsUsingBlock:^NSArray<NEEventTracingVTreeNode *> * _Nonnull(NEEventTracingVTreeNode * _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj ne_et_isEqualToDiffableObject:toppestNode]) {
            [obj doIncreaseActseq];
            *stop = YES;
        }
        return obj.subNodes;
    }];
}

@end
