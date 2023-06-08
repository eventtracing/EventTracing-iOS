//
//  NEEventTracingBuilder.m
//  EventTracing
//
//  Created by dl on 2022/12/6.
//

#import "NEEventTracingBuilder.h"
#import "UIView+EventTracingPrivate.h"
#import "UIView+EventTracingPipEvent.h"
#import "NEEventTracingEngine.h"
#import <objc/runtime.h>

static bool s_enable_check_node_oid_overwrite = false;

extern void NEEventTracingLogEnableNodeOidOverwriteCheck(bool enable)
{
    s_enable_check_node_oid_overwrite = enable;
}

static void _check_node_oid_overwrite (UIView *view, bool isPage, NSString *oid);

@class NEEventTracingLogNodeParamsBuilder;
@interface NEEventTracingLogNodeParamContentIdBuilder : NSObject <NEEventTracingLogNodeParamContentIdBuilder>
@property(nonatomic, copy) NSString *ctype;
@property(nonatomic) NEEventTracingLogNodeParamsBuilder *paramsBuilder;
@property(nonatomic) NSMutableDictionary *json;

+ (instancetype)contentBuilderWithParamsBuilder:(NEEventTracingLogNodeParamsBuilder *)paramsBuilder;
@end

@class NEEventTracingLogNodeBuilder;
@class NEEventTracingLogVirtualParentNodeBuilder;
@interface NEEventTracingLogNodeParamsBuilder : NSObject<NEEventTracingLogNodeParamsBuilder> {
    NSMutableDictionary <NSString *, id> *_json;
}
@property(nonatomic, weak) NEEventTracingLogNodeBuilder *nodeBuilder;
@property(nonatomic, weak) NEEventTracingLogVirtualParentNodeBuilder *virtualParentNodeBuilder;
- (void)clean;

- (void)syncToNodeBuilder;
@end

@interface NEEventTracingLogNodeEventActionBuilder : NEEventTracingLogNodeParamsBuilder<NEEventTracingLogNodeEventActionBuilder>
@property(nonatomic, copy) NSString *eventValue;
@property(nonatomic, assign) NSNumber *useForReferValue;
@property(nonatomic, assign) NSNumber *increaseActseqValue;
@end

@interface NEEventTracingLogNodeUseForReferEventActionBuilder : NEEventTracingLogNodeParamsBuilder<NEEventTracingLogManuallyUseForReferEventActionBuilder>
@property(nonatomic, copy) NSString *eventValue;
@property(nonatomic, copy) NSString *referTypeValue;
@property(nonatomic, copy) NSString *referSPMValue;
@property(nonatomic, copy) NSString *referSCMValue;
@end

@interface NEEventTracingLogVirtualParentNodeBuilder : NSObject<NEEventTracingLogVirtualParentNodeBuilder>
@property(nonatomic, assign) NSUInteger positionValue;
@property(nonatomic, assign) NEETNodeBuildinEventLogDisableStrategy buildinEventLogDisableStrategyValue;

@property(nonatomic, strong) NEEventTracingLogNodeParamsBuilder *paramsBuilder;
@end

@interface NEEventTracingLogNodeBuilder : NSObject<NEEventTracingLogNodeBuilder, NEEventTracingLogBuilder>
@property(nonatomic, weak) UIView *view;
@property(nonatomic, strong) NEEventTracingLogNodeParamsBuilder *paramsBuilder;
@end

@interface UIView (LogETNodeBuilder)
@property(nonatomic, strong, setter=ne_etb_setNodeBuilder:) NEEventTracingLogNodeBuilder *ne_etb_nodeBuilder;
@end

@implementation NEEventTracingBuilder

+ (id<NEEventTracingLogBuilder>)view:(UIView *)view pageId:(NSString *)pageId {
    NEEventTracingLogNodeBuilder *nodeBuilder = [[NEEventTracingLogNodeBuilder alloc] init];
    
    if (s_enable_check_node_oid_overwrite) {
        _check_node_oid_overwrite(view, true, pageId);
    }
    
    [view ne_et_setPageId:pageId params:nodeBuilder.paramsBuilder.params];
    
    nodeBuilder.view = view;
    view.ne_etb_nodeBuilder = nodeBuilder;
    
    return nodeBuilder;
}

+ (id<NEEventTracingLogBuilder>)viewController:(UIViewController *)viewController pageId:(NSString *)pageId {
    NEEventTracingLogNodeBuilder *nodeBuilder = [[NEEventTracingLogNodeBuilder alloc] init];
    
    if (s_enable_check_node_oid_overwrite && viewController.isViewLoaded) {
        _check_node_oid_overwrite(viewController.view, true, pageId);
    }
    
    [viewController ne_et_setPageId:pageId params:nodeBuilder.paramsBuilder.params];
    
    nodeBuilder.view = viewController.view;
    viewController.view.ne_etb_nodeBuilder = nodeBuilder;
    
    return nodeBuilder;
}

+ (id<NEEventTracingLogBuilder>)view:(UIView *)view elementId:(NSString *)elementId {
    NEEventTracingLogNodeBuilder *nodeBuilder = [[NEEventTracingLogNodeBuilder alloc] init];
    
    if (s_enable_check_node_oid_overwrite) {
        _check_node_oid_overwrite(view, false, elementId);
    }
    
    [view ne_et_setElementId:elementId params:nodeBuilder.paramsBuilder.params];
    
    nodeBuilder.view = view;
    view.ne_etb_nodeBuilder = nodeBuilder;
    
    return nodeBuilder;
}

// 业务方自定义事件 构建
+ (void)logWithView:(UIView *)view event:(NE_ETB_EventActionBlock NS_NOESCAPE)block {
    NEEventTracingLogNodeEventActionBuilder *actionBuilder = [[NEEventTracingLogNodeEventActionBuilder alloc] init];
    !block ?: block(actionBuilder);
    
    /// MARK: 开发&测试 包，会做一步检查
#ifdef DEBUG
    UIView *pipFixedView = [view.ne_et_pipTargetEventViews objectForKey:actionBuilder.eventValue] ?: view;
    BOOL valid = pipFixedView.ne_et_isElement || pipFixedView.ne_et_isPage;
    if (!valid) {
        NSString *message = [NSString stringWithFormat:@"[%@]\n%@\n%@\n%@",
                             NSStringFromClass(pipFixedView.class),
                             @"1. 在节点上的自定义事件，必须发生在节点上，并且view要非空",
                             @"2. 需要保障该view或者该事件的pipTargetView必须为一个节点",
                             @"3. ！！请先给view绑定oid，或者给view的该事件pipTargetView绑定oid"];
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"[曙光]节点绑定oid提示" message:message preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
    }
#endif
    
    [[NEEventTracingEngine sharedInstance] logWithEvent:actionBuilder.eventValue
                                                   view:view
                                                 params:actionBuilder.params
                                            eventAction:^(NEEventTracingEventActionConfig * _Nonnull config) {
        if (actionBuilder.useForReferValue) {
            config.useForRefer = [actionBuilder.useForReferValue boolValue];
        }
        if (actionBuilder.increaseActseqValue) {
            config.increaseActseq = [actionBuilder.increaseActseqValue boolValue];
        }
    }];
}

+ (void)logManuallyWithBuilder:(NE_ETB_ManuallyEventActionBlock NS_NOESCAPE)block {
    NEEventTracingLogNodeEventActionBuilder *actionBuilder = [[NEEventTracingLogNodeEventActionBuilder alloc] init];
    !block ?: block(actionBuilder);
    
    [[NEEventTracingEngine sharedInstance] logSimplyWithEvent:actionBuilder.eventValue
                                                       params:actionBuilder.params];
}

+ (void)logManuallyUseForReferWithBuilder:(NE_ETB_ManuallyUseForReferEventActionBlock NS_NOESCAPE)block {
    NEEventTracingLogNodeUseForReferEventActionBuilder *actionBuilder = [[NEEventTracingLogNodeUseForReferEventActionBuilder alloc] init];
    !block ?: block(actionBuilder);
    
    [[NEEventTracingEngine sharedInstance] logReferEvent:actionBuilder.eventValue
                                               referType:actionBuilder.referTypeValue
                                                referSPM:actionBuilder.referSPMValue
                                                referSCM:actionBuilder.referSCMValue
                                                  params:actionBuilder.params];
}

+ (id<NEEventTracingLogNodeParamsBuilder>)emptyParamsBuilder {
    return [NEEventTracingLogNodeParamsBuilder new];
}

+ (void)batchBuildParams:(NE_ETB_Block NS_NOESCAPE)block variableViews:(UIView *)view, ... {
    NSMutableArray *views = [@[] mutableCopy];
    
    va_list args;
    va_start(args, view);
    UIView *v;
    if (view) {
        [views addObject:view];
        while((v = va_arg(args, id))) {
            if (v && [v isKindOfClass: UIView.class]){
                [views addObject:v];
            }
        }
    }
    va_end(args);
    
    [self batchBuildViews:views params:block];
}

+ (void)batchBuildViews:(NSArray<UIView *> *)views params:(NE_ETB_Block NS_NOESCAPE)block {
    [views enumerateObjectsUsingBlock:^(UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj.ne_etb_nodeBuilder build:block];
    }];
}

@end

@implementation NEEventTracingBuilder (VirtualParent)

+ (void)buildVirtualParentNodeForView:(UIView *)view
                            elementId:(NSString *)elementId
                           identifier:(id)identifier
                                block:(NE_ETB_VirtualParentBlock NS_NOESCAPE _Nullable)block {
    NEEventTracingLogVirtualParentNodeBuilder *builder = [[NEEventTracingLogVirtualParentNodeBuilder alloc] init];
    !block ?: block(builder);
    
    [view ne_et_setVirtualParentOid:elementId
                             isPage:NO
                     nodeIdentifier:identifier
                           position:builder.positionValue
     buildinEventLogDisableStrategy:builder.buildinEventLogDisableStrategyValue
                             params:builder.paramsBuilder.params];
}

+ (void)buildVirtualParentNodeForView:(UIView *)view
                               pageId:(NSString *)pageId
                           identifier:(id)identifier
                                block:(NE_ETB_VirtualParentBlock NS_NOESCAPE _Nullable)block {
    NEEventTracingLogVirtualParentNodeBuilder *builder = [[NEEventTracingLogVirtualParentNodeBuilder alloc] init];
    !block ?: block(builder);
    
    [view ne_et_setVirtualParentOid:pageId
                             isPage:YES
                     nodeIdentifier:identifier
                           position:builder.positionValue
     buildinEventLogDisableStrategy:builder.buildinEventLogDisableStrategyValue
                             params:builder.paramsBuilder.params];
}

@end

@interface NEEventTracingLogSCMBuilder : NSObject<NEEventTracingLogSCMBuilder>
@property(nonatomic, strong) NSMutableArray<NSDictionary<NSString *, NSString *> *> *components;
@end

@interface NEEventTracingLogSCMComponentBuilder : NSObject<NEEventTracingLogSCMComponentBuilder>
@property(nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *json;
@property(nonatomic, weak) NEEventTracingLogSCMBuilder *scmBuilder;
@end

@implementation NEEventTracingLogSCMComponentBuilder
+ (instancetype)componentBuilderWithSCMBuilder:(NEEventTracingLogSCMBuilder *)scmBuilder {
    NEEventTracingLogSCMComponentBuilder *builder = [self new];
    builder.json = @{}.mutableCopy;
    builder.scmBuilder = scmBuilder;
    return builder;
}

#define NEEventTracingLogSCMComponentBuilderMethod(name)                                        \
- (id<NEEventTracingLogSCMComponentBuilder>  _Nonnull (^)(NSString * _Nullable))name {          \
    return ^(NSString * _Nullable value) {                                                      \
        self->_json[@"s_"#name] = value ?: @"";                                                 \
        return self;                                                                            \
    };                                                                                          \
}

NEEventTracingLogSCMComponentBuilderMethod(cid)
NEEventTracingLogSCMComponentBuilderMethod(ctype)
NEEventTracingLogSCMComponentBuilderMethod(ctraceid)
NEEventTracingLogSCMComponentBuilderMethod(ctrp)

- (id<NEEventTracingLogSCMBuilder>  _Nonnull (^)(void))pop {
    return ^() {
        [self.scmBuilder.components addObject:self.json.copy];
        return self.scmBuilder;
    };
}
@end

@implementation NEEventTracingLogSCMBuilder
- (instancetype)init {
    self = [super init];
    if (self) {
        self.components = @[].mutableCopy;
    }
    return self;
}
- (id<NEEventTracingLogSCMComponentBuilder>  _Nonnull (^)(void))pushComponent {
    return ^(void) {
        return [NEEventTracingLogSCMComponentBuilder componentBuilderWithSCMBuilder:self];
    };
}
@end

@implementation NEEventTracingBuilder (SCM)

+ (NSString *)buildSCM:(NE_ETB_SCMBlock NS_NOESCAPE)builder {
    return [self buildSCM:builder er:nil];
}

+ (NSString *)buildSCM:(NE_ETB_SCMBlock NS_NOESCAPE)builder er:(BOOL *)er {
    NEEventTracingLogSCMBuilder *builderInstance = [NEEventTracingLogSCMBuilder new];
    builder(builderInstance);
    
    NSMutableString *scm = @"".mutableCopy;
    [builderInstance.components enumerateObjectsUsingBlock:^(NSDictionary<NSString *,NSString *> * _Nonnull params, NSUInteger idx, BOOL * _Nonnull stop) {
        if (scm.length) {
            [scm appendString:@"|"];
        }
        NSString *value = [[NEEventTracingEngine sharedInstance].context.referNodeSCMFormatter nodeSCMWithNodeParams:params];
        [scm appendString:value];
        if (er
            && !(*er)
            && [[NEEventTracingEngine sharedInstance].context.referNodeSCMFormatter needsEncodeSCMForNodeParams:params]) {
            *er = YES;
        }
    }];
    
    return scm.copy;
}

@end

@implementation NEEventTracingLogNodeParamContentIdBuilder

+ (instancetype)contentBuilderWithParamsBuilder:(NEEventTracingLogNodeParamsBuilder *)paramsBuilder {
    NEEventTracingLogNodeParamContentIdBuilder *builder = [self new];
    builder.paramsBuilder = paramsBuilder;
    return builder;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _json = [NSMutableDictionary new];
    }
    return self;
}

#define NEEventTracingLogNodeParamContentIdBuilderMethod(name)                                        \
- (id<NEEventTracingLogNodeParamContentIdBuilder>  _Nonnull (^)(NSString * _Nullable))name {          \
    return ^(NSString * _Nullable value) {                                                  \
        NSString *ctype = @#name;                                                           \
        NSString *ctypeLowercase = [ctype lowercaseString];                                 \
        self.ctype = ctypeLowercase;                                                        \
        NSString *cid_key = [NSString stringWithFormat:@"s_cid_%@", ctypeLowercase];        \
        NSString *ctype_key = [NSString stringWithFormat:@"s_ctype_%@", ctypeLowercase];    \
        self->_json[cid_key] = value ?: @"";                                                \
        self->_json[ctype_key] = ctypeLowercase;                                            \
        return self;                                                                        \
    };                                                                                      \
}

NEEventTracingLogNodeParamContentIdBuilderMethod(user)
NEEventTracingLogNodeParamContentIdBuilderMethod(playlist)
NEEventTracingLogNodeParamContentIdBuilderMethod(song)

- (id<NEEventTracingLogNodeParamContentIdBuilder>  _Nonnull (^)(NSString * _Nonnull, NSString * _Nonnull))cidtype {
    return ^(NSString *cid, NSString *ctype) {
        self.ctype = ctype;
        NSString *cid_key = [NSString stringWithFormat:@"s_cid_%@", ctype];
        NSString *ctype_key = [NSString stringWithFormat:@"s_ctype_%@", ctype];
        self->_json[cid_key] = cid ?: @"";
        self->_json[ctype_key] = ctype ?: @"";

        [self.paramsBuilder syncToNodeBuilder];
        return self;
    };
}
- (id<NEEventTracingLogNodeParamContentIdBuilder>  _Nonnull (^)(NSString * _Nullable))ctraceid {
    return ^(NSString *ctraceid) {
        NSString *ctraceid_key = [NSString stringWithFormat:@"s_ctraceid_%@", self.ctype];
        self->_json[ctraceid_key] = ctraceid ?: @"";
        
        [self.paramsBuilder syncToNodeBuilder];
        return self;
    };
}

- (id<NEEventTracingLogNodeParamContentIdBuilder>  _Nonnull (^)(NSString * _Nullable))ctrp {
    return ^(NSString *ctrp) {
        NSString *ctrp_key = [NSString stringWithFormat:@"s_ctrp_%@", self.ctype];
        self->_json[ctrp_key] = ctrp ?: @"";
        
        [self.paramsBuilder syncToNodeBuilder];
        return self;
    };
}

- (id<NEEventTracingLogNodeParamsBuilder>  _Nonnull (^)(void))pop {
    return ^() {
        if (self.paramsBuilder) {
            self.paramsBuilder.addParams(self->_json);
            [self.paramsBuilder syncToNodeBuilder];
        }
        return self.paramsBuilder;
    };
}

@end

#pragma mark - NEEventTracingLogNodeBuilder
@implementation NEEventTracingLogNodeParamsBuilder
- (instancetype)init {
    self = [super init];
    if (self) {
        _json = [@{} mutableCopy];
    }
    return self;
}

- (void)clean {
    [self->_json removeAllObjects];
    [self.nodeBuilder.view ne_et_removeAllParams];
}

- (void)syncToNodeBuilder {
    NSDictionary *json = [self->_json copy];
    [NEEventTracingBuilder checkForBlackListParamKeys:json.allKeys];
    [self.nodeBuilder.view ne_et_addParams:json];
}

- (id<NEEventTracingLogNodeParamsBuilder> _Nonnull (^)(NSDictionary<NSString *,NSString *> * _Nullable))addParams {
    return ^(NSDictionary<NSString *,NSString *> *params) {
        if ([params isKindOfClass:NSDictionary.class]) {
            [self->_json addEntriesFromDictionary:params];
            
            [self syncToNodeBuilder];
        }
        return self;
    };
}
- (id<NEEventTracingLogNodeParamsBuilder>  _Nonnull (^)(NSString * _Nonnull, NSString * _Nullable))set {
    return ^(NSString *key, NSString *value) {
        self->_json[key] = value ?: @"";
        [self syncToNodeBuilder];
        return self;
    };
}

#define NEEventTracingLogNodeParamsBuilderMethod(name)                                    \
- (id<NEEventTracingLogNodeParamsBuilder>  _Nonnull (^)(NSString * _Nullable))name {      \
    return ^(NSString * _Nullable value) {                                              \
        self->_json[@"s_"#name] = value ?: @"";                                         \
        [self syncToNodeBuilder];                                                       \
        return self;                                                                    \
    };                                                                                  \
}

#define NEEventTracingLogNodeParamsBuilderMethodBollean(name)                             \
- (id<NEEventTracingLogNodeParamsBuilder>  _Nonnull (^)(BOOL))name {                      \
    return ^(BOOL value) {                                                              \
        self->_json[@"s_"#name] = value ? @"1" : @"0";                                  \
        [self syncToNodeBuilder];                                                       \
        return self;                                                                    \
    };                                                                                  \
}

NEEventTracingLogNodeParamsBuilderMethod(cid)
NEEventTracingLogNodeParamsBuilderMethod(ctype)
NEEventTracingLogNodeParamsBuilderMethod(ctraceid)
NEEventTracingLogNodeParamsBuilderMethod(ctrp)

- (id<NEEventTracingLogNodeParamsBuilder>  _Nonnull (^)(NSUInteger))position {
    return ^(NSUInteger value) {
        self.nodeBuilder.view.ne_et_position = value;
        NSString *key = [NSString stringWithFormat:@"s%@", NE_ET_REFER_KEY_POSITION];
        self->_json[key] = @(value).stringValue;
        
        [self syncToNodeBuilder];
        
        // 虚拟父节点也需要
        self.virtualParentNodeBuilder.positionValue = value;
        return self;
    };
}

- (id<NEEventTracingLogNodeParamContentIdBuilder>  _Nonnull (^)(void))pushContent {
    return ^(void) {
        return [NEEventTracingLogNodeParamContentIdBuilder contentBuilderWithParamsBuilder:self];
    };
}

- (id<NEEventTracingLogNodeParamsBuilder>  _Nonnull (^)(NS_NOESCAPE void (^ _Nonnull)(id<NEEventTracingLogNodeParamContentIdBuilder> _Nonnull)))pushContentWithBlock {
    return ^(void (^ _Nonnull NS_NOESCAPE block)(id<NEEventTracingLogNodeParamContentIdBuilder> _Nonnull)) {
        NEEventTracingLogNodeParamContentIdBuilder *builder = [NEEventTracingLogNodeParamContentIdBuilder contentBuilderWithParamsBuilder:self.nodeBuilder.paramsBuilder];
        block(builder);
        builder.pop();
        
        return self;
    };
}

NEEventTracingLogNodeParamsBuilderMethod(device)
NEEventTracingLogNodeParamsBuilderMethod(resolution)
NEEventTracingLogNodeParamsBuilderMethod(carrier)
NEEventTracingLogNodeParamsBuilderMethod(network)
NEEventTracingLogNodeParamsBuilderMethod(code)
NEEventTracingLogNodeParamsBuilderMethod(toid)

NEEventTracingLogNodeParamsBuilderMethod(module)
NEEventTracingLogNodeParamsBuilderMethod(title)
NEEventTracingLogNodeParamsBuilderMethod(subtitle)
NEEventTracingLogNodeParamsBuilderMethod(label)
NEEventTracingLogNodeParamsBuilderMethod(url)
NEEventTracingLogNodeParamsBuilderMethod(status)
NEEventTracingLogNodeParamsBuilderMethod(name)

- (id<NEEventTracingLogNodeParamsBuilder>  _Nonnull (^)(NSTimeInterval))time_S {
    return ^(NSTimeInterval value) {
        self.time_MS(value * 1000);
        return self;
    };
}

- (id<NEEventTracingLogNodeParamsBuilder>  _Nonnull (^)(NSTimeInterval))time_MS {
    return ^(NSTimeInterval value) {
        self->_json[@"s_time"] = [NSString stringWithFormat:@"%zd", (NSInteger)value];
        [self syncToNodeBuilder];
        return self;
    };
}

- (id<NEEventTracingLogNodeParamsBuilder>  _Nonnull (^)(NSDate * _Nonnull))timeFromStartDate {
    return ^(NSDate *startDate) {
        return self.time_S([[NSDate date] timeIntervalSinceDate:startDate]);
    };
}

- (NSDictionary *)params {
    return self->_json.copy;
}

@end

@implementation NEEventTracingLogNodeEventActionBuilder

- (id<NEEventTracingLogNodeEventActionBuilder>  _Nonnull (^)(BOOL))increaseActseq {
    return ^(BOOL value) {
        self->_increaseActseqValue = @(value);
        return self;
    };
}
- (id<NEEventTracingLogNodeEventActionBuilder>  _Nonnull (^)(void))useForRefer {
    return ^(void) {
        self->_useForReferValue = @YES;
        if (!self->_increaseActseqValue) {
            self->_increaseActseqValue = @YES;
        }
        return self;
    };
}

#define NEEventTracingLogNodeEventActionBuilderMethod(p, event)               \
- (id<NEEventTracingLogNodeParamsBuilder>  _Nonnull (^)(void))p {             \
    return ^(void) {                                                \
        self->_eventValue = event;                                  \
        return self;                                                \
    };                                                              \
}

NEEventTracingLogNodeEventActionBuilderMethod(pv, NE_ET_EVENT_ID_P_VIEW)
NEEventTracingLogNodeEventActionBuilderMethod(pd, NE_ET_EVENT_ID_P_VIEW_END)
NEEventTracingLogNodeEventActionBuilderMethod(ev, NE_ET_EVENT_ID_E_VIEW)
NEEventTracingLogNodeEventActionBuilderMethod(ed, NE_ET_EVENT_ID_E_VIEW_END)
NEEventTracingLogNodeEventActionBuilderMethod(ec, NE_ET_EVENT_ID_E_CLCK)
NEEventTracingLogNodeEventActionBuilderMethod(elc, NE_ET_EVENT_ID_E_LONG_CLCK)
NEEventTracingLogNodeEventActionBuilderMethod(es, NE_ET_EVENT_ID_E_SLIDE)
NEEventTracingLogNodeEventActionBuilderMethod(pgf, NE_ET_EVENT_ID_P_REFRESH)
NEEventTracingLogNodeEventActionBuilderMethod(plv, NE_ET_EVENT_ID_PLV)
NEEventTracingLogNodeEventActionBuilderMethod(pld, NE_ET_EVENT_ID_PLD)

- (id<NEEventTracingLogNodeParamsBuilder> _Nonnull (^)(NSString * _Nonnull))event {
    return ^(NSString *event) {
        self->_eventValue = event;
        return self;
    };
}

@end

@implementation NEEventTracingLogNodeUseForReferEventActionBuilder

- (id<NEEventTracingLogManuallyUseForReferEventActionBuilder> _Nonnull (^)(NSString * _Nonnull))event {
    return ^(NSString *event) {
        self->_eventValue = event;
        return self;
    };
}
- (id<NEEventTracingLogManuallyUseForReferEventActionBuilder>  _Nonnull (^)(NSString * _Nonnull))referSPM {
    return ^(NSString *value) {
        self.referSPMValue = value;
        return self;
    };
}
- (id<NEEventTracingLogManuallyUseForReferEventActionBuilder>  _Nonnull (^)(NSString * _Nonnull))referSCM {
    return ^(NSString *value) {
        self.referSCMValue = value;
        return self;
    };
}
- (id<NEEventTracingLogNodeParamsBuilder>  _Nonnull (^)(NSString * _Nonnull))referType {
    return ^(NSString *value) {
        self.referTypeValue = value;
        return self;
    };
}

@end

@implementation NEEventTracingLogNodeBuilder
- (instancetype)init {
    self = [super init];
    if (self) {
        _paramsBuilder = [[NEEventTracingLogNodeParamsBuilder alloc] init];
        _paramsBuilder.nodeBuilder = self;
    }
    return self;
}

#define NEEventTracingLogNodeBuilderMethod(TYPE, p)                                       \
- (id<NEEventTracingLogNodeBuilder>  _Nonnull (^)(TYPE))p {                               \
    return ^(TYPE value) {                                                      \
        self.view.ne_et_ ## p = value;                                             \
        return self;                                                            \
    };                                                                          \
}

#define NELogETNodeVisibleBuilderMethod(TYPE, p)                                \
- (id<NEEventTracingLogNodeBuilder>  _Nonnull (^)(CGFloat)) p {                           \
    return ^(CGFloat value) {                                                   \
        UIEdgeInsets insets = self.view.ne_et_visibleEdgeInsets;                   \
        insets.TYPE = value;                                                    \
        self.visibleEdgeInsets(insets);                                         \
        return self;                                                            \
    };                                                                          \
}

NEEventTracingLogNodeBuilderMethod(BOOL, logicalVisible)
NEEventTracingLogNodeBuilderMethod(UIEdgeInsets, visibleEdgeInsets)
NELogETNodeVisibleBuilderMethod(top, visibleEdgeInsetsTop)
NELogETNodeVisibleBuilderMethod(left, visibleEdgeInsetsLeft)
NELogETNodeVisibleBuilderMethod(bottom, visibleEdgeInsetsBottom)
NELogETNodeVisibleBuilderMethod(right, visibleEdgeInsetsRight)
NEEventTracingLogNodeBuilderMethod(NEETNodeVisibleRectCalculateStrategy, visibleRectCalculateStrategy)

- (id<NEEventTracingLogNodeBuilder>  _Nonnull (^)(BOOL))visiblePassthrough {
    return ^(BOOL passthrough) {
        self.visibleRectCalculateStrategy(passthrough ? NEETNodeVisibleRectCalculateStrategyPassthrough : NEETNodeVisibleRectCalculateStrategyOnParentNode);
        return self;
    };
}

- (id<NEEventTracingLogNodeBuilder>  _Nonnull (^)(CGFloat))impressRatioThreshold {
    return ^(CGFloat ratio) {
        return self;
    };
}
- (id<NEEventTracingLogNodeBuilder> _Nonnull (^)(NSTimeInterval))impressIntervalThreshold_S {
    return ^(NSTimeInterval timeInterval) {
        return self;
    };
}
- (id<NEEventTracingLogNodeBuilder> _Nonnull (^)(NSTimeInterval))impressIntervalThreshold_MS {
    return ^(NSTimeInterval timeInterval) {
        return self;
    };
}

- (id<NEEventTracingLogNodeBuilder>  _Nonnull (^)(NEETNodeBuildinEventLogDisableStrategy))buildinEventLogDisableStrategy {
    return ^(NEETNodeBuildinEventLogDisableStrategy value) {
        self.view.ne_et_buildinEventLogDisableStrategy = value;
        return self;
    };
}
- (id<NEEventTracingLogNodeBuilder>  _Nonnull (^)(void))buildinEventLogDisableClick {
    return ^(void) {
        self.view.ne_et_buildinEventLogDisableStrategy |= NEETNodeBuildinEventLogDisableStrategyClick;
        return self;
    };
}
- (id<NEEventTracingLogNodeBuilder>  _Nonnull (^)(void))buildinEventLogDisableImpress {
    return ^(void) {
        self.view.ne_et_buildinEventLogDisableStrategy |= NEETNodeBuildinEventLogDisableStrategyImpress;
        return self;
    };
}
- (id<NEEventTracingLogNodeBuilder>  _Nonnull (^)(BOOL))buildinEventLogDisableImpressend {
    return ^(BOOL value) {
        if (value) {
            self.view.ne_et_buildinEventLogDisableStrategy |= NEETNodeBuildinEventLogDisableStrategyImpressend;
        } else if (self.view.ne_et_buildinEventLogDisableStrategy & NEETNodeBuildinEventLogDisableStrategyImpressend) {
            self.view.ne_et_buildinEventLogDisableStrategy &= ~NEETNodeBuildinEventLogDisableStrategyImpressend;
        }
        return self;
    };
}
- (id<NEEventTracingLogNodeBuilder>  _Nonnull (^)(void))buildinEventLogDisableAll {
    return ^(void) {
        self.view.ne_et_buildinEventLogDisableStrategy = NEETNodeBuildinEventLogDisableStrategyAll;
        return self;
    };
}

NEEventTracingLogNodeBuilderMethod(UIViewController *, logicalParentViewController)
NEEventTracingLogNodeBuilderMethod(UIView *, logicalParentView)
NEEventTracingLogNodeBuilderMethod(NSString *, logicalParentSPM)

- (id<NEEventTracingLogNodeBuilder>  _Nonnull (^)(BOOL))autoMountOnCurrentRootPage {
    return ^(BOOL mount) {
        if (mount) {
            [self.view ne_et_autoMountOnCurrentRootPage];
        } else {
            [self.view ne_et_cancelAutoMountOnCurrentRootPage];
        }
        return self;
    };
}

- (id<NEEventTracingLogNodeBuilder>  _Nonnull (^)(BOOL))autoMountOnCuurentRootPage {
    return self.autoMountOnCurrentRootPage;
}

- (id<NEEventTracingLogNodeBuilder> _Nonnull (^)(NEETAutoMountRootPageQueuePriority))autoMountOnCuurentRootPageWithPriority {
    return self.autoMountOnCurrentRootPageWithPriority;
}

- (id<NEEventTracingLogNodeBuilder>  _Nonnull (^)(NEETAutoMountRootPageQueuePriority))autoMountOnCurrentRootPageWithPriority {
    return ^(NEETAutoMountRootPageQueuePriority priority) {
        [self.view ne_et_autoMountOnCurrentRootPageWithPriority:priority];
        return self;
    };
}

- (id<NEEventTracingLogNodeBuilder>  _Nonnull (^)(BOOL))pageOcclusionEnable {
    return ^(BOOL pageOcclusionEnable) {
        self.view.ne_et_pageOcclusionEnable = pageOcclusionEnable;
        return self;
    };
}

- (void)_et_setVirtualParentOid:(NSString *)oid
                         isPage:(BOOL)isPage
                     identifier:(id)identifier
                   builderBlock:(NE_ETB_VirtualParentBlock)block
{
    if (![oid isKindOfClass:NSString.class] || oid.length == 0 || !identifier) {
        return;
    }
    
    NEEventTracingLogVirtualParentNodeBuilder *builder = [[NEEventTracingLogVirtualParentNodeBuilder alloc] init];
    !block ?: block(builder);
    
    [self.view ne_et_setVirtualParentOid:oid
                                  isPage:isPage
                          nodeIdentifier:identifier
                                position:builder.positionValue
          buildinEventLogDisableStrategy:builder.buildinEventLogDisableStrategyValue
                                  params:builder.paramsBuilder.params];
}

- (id<NEEventTracingLogNodeBuilder>  _Nonnull (^)(NSString * _Nonnull, id _Nonnull, NE_ETB_VirtualParentBlock NS_NOESCAPE _Nullable))virtualParent {
    return ^(NSString *elementId, id identifier, NE_ETB_VirtualParentBlock block) {
        [self _et_setVirtualParentOid:elementId isPage:NO identifier:identifier builderBlock:block];
        return self;
    };
}

- (id<NEEventTracingLogNodeBuilder>  _Nonnull (^)(NSString * _Nonnull, id _Nonnull, NE_ETB_VirtualParentBlock NS_NOESCAPE _Nullable))virtualPageParent {
    return ^(NSString *pageId, id identifier, NE_ETB_VirtualParentBlock block) {
        [self _et_setVirtualParentOid:pageId isPage:YES identifier:identifier builderBlock:block];
        return self;
    };
}

- (id<NEEventTracingLogNodeBuilder> _Nonnull (^)(id _Nonnull))bindDataForReuse {
    return ^(id data) {
        [self.view ne_et_bindDataForReuse:data];
        
        if ([data isKindOfClass:NSString.class] || [data isKindOfClass:NSArray.class] || [data isKindOfClass:NSDictionary.class]) {
            return self;
        }
        
        return self;
    };
}

- (id<NEEventTracingLogNodeBuilder>  _Nonnull (^)(BOOL))enableSubPageProducePvRefer {
    return ^(BOOL value) {
        self.view.ne_et_subpagePvToReferEnable = value;
        return self;
    };
}

- (id<NEEventTracingLogNodeBuilder>  _Nonnull (^)(BOOL))enableSubPageConsumeAllRefer {
    return ^(BOOL value) {
        if (value) {
            [self.view ne_et_makeSubpageConsumeAllRefer];
        } else {
            [self.view ne_et_clearSubpageConsumeReferOption];
        }
        return self;
    };
}

- (id<NEEventTracingLogNodeBuilder>  _Nonnull (^)(BOOL))enableSubPageConsumeEventRefer {
    return ^(BOOL value) {
        if (value) {
            [self.view ne_et_makeSubpageConsumeEventRefer];
        } else {
            [self.view ne_et_clearSubpageConsumeReferOption];
        }
        return self;
    };
}

- (id<NEEventTracingLogNodeBuilder>  _Nonnull (^)(NSString * _Nonnull))bindDataForReuseWithAutoClassifyIdAppend {
    return ^(NSString *identifier) {
        [self.view ne_et_bindDataForReuse:self.view.ne_et_autoClassifyIdAppend(identifier)];
        return self;
    };
}
- (id<NEEventTracingLogNodeBuilder>  _Nonnull (^)(NSString * _Nonnull))referToid {
    return ^(NSString *toid) {
        [self.view ne_et_makeReferToid:toid];
        return self;
    };
}

- (id<NEEventTracingLogNodeBuilder>  _Nonnull (^)(BOOL))ignoreReferCascade {
    return ^(BOOL value) {
        self.view.ne_et_ignoreReferCascade = value;
        return self;
    };
}

- (id<NEEventTracingLogNodeBuilder>  _Nonnull (^)(BOOL))doNotParticipateMultirefer {
    return ^(BOOL value) {
        self.view.ne_et_psreferMute = value;
        return self;
    };
}

- (id<NEEventTracingLogNodeParamsBuilder>)params {
    return self.paramsBuilder;
}
- (id<NEEventTracingLogNodeParamsBuilder>)emptyParams {
    [self.paramsBuilder clean];
    return self.paramsBuilder;
}

- (id<NEEventTracingLogNodeBuilder>  _Nonnull (^)(NE_ETB_ParamsBlock _Nullable))addParamsCallback {
    return ^(NE_ETB_ParamsBlock block) {
        [self.view ne_et_addParamsCallback:^NSDictionary * _Nonnull{
            NEEventTracingLogNodeParamsBuilder *builder = [[NEEventTracingLogNodeParamsBuilder alloc] init];
            !block ?: block(builder);
            return builder.params;
        }];
        return self;
    };
}

- (id<NEEventTracingLogNodeBuilder>  _Nonnull (^)(NE_ETB_ParamsBlock _Nullable))addClickParamsCallback {
    return ^(NE_ETB_ParamsBlock block) {
        return self.addParamsCallbackForEvent(NE_ET_EVENT_ID_E_CLCK, block);
    };
}

- (id<NEEventTracingLogNodeBuilder>  _Nonnull (^)(NE_ETB_ParamsBlock _Nullable))addLongClickParamsCallback {
    return ^(NE_ETB_ParamsBlock block) {
        return self.addParamsCallbackForEvent(NE_ET_EVENT_ID_E_LONG_CLCK, block);
    };
}

- (id<NEEventTracingLogNodeBuilder>  _Nonnull (^)(NSString * _Nonnull, NE_ETB_ParamsBlock _Nullable))addParamsCallbackForEvent {
    return ^(NSString *event, NE_ETB_ParamsBlock block) {
        [self.view ne_et_addParamsCallback:^NSDictionary * _Nonnull{
            NEEventTracingLogNodeParamsBuilder *builder = [[NEEventTracingLogNodeParamsBuilder alloc] init];
            !block ?: block(builder);
            return builder.params;
        } forEvent:event];
        return self;
    };
}
- (id<NEEventTracingLogNodeBuilder>  _Nonnull (^)(NSArray<NSString *> * _Nonnull, NE_ETB_ParamsBlock _Nullable))addParamsCallbackForEvents {
    return ^(NSArray<NSString *> *events, NE_ETB_ParamsBlock block) {
        [self.view ne_et_addParamsCallback:^NSDictionary * _Nonnull{
            NEEventTracingLogNodeParamsBuilder *builder = [[NEEventTracingLogNodeParamsBuilder alloc] init];
            !block ?: block(builder);
            return builder.params;
        } forEvents:events];
        return self;
    };
}

- (id<NEEventTracingLogNodeBuilder>  _Nonnull (^)(NSArray<NSString *> * _Nonnull, NE_ETB_ParamsCarryEventsBlock _Nullable))addParamsCarryEventCallbackForEvents {
    return ^(NSArray<NSString *> *events, NE_ETB_ParamsCarryEventsBlock block) {
        [self.view ne_et_addParamsCarryEventCallback:^NSDictionary * _Nonnull(NSString *event) {
            NEEventTracingLogNodeParamsBuilder *builder = [[NEEventTracingLogNodeParamsBuilder alloc] init];
            !block ?: block(builder, event);
            return builder.params;
        } forEvents:events];
        return self;
    };
}

- (void)build:(NE_ETB_Block NS_NOESCAPE)block {
    if (self.view && block) {
        block(self);
    }
}

@end

@implementation NEEventTracingLogVirtualParentNodeBuilder
- (instancetype)init {
    self = [super init];
    if (self) {
        _paramsBuilder = [[NEEventTracingLogNodeParamsBuilder alloc] init];
        _paramsBuilder.virtualParentNodeBuilder = self;
        
        _buildinEventLogDisableStrategyValue = [NEEventTracingEngine sharedInstance].context.isElementAutoImpressendEnable ? NEETNodeBuildinEventLogDisableStrategyNone : NEETNodeBuildinEventLogDisableStrategyImpressend;
    }
    return self;
}
- (id<NEEventTracingLogVirtualParentNodeBuilder>  _Nonnull (^)(NEETNodeBuildinEventLogDisableStrategy))buildinEventLogDisableStrategy {
    return ^(NEETNodeBuildinEventLogDisableStrategy value) {
        self.buildinEventLogDisableStrategyValue |= value;
        return self;
    };
}
- (id<NEEventTracingLogVirtualParentNodeBuilder>  _Nonnull (^)(void))buildinEventLogDisableImpress {
    return ^(void) {
        self.buildinEventLogDisableStrategyValue |= NEETNodeBuildinEventLogDisableStrategyImpress;
        return self;
    };
}
- (id<NEEventTracingLogVirtualParentNodeBuilder>  _Nonnull (^)(BOOL))buildinEventLogDisableImpressend {
    return ^(BOOL value) {
        if (value) {
            self.buildinEventLogDisableStrategyValue |= NEETNodeBuildinEventLogDisableStrategyImpressend;
        } else if (self.buildinEventLogDisableStrategyValue & NEETNodeBuildinEventLogDisableStrategyImpressend) {
            self.buildinEventLogDisableStrategyValue &= ~NEETNodeBuildinEventLogDisableStrategyImpressend;
        }
        return self;
    };
}
- (id<NEEventTracingLogVirtualParentNodeBuilder>  _Nonnull (^)(void))buildinEventLogDisableAll {
    return ^(void) {
        self.buildinEventLogDisableStrategyValue = NEETNodeBuildinEventLogDisableStrategyAll;
        return self;
    };
}

- (id<NEEventTracingLogNodeParamsBuilder>)params {
    return _paramsBuilder;
}
@end

@implementation UIView (BILogBuilder)
- (NEEventTracingLogNodeBuilder *)ne_etb_nodeBuilder {
    return objc_getAssociatedObject(self, _cmd);
}
- (void)ne_etb_setNodeBuilder:(NEEventTracingLogNodeBuilder *)ne_etb_nodeBuilder {
    objc_setAssociatedObject(self, @selector(ne_etb_nodeBuilder), ne_etb_nodeBuilder, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)ne_etb_build:(NE_ETB_Block NS_NOESCAPE)block {
    NEEventTracingLogNodeBuilder *builder = self.ne_etb_nodeBuilder;
    if (!builder || !block) {
        return;
    }
    
    block(builder);
}

- (void)ne_etb_buildParams:(NE_ETB_ParamsBlock NS_NOESCAPE)block {
    NEEventTracingLogNodeBuilder *builder = self.ne_etb_nodeBuilder;
    if (!builder.params || !block) {
        return;
    }
    block(builder.params);
}

@end
@implementation UIViewController (BILogBuilder)
- (void)ne_etb_build:(NE_ETB_Block NS_NOESCAPE)block {
    [self.view ne_etb_build:block];
}

- (void)ne_etb_buildParams:(NE_ETB_ParamsBlock NS_NOESCAPE)block {
    [self.view ne_etb_buildParams:block];
}
@end

@interface UIView (ETNodeDynamicParams_Private) <NEEventTracingVTreeNodeDynamicParamsProtocol>
@end
@implementation UIView (ETNodeExtraParams)
- (NSDictionary *)ne_etb_dynamicParams {
    NEEventTracingLogNodeParamsBuilder *builder = [NEEventTracingLogNodeParamsBuilder new];
    
    UIViewController *vc = (UIViewController *)self.nextResponder;
    if ([vc isKindOfClass:UIViewController.class]) {
        [vc ne_etb_makeDynamicParams:builder];
    }
    
    [self ne_etb_makeDynamicParams:builder];
    
    // 将 position 同步到节点配置中
    id position = [builder.params objectForKey:NE_ET_PARAM_CONST_KEY_POSITION];
    if (position) {
        self.ne_et_position = [position unsignedIntegerValue];
    }
    
    return builder.params;
}

- (void)ne_etb_makeDynamicParams:(id<NEEventTracingLogNodeParamsBuilder>)builder { }
@end

@interface UIViewController (ETNodeDynamicParams_Private) <NEEventTracingVTreeNodeDynamicParamsProtocol>
@end
@implementation UIViewController (ETNodeExtraParams)
- (NSDictionary *)ne_etb_dynamicParams {
    return [self.view ne_etb_dynamicParams];
}
- (void)ne_etb_makeDynamicParams:(id<NEEventTracingLogNodeParamsBuilder>)builder {}
@end



static void _check_node_oid_overwrite(UIView *view, bool isPage, NSString *oid)
{
    if (!s_enable_check_node_oid_overwrite) {
        return;
    }
    id element = view;
    NSString *ori_oid = isPage ? [element ne_et_pageId] : [element ne_et_elementId];
    NSString *ori_anotherOid;
    if (isPage && [element respondsToSelector:@selector(ne_et_elementId)]) {
        ori_anotherOid = [element ne_et_elementId];
    } else if (!isPage && [element respondsToSelector:@selector(ne_et_pageId)]) {
        ori_anotherOid = [element ne_et_pageId];
    }
    
    bool isOidWillChanged = (oid && ori_oid && ![oid isEqualToString:ori_oid]); // oid 将发生变更
    bool isEidPidExistAtTheSameTime = ori_anotherOid != nil; // pid 和 eid 同时存在
    if (isOidWillChanged || isEidPidExistAtTheSameTime) {
        NSString *nodeDesc = NSStringFromClass([element class]);
        if ([element isKindOfClass:UIView.class]) {
            if ([(UIView *)element ne_et_logicalParentViewController]) {
                nodeDesc = NSStringFromClass([(UIView *)element ne_et_logicalParentViewController].class);
            } else if ([(UIView *)element respondsToSelector:@selector(ne_et_currentViewController)]) {
                nodeDesc = NSStringFromClass([[(UIView *)element performSelector:@selector(ne_et_currentViewController)] class]);
            }
        }
        NSString *message = [NSString stringWithFormat:@"⚠️节点oid变更 %@: 原oid:%@ => 新oid:%@⚠️\n%@\n%@\n%@",
                             nodeDesc, ori_oid ?: ori_anotherOid, oid,
                             @"1. 一个view设置了oid后，就是一个节点，如果该节点再次被设置成另外一个oid，那就成了另外一个节点，这样会把之前的oid覆盖掉",
                             @"2. 如果确实需要重新覆盖oid，请显式的「clean」掉之前的 oid（-[UIView ne_etb_clear]），再设置新的oid",
                             @"3. 建议和此埋点的相关同学进行充分沟通，以确保不对历史埋点产生意料之外的影响"];
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"[曙光]重复设置节点oid提示" message:message preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
    }
}


static NSMutableDictionary<NSString *, NSString *> *BlackListParamKeyMap;
static NSMutableArray<NSString *> *alertedParamKeys = nil;

@implementation NEEventTracingBuilder (BlackListParamKey)

+ (void)addBlackListParamKey:(NSString *)key errorString:(NSString *)errorString {
#ifdef DEBUG
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        BlackListParamKeyMap = @{}.mutableCopy;
    });
    
    [BlackListParamKeyMap setObject:errorString forKey:key];
#endif
}

+ (NSArray<NSString *> *)allBlackListParamKeys {
    return BlackListParamKeyMap.allKeys;
}

+ (void)checkForBlackListParamKeys:(NSArray<NSString *> *)paramKeys {
#ifdef DEBUG
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        alertedParamKeys = @[].mutableCopy;
    });
    
    if (alertedParamKeys.count > 0) {
        return;
    }
    
    NSArray<NSString *> *allBlackListParamKeys = [self allBlackListParamKeys];
    if (![[NSSet setWithArray:paramKeys] intersectsSet:[NSSet setWithArray:allBlackListParamKeys]]) {
        return;
    }
    
    __block NSString *blackListParamKey = nil;
    [paramKeys enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([allBlackListParamKeys containsObject:obj]) {
            blackListParamKey = obj;
            *stop = YES;
        }
    }];
    if (!blackListParamKey) {
        return;
    }
    
    [self _doShowAlertForBlackListParamKeys:blackListParamKey errorString:[BlackListParamKeyMap objectForKey:blackListParamKey]];
    [alertedParamKeys addObject:blackListParamKey];
#endif
}

+ (void)_doShowAlertForBlackListParamKeys:(NSString *)key errorString:(NSString *)errorString {
    NSString *message = [NSString stringWithFormat:@"参数 [%@] 不可以在该app内使用\n原因: %@", key, errorString];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"[曙光] 参数黑名单" message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [alertedParamKeys removeAllObjects];
        });
    }]];
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
}

@end
