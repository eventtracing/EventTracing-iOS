//
//  EventTracingVTreeNode.m
//  EventTracing
//
//  Created by dl on 2021/2/26.
//

#import "EventTracingVTreeNode.h"
#import "EventTracingVTreeNode+Private.h"

#import "NSArray+ETEnumerator.h"
#import "EventTracingTraverser.h"
#import "EventTracingEngine+Private.h"
#import "UIView+EventTracingPrivate.h"
#import "EventTracingEventRefer+Private.h"

#import <BlocksKit/BlocksKit.h>

NSString * const kETAddParamCallbackObjectkey = @"__OBJECT__";

@implementation EventTracingVTreeNode
@synthesize VTree = _VTree;
@synthesize root = _root;
@synthesize virtualNode = _virtualNode;
@synthesize depth =_depth;

@synthesize identifier = _identifier;
@synthesize view = _view;
@synthesize buildinEventLogDisableStrategy = _buildinEventLogDisableStrategy;
@synthesize impressMaxRatio = _impressMaxRatio;
@synthesize isPageNode = _isPageNode;
@synthesize pageOcclusionEnable = _pageOcclusionEnable;

@synthesize oid = _oid;
@synthesize ignoreRefer = _ignoreRefer;
@synthesize pgrefer = _pgrefer;
@synthesize psrefer = _psrefer;
@synthesize pgstep = _pgstep;

@synthesize visible = _visible;
@synthesize blockedBySubPage = _blockedBySubPage;
@synthesize visibleRect = _visibleRect;
@synthesize visibleRectCalculateStrategy = _visibleRectCalculateStrategy;

// Inner
@synthesize innerStaticParams = _innerStaticParams;
@synthesize dynamicParams = _dynamicParams;
@synthesize callbackParams = _callbackParams;

@synthesize psreferMute = _psreferMute;

@synthesize subpagePvToReferEnable = _subpagePvToReferEnable;
@synthesize pageReferConsumeOption = _pageReferConsumeOption;

- (instancetype)init {
    self = [super init];
    if (self) {
        _lock = dispatch_semaphore_create(1);
        
        _innerSubNodes = [@[] mutableCopy];
        _isPageNode = NO;
        
        _innerStaticParams = @{};
        _dynamicParams = @{};
        _callbackParams = @{};
    }
    return self;
}

+ (instancetype)buildWithView:(UIView *)view {
    EventTracingVTreeNode *node = [[EventTracingVTreeNode alloc] init];
    node->_view = view;
    node.viewVisibleRectOnScreen = [view convertRect:ET_viewVisibleRectOnSelf(view) toView:nil];
    node->_visibleRectCalculateStrategy = view.et_visibleRectCalculateStrategy;
    node->_buildinEventLogDisableStrategy = view.et_buildinEventLogDisableStrategy;
    node->_impressMaxRatio = 0.f;
    node->_identifier = view.et_reuseIdentifier;
    node->_isPageNode = ET_isPage(view);
    node->_oid = ET_isPage(view) ? view.et_pageId : view.et_elementId;
    node.position = view.et_position;
    node->_depth = 0;
    node->_pageOcclusionEnable = view.et_pageOcclusionEnable;
    node->_psreferMute = view.et_props.isPsreferMuted;
    
    node->_subpagePvToReferEnable = view.et_props.subpagePvToReferEnable;
    node->_pageReferConsumeOption = view.et_props.pageReferConsumeOption;
    
    node.hasBindData = view.et_props.bizLeafIdentifier.length > 0;
    if (node->_isPageNode) {
        node->_pageNodeMarkAsRootPage = view.et_isRootPage;
    }
    
    return node;
}

+ (instancetype)buildVirtualNodeWithOid:(NSString *)oid
                                 isPage:(BOOL)isPage
                             identifier:(NSString *)identifier
                               position:(NSUInteger)position
         buildinEventLogDisableStrategy:(ETNodeBuildinEventLogDisableStrategy)buildinEventLogDisableStrategy
                                 params:(NSDictionary * _Nullable)params {
    EventTracingVTreeNode *node = [[EventTracingVTreeNode alloc] init];
    node->_oid = oid;
    node->_identifier = identifier;
    node->_isPageNode = isPage;
    node->_innerStaticParams = params;
    node->_visible = YES;           // 虚拟父节点的是否可见，取决于是否有子节点可见
    node->_virtualNode = YES;
    node->_pageOcclusionEnable = NO; // 虚拟父节点不参与 page 遮挡
    node.position = position;
    node->_buildinEventLogDisableStrategy = buildinEventLogDisableStrategy;
    
    return node;
}

- (void)associateToVTree:(EventTracingVTree *)VTree {
    _VTree = VTree;
}

- (void)markAsRoot {
    _oid = @"__ROOT__";
    _root = YES;
    _visible = YES;
    _visibleRect = [UIScreen mainScreen].bounds;
    _viewVisibleRectOnScreen = [UIScreen mainScreen].bounds;
    _impressMaxRatio = 1.f;
}

- (void)markIgnoreRefer {
    self->_ignoreRefer = YES;
}

- (void)updateStaticParams:(NSDictionary<NSString *, NSString *> *)staticParams {
    LOCK {
        _innerStaticParams = [staticParams copy] ?: @{};
    } UNLOCK
}

- (void)updatePosition:(NSUInteger)position {
    self.position = position;
}

- (void)refreshDynsmicParamsIfNeeded {
    [self refreshDynsmicParamsIfNeededForEvent:kETAddParamCallbackObjectkey];
}

- (void)refreshDynsmicParamsIfNeededForEvent:(NSString *)event {
    if (!self.view && ![self.view.et_reuseIdentifier isEqualToString:self.identifier]) {
        return;
    }
    
    // 当前view被再次使用了，但是所关联的节点不是当前节点，则不应该再被更新参数
    if (self.view.et_currentVTreeNode && self.view.et_currentVTreeNode != self) {
        return;
    }
    
    [self doUpdateDynamicParams];
    [self doUpdateCallbackParamsForEvent:event];
}

- (void)doUpdateDynamicParams {
    // dynamic params
    NSDictionary *params = nil;
    UIViewController *vc = self.view.et_currentViewController;
    if (vc && [vc respondsToSelector:@selector(et_dynamicParams)]) {
        params = [(id<EventTracingVTreeNodeDynamicParamsProtocol>)vc et_dynamicParams];
    } else if ([self.view respondsToSelector:@selector(et_dynamicParams)]) {
        params = [(id<EventTracingVTreeNodeDynamicParamsProtocol>)self.view et_dynamicParams];
    }
    
    LOCK {
        _dynamicParams = params ?: @{};
    } UNLOCK
    
    [self doUpdateCallbackParamsForEvent:kETAddParamCallbackObjectkey];
}

- (void)doUpdateCallbackParamsForEvent:(NSString *)event {
    // callback params
    NSMutableDictionary<NSString *, NSDictionary<NSString *, NSString *> *> *callbackParams = nil;
    LOCK {
        callbackParams = _callbackParams.mutableCopy ?: @{}.mutableCopy;
    } UNLOCK
    
    
    [self.view.et_props.paramCallbacks enumerateObjectsUsingBlock:^(EventTracingAssociatedProsParamsCallback * _Nonnull callbackObj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSArray<NSString *> *events = callbackObj.events;
        if (![events containsObject:event]) {
            return;
        }
        
        NSDictionary *params;
        if (callbackObj.callback) {
            params = callbackObj.callback();
        } else if (callbackObj.carryEventCallback) {
            params = callbackObj.carryEventCallback(event);
        } else{
            NSAssert(false, @"callback设置错误");
            return;
        }
        if (!params.count) {
            return;
        }
        
        NSMutableDictionary *mutableParams = [callbackParams objectForKey:event].mutableCopy ?: @{}.mutableCopy;
        [mutableParams addEntriesFromDictionary:params];
        [callbackParams setObject:mutableParams.copy forKey:event];
    }];
    
    LOCK {
        _callbackParams = callbackParams.copy ?: @{};
    } UNLOCK
}

- (void)setupParentNode:(EventTracingVTreeNode * _Nullable)parentNode {
    _parentNode = parentNode;
    
    [self _setDiffIdentifierNeedsUpdate];
}

- (void)pushSubNode:(EventTracingVTreeNode *)subNode {
    [subNode setupParentNode:self];
    [self.innerSubNodes addObject:subNode];
    
    subNode->_depth = self.depth + 1;
}

- (void)removeSubNode:(EventTracingVTreeNode *)subNode {
    [subNode setupParentNode:nil];
    [self.innerSubNodes removeObject:subNode];
}

- (void)updateParentNodesHasSubpageNodeMarkAsRootPageIfNeeded {
    if (!self.isPageNode || !self.pageNodeMarkAsRootPage) {
        return;
    }
    
    [self.parentNode enumerateAncestorNodeWithBlock:^(EventTracingVTreeNode * _Nonnull ancestorNode, BOOL * _Nonnull stop) {
        if (ancestorNode.isPageNode) {
            ancestorNode.hasSubPageNodeMarkAsRootPage = YES;
        }
    }];
}

- (void)nodeWillImpress {
    self.beginTime = [NSDate date].timeIntervalSince1970;
    
    if (!self.isPageNode) {
        return;
    }
    
    _pgstep = [[EventTracingEngine sharedInstance] pgstepIncreased];
    
    // MARK: page曝光，需要增加actseq
    EventTracingVTreeNode *toppestNode = [self findToppestNode:NO];
    [toppestNode _doIncreaseActseq];
    
    if (self == toppestNode) {
        _rootPagePVFormattedRefer = ET_formattedReferForNode(self, NO);
    }
}

- (NSUInteger)doIncreaseActseq {
    // actseq的自增，发生在顶层page node上
    // 如果找不到顶层page node，则取顶层element node
    EventTracingVTreeNode *toppestNode = [self findToppestNode:NO];
    return [toppestNode _doIncreaseActseq];
}

- (void)syncToNode:(EventTracingVTreeNode *)node {
    node.beginTime = self.beginTime;
    
    node->_pgstep = self.pgstep;
    node->_pgrefer = self.pgrefer;
    node->_psrefer = self.psrefer;
    if (self.actseqSentinel) {
        node.actseqSentinel = [EventTracingSentinel sentinelWithInitialValue:self.actseqSentinel.value];
    }
    
    node->_rootPagePVFormattedRefer = self.rootPagePVFormattedRefer;
    node->_impressMaxRatio = MAX(node->_impressMaxRatio, self.impressMaxRatio);
}

- (void)pageNodeMarkFromRefer:(NSString *)pgrefer psrefer:(NSString *)psrefer {
    if (!self.isPageNode) {
        return;
    }
    
    _pgrefer = pgrefer;
    _psrefer = psrefer;
}

- (EventTracingVTreeNode * _Nullable)findToppestNode:(BOOL)onlyPageNode {
    __block EventTracingVTreeNode *rootPageNode;
    __block EventTracingVTreeNode *rootNode;
    [self enumerateAncestorNodeWithBlock:^(EventTracingVTreeNode * _Nonnull ancestorNode, BOOL * _Nonnull stop) {
        if (ancestorNode.isPageNode) {
            rootPageNode = ancestorNode;
            
            if (ancestorNode.pageNodeMarkAsRootPage) {
                *stop = YES;
            }
        }
        
        rootNode = ancestorNode;
    }];
    
    if (onlyPageNode) {
        return rootPageNode;
    }
    return rootPageNode ?: rootNode;
}

#pragma mark - Private methods
- (int32_t) _doIncreaseActseq {
    if (!_actseqSentinel) {
        _actseqSentinel = [EventTracingSentinel sentinel];
    }
    [_actseqSentinel increase];
    
    return _actseqSentinel.value;
}

- (void) _setDiffIdentifierNeedsUpdate {
    _diffIdentifiershouldUpdate = YES;
    _diffIdentifier = nil;
    
    [self.subNodes enumerateObjectsUsingBlock:^(EventTracingVTreeNode * _Nonnull subNode, NSUInteger idx, BOOL * _Nonnull stop) {
        [subNode _setDiffIdentifierNeedsUpdate];
    }];
}

#pragma mark - NSCopying
- (id)copyWithZone:(nullable NSZone *)zone {
    EventTracingVTreeNode *node = [[EventTracingVTreeNode alloc] init];
    node->_root = self.root;
    node->_virtualNode = self.isVirtualNode;
    node->_depth = self.depth;
    
    node->_identifier = self.identifier;
    node->_view = self.view;
    node->_buildinEventLogDisableStrategy = self.buildinEventLogDisableStrategy;
    node->_impressMaxRatio = self.impressMaxRatio;
    
    node->_oid = self.oid;
    node.position = self.position;
    node->_ignoreRefer = self.ignoreRefer;
    node->_psreferMute = self.psreferMute;
    node->_subpagePvToReferEnable = self.subpagePvToReferEnable;
    node->_pageReferConsumeOption = self.pageReferConsumeOption;
    node->_pgrefer = self.pgrefer;
    node->_psrefer = self.psrefer;
    node->_pgstep = self.pgstep;
    node.actseqSentinel = [EventTracingSentinel sentinelWithInitialValue:self.actseqSentinel.value];
    node.beginTime = self.beginTime;
    
    node->_isPageNode = self.isPageNode;
    node->_pageOcclusionEnable = self.pageOcclusionEnable;
    
    node.visible = self.visible;
    node.visibleRect = self.visibleRect;
    node.viewVisibleRectOnScreen = self.viewVisibleRectOnScreen;
    node->_visibleRectCalculateStrategy = self.visibleRectCalculateStrategy;
    node.blockedBySubPage = self.blockedBySubPage;
    node.coundAutoMountOtherNodes = self.coundAutoMountOtherNodes;
    node.validForContainingSubNodeOids = self.validForContainingSubNodeOids;
    
    node.pageNodeMarkAsRootPage = self.pageNodeMarkAsRootPage;
    node.hasSubPageNodeMarkAsRootPage = self.hasSubPageNodeMarkAsRootPage;
    
    [self.innerSubNodes enumerateObjectsUsingBlock:^(EventTracingVTreeNode * _Nonnull subNode, NSUInteger idx, BOOL * _Nonnull stop) {
        EventTracingVTreeNode *copySubNode = subNode.copy;
        [node pushSubNode:copySubNode];
    }];
    node->_innerStaticParams = self.innerStaticParams.copy;
    node->_dynamicParams = self.dynamicParams.copy;
    node->_callbackParams = self.callbackParams.copy;
    
    return node;
}

#pragma mark - EventTracingDiffable
- (nonnull id<NSObject>)et_diffIdentifier {
    if (!_diffIdentifier || _diffIdentifiershouldUpdate) {
        NSMutableString *result = [@"" mutableCopy];
        [self enumerateAncestorNodeWithBlock:^(EventTracingVTreeNode * _Nonnull ancestorNode, BOOL * _Nonnull stop) {
            if (result.length > 0) {
                [result appendString:@"|"];
            }
            [result appendString:ancestorNode.oid];
            [result appendString:@"`"];
            [result appendString:ancestorNode.identifier];
            [result appendString:@"`"];
        }];
        
        _diffIdentifier = result.copy;
        _diffIdentifiershouldUpdate = NO;
    }
    return _diffIdentifier;
}

- (BOOL)et_isEqualToDiffableObject:(nullable id<EventTracingDiffable>)object {
    if (self == object) {
        return YES;
    }
    
    NSString *objectIdentifier = [(EventTracingVTreeNode *)object identifier];
    if ([object isKindOfClass:self.class] && [objectIdentifier isEqualToString:self.identifier]) {
        return YES;
    }
    return NO;
}

#pragma mark - getters
- (NSUInteger)actseq {
    EventTracingVTreeNode *toppestNode = [self findToppestNode:NO];
    return toppestNode.actseqSentinel.value;
}

- (NSArray<EventTracingVTreeNode *> *)subNodes {
    return self.innerSubNodes.copy;
}

- (NSDictionary<NSString *,NSString *> *)nodeParams {
    NSMutableDictionary *params = [@{} mutableCopy];
    
    NSDictionary *staticParams = [self nodeStaticParams];
    if (staticParams.count) {
        [params addEntriesFromDictionary:staticParams.copy];
    }
    
    NSDictionary *dynamicParams = [self nodeDynamicParams];
    if (dynamicParams.count) {
        [params addEntriesFromDictionary:dynamicParams.copy];
    }
    
    NSDictionary *callbackParams = [self nodeCallbackParamsForEvent:kETAddParamCallbackObjectkey];
    if (callbackParams.count) {
        [params addEntriesFromDictionary:callbackParams.copy];
    }

    return params;
}

- (NSDictionary<NSString *,NSString *> *)nodeStaticParams {
    NSDictionary *params = nil;
    
    LOCK {
        params = _innerStaticParams.copy;
    } UNLOCK
    
    return params;
}

- (NSDictionary<NSString *,NSString *> *)nodeDynamicParams {
    NSDictionary *params = nil;
    
    LOCK {
        params = _dynamicParams.copy;
    } UNLOCK
    
    return params;
}

- (NSDictionary<NSString *, NSString *> *)nodeCallbackParamsForEvent:(NSString *)event {
    NSDictionary *callbackParams = nil;
    
    LOCK {
        callbackParams = [[_callbackParams objectForKey:event] ?: @{} copy];
    } UNLOCK
    
    return callbackParams;
}

- (NSDictionary<NSString *, NSString *> *)nodeParamsForEvent:(NSString *)event {
    NSMutableDictionary *params = [self nodeParams].mutableCopy;
    [params addEntriesFromDictionary:[self nodeCallbackParamsForEvent:event]];
    return params;
}

- (NSString *)spm {
    NSMutableString *result = [@"" mutableCopy];
    [self enumerateAncestorNodeWithBlock:^(EventTracingVTreeNode * _Nonnull ancestorNode, BOOL * _Nonnull stop) {
        if (result.length > 0) {
            [result appendString:@"|"];
        }
        [result appendString:ancestorNode.oid];
        if (ancestorNode.position > 0) {
            [result appendString:@":"];
            [result appendString:@(ancestorNode.position).stringValue];
        }
    }];
    
    return result.copy;
}

- (NSString *)scm {
    NSMutableString *result = [@"" mutableCopy];
    [self enumerateAncestorNodeWithBlock:^(EventTracingVTreeNode * _Nonnull ancestorNode, BOOL * _Nonnull stop) {
        if (result.length > 0) {
            [result appendString:@"|"];
        }
        NSString *scm = [[EventTracingEngine sharedInstance].ctx.referNodeSCMFormatter nodeSCMWithView:self.view node:ancestorNode inVTree:ancestorNode.VTree];
        [result appendString:scm];
    }];
    
    return result.copy;
}

- (BOOL)isSCMNeedsER {
    __block BOOL needsER = NO;
    [self enumerateAncestorNodeWithBlock:^(EventTracingVTreeNode * _Nonnull ancestorNode, BOOL * _Nonnull stop) {
        if ([[EventTracingEngine sharedInstance].ctx.referNodeSCMFormatter needsEncodeSCMForNode:ancestorNode]) {
            needsER = YES;
            *stop = YES;
        }
    }];
    
    return needsER;
}

- (CGRect)visibleFrame {
    CGRect parentNodeVisibleRect = self.parentNode.visibleRect;
    CGRect visibleRect = self.visibleRect;
    CGPoint originPoint = CGPointMake(visibleRect.origin.x - parentNodeVisibleRect.origin.x,
                                      visibleRect.origin.y - parentNodeVisibleRect.origin.y);
    return (CGRect){ originPoint, visibleRect.size };
}

- (BOOL)isVisible {
    if (self.isVirtualNode) {
        return [self.subNodes bk_any:^BOOL(EventTracingVTreeNode *obj) {
            return obj.visible;
        }];
    }
    return _visible && !_blockedBySubPage;
}

- (CGRect)visibleRect {
    // 虚拟父节点的可见区域，是所有子节点的可见区域的合集
    if (self.isVirtualNode) {
        __block CGRect visibleRect = CGRectZero;
        [self.subNodes enumerateObjectsUsingBlock:^(EventTracingVTreeNode * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            visibleRect = CGRectEqualToRect(visibleRect, CGRectZero) ? obj.visibleRect : CGRectUnion(visibleRect, obj.visibleRect);
        }];
        
        return visibleRect;
    }
    
    return _visibleRect;
}

- (CGRect)viewVisibleRectOnScreen {
    // 虚拟父节点的可见区域，是所有子节点的可见区域的合集
    if (self.isVirtualNode) {
        __block CGRect viewVisibleRectOnScreen = CGRectZero;
        [self.subNodes enumerateObjectsUsingBlock:^(EventTracingVTreeNode * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            viewVisibleRectOnScreen = CGRectEqualToRect(viewVisibleRectOnScreen, CGRectZero) ? obj.viewVisibleRectOnScreen : CGRectUnion(viewVisibleRectOnScreen, obj.viewVisibleRectOnScreen);
        }];
        
        return viewVisibleRectOnScreen;
    }
    
    return _viewVisibleRectOnScreen;
}

#pragma mark - debug
- (NSDictionary *)debugJson {
    NSMutableDictionary *json = [@{} mutableCopy];
    [json addEntriesFromDictionary:self.nodeParams];
    
    [json setObject:_oid forKey:ET_CONST_KEY_OID];
    if (self.position > 0) {
        [json setObject:@(self.position).stringValue forKey:ET_REFER_KEY_POSITION];
    }
    
    if (self.isPageNode) {
        [json setObject:@(_pgstep) forKey:ET_REFER_KEY_PGSTEP];
        
        if (_pgrefer) {
            [json setObject:_pgrefer forKey:ET_REFER_KEY_PGREFER];
        }
        
        if (_psrefer) {
            [json setObject:_psrefer forKey:ET_REFER_KEY_PSREFER];
        }
    }
    
    NSMutableDictionary *debugJson = [self debugSelfJson].mutableCopy;
    [debugJson setObject:self.spm forKey:ET_REFER_KEY_SPM];
    [debugJson setObject:self.scm forKey:ET_REFER_KEY_SCM];
    [json setObject:debugJson.copy forKey:@"__debug"];
    
    if (self.subNodes.count) {
        [json setObject:[self.subNodes bk_map:^id(EventTracingVTreeNode *obj) {
            return obj.debugJson;
        }] forKey:@"nodes"];
    }
    return json.copy;
}

- (NSString *)debugJsonString {
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self.debugJson options:0 error:nil];
    return [[NSString alloc]initWithData:jsonData encoding:NSUTF8StringEncoding];
}

- (NSDictionary *)debugSelfJson {
    NSMutableDictionary *json = @{
        @"_id": self.identifier,
        @"_blockedBySubPage": @(self.blockedBySubPage),
        @"_visible": @(self.visible),
    }.mutableCopy;
    if (self.isVirtualNode) {
        [json setObject:@YES forKey:@"_virtual"];
    }
    
    [json setObject:NSStringFromCGRect(self.visibleRect) forKey:@"_visibleRect"];
    [json setObject:@(self.impressMaxRatio).stringValue forKey:@"_impressMaxRatio"];
    [json setObject:@(self.ignoreRefer) forKey:@"_ignoreRefer"];
    
    if (self.isPageNode) {
        BOOL isRootPage = [self findToppestNode:YES] == self;
        [json setObject:@(isRootPage) forKey:@"_rootpage"];
    }
    
    return json;
}

- (NSString *)description {
    NSMutableString *description = [@"" mutableCopy];
    [description appendFormat:@"%@: %@", ET_CONST_KEY_OID, (self.oid ?: @"")];
    [description appendFormat:@", %@: %@", ET_REFER_KEY_SPM, self.spm];
    [description appendFormat:@", %@: %@", ET_REFER_KEY_SCM, self.scm];
    [description appendFormat:@", %@: %@", ET_REFER_KEY_PGREFER, self.pgrefer];
    [description appendFormat:@", %@: %@", ET_REFER_KEY_PSREFER, self.psrefer];
    if (self.isPageNode) {
        [description appendFormat:@", %@: %ld", ET_REFER_KEY_PGSTEP, self.pgstep];
    }
    [description appendFormat:@", _visible[%@-%@]:{%.1f,%.1f,%.1f,%.1f}", @(self.visible).stringValue, @(self.impressMaxRatio).stringValue, _visibleRect.origin.x, _visibleRect.origin.y, _visibleRect.size.width, _visibleRect.size.height];
    
    [description appendString:@", sub: ["];
    [self.subNodes enumerateObjectsUsingBlock:^(EventTracingVTreeNode * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [description appendFormat:@"%@: %@,", ET_CONST_KEY_OID, obj.oid];
    }];
    [description appendString:@"]"];
    
    [description appendString:@", {"];
    [self.nodeParams enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        [description appendFormat:@"%@: %@, ", key, obj];
    }];
    [description appendString:@"}"];
    
    return description.copy;
}

@end

@implementation EventTracingVTreeNode (Geometry)
- (EventTracingVTreeNode * _Nullable)hitTest:(CGPoint)point {
    return [self hitTest:point pageOnly:NO];
}

- (EventTracingVTreeNode * _Nullable)hitTest:(CGPoint)point pageOnly:(BOOL)pageOnly {
    BOOL(^nodeVisible)(EventTracingVTreeNode *) = ^BOOL(EventTracingVTreeNode *node) {
        return !node.isRoot && (!pageOnly || ( pageOnly && node.isPageNode)) && CGRectContainsPoint(node.visibleRect, point);
    };
    
    __block EventTracingVTreeNode *foundedNode = nil;
    [self.subNodes enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(EventTracingVTreeNode * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (nodeVisible(obj)) {
            foundedNode = obj;
            *stop = YES;
        }
    }];
    
    if (foundedNode) {
        return [foundedNode hitTest:point pageOnly:pageOnly];
    }
    
    if (nodeVisible(self)) {
        return self;
    }
    
    return nil;
}

@end

@implementation EventTracingVTreeNode (Enumerater)

- (EventTracingVTreeNode * _Nullable)firstAncestorPageNode {
    __block EventTracingVTreeNode *pageNode = nil;
    [self enumerateAncestorNodeWithBlock:^(EventTracingVTreeNode * _Nonnull ancestorNode, BOOL * _Nonnull stop) {
        if (ancestorNode.isPageNode) {
            pageNode = ancestorNode;
            *stop = YES;
        }
    }];
    
    return pageNode;
}

- (void)enumerateAncestorNodeWithBlock:(void (NS_NOESCAPE ^ _Nonnull)(EventTracingVTreeNode * _Nonnull, BOOL * _Nonnull))block {
    [@[self] et_enumerateObjectsUsingBlock:^NSArray * _Nonnull(EventTracingVTreeNode *node, BOOL * _Nonnull stop) {
        block(node, stop);
        return (node.parentNode && !node.parentNode.isRoot) ? @[node.parentNode] : nil;
    }];
}

@end

