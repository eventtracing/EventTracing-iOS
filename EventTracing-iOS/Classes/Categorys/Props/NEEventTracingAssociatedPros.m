//
//  NEEventTracingAssociatedPros.m
//  BlocksKit
//
//  Created by dl on 2021/7/27.
//

#import "NEEventTracingAssociatedPros.h"
#import "NEEventTracingTraverser.h"
#import "NEEventTracingVTreeNode+Private.h"
#import "NEEventTracingEngine+Private.h"

#import <objc/runtime.h>
#import <BlocksKit/BlocksKit.h>

static NSNumber *uniqueBizClassId(UIView *view) {
    static NSMutableDictionary *sClassLeafModMap = nil;
    if (!sClassLeafModMap) {
        sClassLeafModMap = @{}.mutableCopy;
    }
    
    NSNumber *classIdRet = [sClassLeafModMap objectForKey:NSStringFromClass(object_getClass([view class]))];
    if (![classIdRet boolValue]) {
        static NSUInteger sIncreaseClassId = 1;
        classIdRet = @(sIncreaseClassId++);
        [sClassLeafModMap setObject:classIdRet forKey:NSStringFromClass(object_getClass([view class]))];
    }
    
    return classIdRet;
}

@interface NEEventTracingAssociatedProsParamsCallback()
@property (nonatomic, copy, readwrite) NE_ET_AddParamsCallback callback;
@property (nonatomic, copy, readwrite) NE_ET_AddParamsCarryEventCallback carryEventCallback;
@property (nonatomic, copy, readwrite) NSArray<NSString *> *events;
@end

@implementation NEEventTracingAssociatedProsParamsCallback
@end

@interface NEEventTracingAssociatedPros() {
    __weak UIView *_view;
    BOOL _buildinEventLogDisableStrategyHasBeenSetted;
}

@property(nonatomic, strong, readonly) NSMutableArray<NEEventTracingAssociatedProsParamsCallback *> *innerParamCallbacks;
@end

__attribute__((objc_direct_members))
@implementation NEEventTracingAssociatedPros
@synthesize view = _view;
@synthesize pageId = _pageId;
@synthesize elementId = _elementId;
@synthesize buildinEventLogDisableStrategy = _buildinEventLogDisableStrategy;
@synthesize reuseIdentifier = _reuseIdentifier;
@synthesize bizLeafIdentifier = _bizLeafIdentifier;
@synthesize reuseIdentifierNeedsUpdate = _reuseIdentifierNeedsUpdate;
@synthesize reuseSEQ = _reuseSEQ;

- (instancetype)init {
    self = [super init];
    if (self) {
        _pageOcclusionEnable = YES;
        _params = @{}.mutableCopy;
        _checkedGuardParamKeys = [NSMutableSet set];
        _innerParamCallbacks = @[].mutableCopy;
        _logicalVisible = YES;
        _visibleEdgeInsets = UIEdgeInsetsZero;
    }
    return self;
}

+ (instancetype)associatedProsWithView:(UIView *)view {
    NEEventTracingAssociatedPros *props = [[NEEventTracingAssociatedPros alloc] init];
    props->_view = view;
    return props;
}

- (void)setupOid:(NSString *)oid
          isPage:(BOOL)isPage
          params:(NSDictionary<NSString *, NSString *> * _Nullable)params {
    if (isPage) {
        _elementId = nil;
        _pageId = oid;
    } else {
        _pageId = nil;
        _elementId = oid;
    }
    
    if (params.count) {
        [self.params addEntriesFromDictionary:params];
    }
}

- (void)addParamsCallback:(NE_ET_AddParamsCallback)callback forEvent:(NSString *)event {
    if (event.length == 0 || !callback) {
        return;
    }
    
    NEEventTracingAssociatedProsParamsCallback *callbackObj = [[NEEventTracingAssociatedProsParamsCallback alloc] init];
    callbackObj.callback = callback;
    callbackObj.events = @[event];
    
    [self.innerParamCallbacks addObject:callbackObj];
}

- (void)addParamsCarryEventCallback:(NE_ET_AddParamsCarryEventCallback)callback forEvents:(NSArray<NSString *> *)events {
    if (events.count == 0 || !callback) {
        return;
    }
    
    NEEventTracingAssociatedProsParamsCallback *callbackObj = [[NEEventTracingAssociatedProsParamsCallback alloc] init];
    callbackObj.carryEventCallback = callback;
    callbackObj.events = events;
    
    [self.innerParamCallbacks addObject:callbackObj];
}

- (void)bindDataForReuse:(id)data {
    if ([data isKindOfClass:NSString.class]) {
        _bizLeafIdentifier = self.autoClassifyIdAppend(data);
    } else {
        NSString *memAddrStr = [NSString stringWithFormat:@"%p", data];
        _bizLeafIdentifier = self.autoClassifyIdAppend(memAddrStr);
    }
    
    _reuseIdentifierNeedsUpdate = YES;
}

- (void)setResueIdentifierNeedsUpdate {
    _reuseIdentifierNeedsUpdate = YES;
}

- (NSString *)doUpdateReuseIdentifier {
    // 默认是使用 view 的内存地址
    NSString *memAddrStr = [NSString stringWithFormat:@"%p", self.view];
    BOOL hasBizLeafIdentifier = _bizLeafIdentifier.length > 0;
    NSString *bizLeafIdentifier = hasBizLeafIdentifier ? _bizLeafIdentifier : memAddrStr;
    
    NEEventTracingSentinel *sentinel = _reuseSEQ;
    
    NSMutableString *identifierString = [@"" mutableCopy];
    [identifierString appendFormat:@"[seq_(%@)]", @(sentinel.value).stringValue];
    [identifierString appendFormat:@"[%@_(%@)]", (self.isPage ? NE_ET_REFER_KEY_P : NE_ET_REFER_KEY_E), (self.isPage ? self.pageId : self.elementId)];
    [identifierString appendFormat:@"[biz_(%@)]", bizLeafIdentifier];
    if (hasBizLeafIdentifier) {
        [identifierString appendFormat:@"[%@]", NE_ET_REUSE_BIZ_SET];
    }
    
    _reuseIdentifier = identifierString.copy;
    _reuseIdentifierNeedsUpdate = NO;
    return identifierString.copy;
}

#pragma mark - getters
- (BOOL)isPage {
    return self.pageId.length > 0;
}
- (BOOL)isElement {
    return !self.isPage && self.elementId.length > 0;
}
- (NSString *)reuseIdentifier {
    NSString *identifier = _reuseIdentifier;
    if (identifier.length == 0 || _reuseIdentifierNeedsUpdate) {
        identifier = [self doUpdateReuseIdentifier];
    }
    return identifier;
}
- (NEEventTracingSentinel *)reuseSEQ {
    if (!_reuseSEQ) {
        _reuseSEQ = [[NEEventTracingSentinel alloc] init];
    }
    return _reuseSEQ;
}
- (NSString * _Nonnull (^)(NSString * _Nonnull))autoClassifyIdAppend {
    __weak typeof(self) weakSelf = self;
    return ^NSString *(NSString * identifier) {
        return [NSString stringWithFormat:@"%@_%@", uniqueBizClassId((UIView *)weakSelf), identifier];
    };
}

- (NEETNodeBuildinEventLogDisableStrategy)buildinEventLogDisableStrategy {
    if (!_buildinEventLogDisableStrategyHasBeenSetted
        && NE_ET_isElement(self.view)
        && ![NEEventTracingEngine sharedInstance].ctx.isElementAutoImpressendEnable) {
        return NEETNodeBuildinEventLogDisableStrategyImpressend;
    }

    return _buildinEventLogDisableStrategy;
}

- (void)setBuildinEventLogDisableStrategy:(NEETNodeBuildinEventLogDisableStrategy)buildinEventLogDisableStrategy {
    _buildinEventLogDisableStrategy = buildinEventLogDisableStrategy;
    _buildinEventLogDisableStrategyHasBeenSetted = YES;
}

- (NSArray<NEEventTracingAssociatedProsParamsCallback *> *)paramCallbacks {
    return self.innerParamCallbacks.copy;
}

@end

@implementation NEEventTracingVirtualParentAssociatedPros
@synthesize view = _view;

+ (instancetype)associatedProsWithView:(UIView *)view {
    NEEventTracingVirtualParentAssociatedPros *props = [[NEEventTracingVirtualParentAssociatedPros alloc] init];
    props->_view = view;
    return props;
}

- (BOOL)hasVirtualParentNode {
    if (self.virtualParentNodeIdentifier.length == 0) {
        return NO;
    }
    return (self.virtualParentNodePageId.length > 0 || self.virtualParentNodeElementId.length > 0);
}
- (void)setupVirtualParentElementId:(NSString *)elementId nodeIdentifier:(id)nodeIdentifier params:(NSDictionary<NSString *, NSString *> *)params {
    self.virtualParentNodeElementId = elementId;
    self.virtualParentNodePageId = nil;
    self.virtualParentNodeIdentifier = nodeIdentifier;
    self.virtualParentNodeParams = params.copy;
}
- (void)setupVirtualParentPageId:(NSString *)pageId nodeIdentifier:(id)nodeIdentifier params:(NSDictionary<NSString *, NSString *> *)params {
    self.virtualParentNodePageId = pageId;
    self.virtualParentNodeElementId = nil;
    self.virtualParentNodeIdentifier = nodeIdentifier;
    self.virtualParentNodeParams = params.copy;
}

@end
