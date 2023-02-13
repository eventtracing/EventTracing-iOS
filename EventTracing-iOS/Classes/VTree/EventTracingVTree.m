//
//  EventTracingVTree.m
//  EventTracing
//
//  Created by dl on 2021/2/26.
//

#import "EventTracingVTree.h"
#import "EventTracingVTree+Private.h"
#import "EventTracingVTreeNode+Private.h"
#import "EventTracingVTreeNode+Visible.h"

#import "EventTracingTraverser.h"
#import "UIView+EventTracingPrivate.h"
#import "NSArray+ETEnumerator.h"

#import <BlocksKit/BlocksKit.h>

@implementation EventTracingVTree
@synthesize stable = _stable;
@synthesize visible = _visible;
@synthesize rootPageNode = _rootPageNode;

- (instancetype)init {
    self = [super init];
    if (self) {
        _lock = dispatch_semaphore_create(1);
        
        _rootNode = [[EventTracingVTreeNode alloc] init];
        [_rootNode markAsRoot];
        
        [self regenerateVTreeIdentifier];
    }
    return self;
}

+ (instancetype)emptyVTree {
    static EventTracingVTree *emptyVTree;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        emptyVTree = [[EventTracingVTree alloc] init];
    });
    return emptyVTree;
}

- (void)pushNode:(EventTracingVTreeNode *)node parentNode:(EventTracingVTreeNode * _Nullable)parentNode ignoreParentValid:(BOOL)ignoreParentValid {
    __block EventTracingVTreeNode *validParentNode = parentNode;
    if (!ignoreParentValid && parentNode) {
        /// MARK: 如果父节点明确声明了只能存在哪几个子节点，则严格控制，其他节点不可挂载该名下
        /// MARK: 排除场景 => 1. 自动挂载;
        if (parentNode.validForContainingSubNodeOids.count > 0 && ![parentNode.validForContainingSubNodeOids containsObject:node.oid]) {
            validParentNode = nil;
        }
    }
    
    if (!validParentNode) {
        [_rootNode pushSubNode:node];
    } else {
        [validParentNode pushSubNode:node];
    }
}

- (void)removeNode:(EventTracingVTreeNode *)node {
    [_rootNode removeSubNode:node];
}

- (BOOL)containsNode:(EventTracingVTreeNode *)node {
    return [self.flattenNodes containsObject:node];
}

- (EventTracingVTreeNode * _Nullable)findRootPageNodeFromNode:(EventTracingVTreeNode *)node {
    return [node findToppestNode:YES];
}

- (EventTracingVTreeNode * _Nullable)findToppestRightPageNode {
    __block EventTracingVTreeNode *toppestPageNode = nil;
    
    // MARK: 右侧深度遍历，找到第一个page节点
    [self.rootNode.subNodes et_enumerateObjectsWithType:EventTracingEnumeratorTypeBFSRight usingBlock:^NSArray<EventTracingVTreeNode *> * _Nonnull(EventTracingVTreeNode * _Nonnull nextNode, BOOL * _Nonnull stop) {
        if (nextNode.isPageNode && !nextNode.hasSubPageNodeMarkAsRootPage) {
            toppestPageNode = nextNode;
            
            *stop = YES;
        }
        
        return nextNode.subNodes;
    }];
    
    /// MARK: 更新 rootpage 节点
    _rootPageNode = toppestPageNode;
    
    return toppestPageNode;
}

- (EventTracingVTreeNode * _Nullable)findNodeByDiffIdentifier:(id<NSObject>)diffIdentifier {
    __block EventTracingVTreeNode *node = nil;
    [self.rootNode.subNodes et_enumerateObjectsUsingBlock:^NSArray<EventTracingVTreeNode *> * _Nonnull(EventTracingVTreeNode * _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj.et_diffIdentifier isEqual:diffIdentifier]) {
            node = obj;
            *stop = YES;
        }
        return obj.subNodes;
    }];
    return node;
}

- (NSArray<EventTracingVTreeNode *> *)flattenNodes {
    NSMutableArray<EventTracingVTreeNode *> *nodes = [@[] mutableCopy];
    
    [self.rootNode.subNodes et_enumerateObjectsWithType:EventTracingEnumeratorTypeDFS usingBlock:^NSArray<EventTracingVTreeNode *> * _Nonnull(EventTracingVTreeNode * _Nonnull obj, BOOL * _Nonnull stop) {
        [nodes addObject:obj];
        return obj.subNodes;
    }];
    
    return nodes.copy;
}

- (void)VTreeDidBecomeStable {
    _stable = YES;
}

- (void)VTreeMarkUnStable {
    _stable = NO;
}

- (void)markVTreeVisible:(BOOL)visible {
    _visible = visible;
}

- (void)regenerateVTreeIdentifier {
    unsigned long long time = [NSDate date].timeIntervalSince1970 * 1000;
    uint32_t randomNumber = arc4random() % 900 + 100;
    _identifier = [NSString stringWithFormat:@"%@#%llu#%u", [NSUUID UUID].UUIDString, time, randomNumber];
}

#pragma mark - NSCopying
- (id)copyWithZone:(nullable NSZone *)zone {
    EventTracingVTree *VTree = [[EventTracingVTree alloc] init];
    VTree.identifier = self.identifier.copy;
    VTree->_stable = self.stable;
    VTree->_visible = self.visible;
    VTree->_rootNode = self.rootNode.copy;
    [@[VTree->_rootNode] et_enumerateObjectsUsingBlock:^NSArray<EventTracingVTreeNode *> * _Nonnull(EventTracingVTreeNode * _Nonnull obj, BOOL * _Nonnull stop) {
        [obj associateToVTree:VTree];
        return obj.subNodes;
    }];
    return VTree;
}

- (BOOL)isEaualToOtherVTree:(EventTracingVTree *)otherVTree {
    if (otherVTree == self) {
        return YES;
    }
    
    if (![otherVTree isKindOfClass:self.class]) {
        return NO;
    }
    
    if (_visible != [(EventTracingVTree *)otherVTree isVisible]) {
        return NO;
    }
    
    NSArray<EventTracingVTreeNode *> *selfNodes = self.flattenNodes;
    NSArray<EventTracingVTreeNode *> *otherNodes = [(EventTracingVTree *)otherVTree flattenNodes];
    
    if (selfNodes.count != otherNodes.count) {
        return NO;
    }
    
    __block BOOL equal = YES;
    [selfNodes enumerateObjectsUsingBlock:^(EventTracingVTreeNode * _Nonnull selfNode, NSUInteger idx, BOOL * _Nonnull stop) {
        EventTracingVTreeNode *otherNode = [otherNodes objectAtIndex:idx];
        if (![selfNode et_isEqualToDiffableObject:otherNode]) {
            equal = NO;
            *stop = YES;
        }
    }];
    
    return equal;
}

#pragma mark - getters
- (NSUInteger)hash {
    return [self description].hash;
}

#pragma mark - debug
- (NSDictionary *)debugJson {
    NSMutableDictionary *json = [@{} mutableCopy];
    [json setValue:@(_stable).stringValue forKey:@"_stable"];
    [json setValue:@(_visible).stringValue forKey:@"_visible"];
    
    if (self.rootNode.subNodes.count) {
        [json setObject:[self.rootNode.subNodes bk_map:^id(EventTracingVTreeNode *obj) {
            return obj.debugJson;
        }] forKey:@"nodes"];
    }
    return json.copy;
}

- (NSString *)debugJsonString {
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:[self debugJson] options:NSJSONWritingPrettyPrinted error:nil];
    NSString *jsonFormateString = [[NSString alloc]initWithData:jsonData encoding:NSUTF8StringEncoding];
    return jsonFormateString;
}

- (NSString *)description {
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self.debugJson options:0 error:nil];
    NSString *jsonString = [[NSString alloc]initWithData:jsonData encoding:NSUTF8StringEncoding];
    return jsonString;
}

@end

@implementation EventTracingVTree (Geometry)

#pragma mark - Geometry
- (EventTracingVTreeNode * _Nullable)hitTest:(CGPoint)point {
    return [self hitTest:point pageOnly:NO];
}

- (EventTracingVTreeNode * _Nullable)hitTest:(CGPoint)point pageOnly:(BOOL)pageOnly {
    return [self.rootNode hitTest:point pageOnly:pageOnly];
}

- (EventTracingVTreeNode * _Nullable)nodeForSpm:(NSString *)spm {
    if (!self.rootNode) {
        return nil;
    }
    
    __block EventTracingVTreeNode *foundedNode = nil;
    [@[self.rootNode] et_enumerateObjectsUsingBlock:^NSArray<EventTracingVTreeNode *> * _Nonnull(EventTracingVTreeNode * _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj.spm isEqualToString:spm]) {
            foundedNode = obj;
            *stop = YES;
        }
        return obj.subNodes;
    }];
    
    return foundedNode;
}

- (UIView * _Nullable)nodeViewForSpm:(NSString *)spm {
    return [self nodeForSpm:spm].view;
}

@end
