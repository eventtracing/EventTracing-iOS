//
//  EventTracingBuilder.m
//  EventTracing
//
//  Created by dl on 2022/12/6.
//

#import "EventTracingBuilder.h"
#import "UIView+EventTracingPrivate.h"
#import "UIView+EventTracingPipEvent.h"
#import "EventTracingEngine.h"
#import <objc/runtime.h>

static bool s_enable_check_node_oid_overwrite = false;

extern void EventTracingLogEnableNodeOidOverwriteCheck(bool enable)
{
    s_enable_check_node_oid_overwrite = enable;
}

static void _check_node_oid_overwrite (UIView *view, bool isPage, NSString *oid);

@class EventTracingLogNodeParamsBuilder;
@interface EventTracingLogNodeParamContentIdBuilder : NSObject <EventTracingLogNodeParamContentIdBuilder>
@property(nonatomic, copy) NSString *ctype;
@property(nonatomic) EventTracingLogNodeParamsBuilder *paramsBuilder;
@property(nonatomic) NSMutableDictionary *json;

+ (instancetype)contentBuilderWithParamsBuilder:(EventTracingLogNodeParamsBuilder *)paramsBuilder;
@end

@class EventTracingLogNodeBuilder;
@class EventTracingLogVirtualParentNodeBuilder;
@interface EventTracingLogNodeParamsBuilder : NSObject<EventTracingLogNodeParamsBuilder> {
    NSMutableDictionary <NSString *, id> *_json;
}
@property(nonatomic, weak) EventTracingLogNodeBuilder *nodeBuilder;
@property(nonatomic, weak) EventTracingLogVirtualParentNodeBuilder *virtualParentNodeBuilder;
- (void)clean;

- (void)syncToNodeBuilder;
@end

@interface EventTracingLogNodeEventActionBuilder : EventTracingLogNodeParamsBuilder<EventTracingLogNodeEventActionBuilder>
@property(nonatomic, copy) NSString *eventValue;
@property(nonatomic, assign) NSNumber *useForReferValue;
@property(nonatomic, assign) NSNumber *increaseActseqValue;
@end

@interface EventTracingLogNodeUseForReferEventActionBuilder : EventTracingLogNodeParamsBuilder<EventTracingLogManuallyUseForReferEventActionBuilder>
@property(nonatomic, copy) NSString *eventValue;
@property(nonatomic, copy) NSString *referTypeValue;
@property(nonatomic, copy) NSString *referSPMValue;
@property(nonatomic, copy) NSString *referSCMValue;
@end

@interface EventTracingLogVirtualParentNodeBuilder : NSObject<EventTracingLogVirtualParentNodeBuilder>
@property(nonatomic, assign) NSUInteger positionValue;
@property(nonatomic, assign) ETNodeBuildinEventLogDisableStrategy buildinEventLogDisableStrategyValue;

@property(nonatomic, strong) EventTracingLogNodeParamsBuilder *paramsBuilder;
@end

@interface EventTracingLogNodeBuilder : NSObject<EventTracingLogNodeBuilder, EventTracingLogBuilder>
@property(nonatomic, weak) UIView *view;
@property(nonatomic, strong) EventTracingLogNodeParamsBuilder *paramsBuilder;
@end

@interface UIView (LogETNodeBuilder)
@property(nonatomic, strong, setter=et_setNodeBuilder:) EventTracingLogNodeBuilder *et_nodeBuilder;
@end

@implementation EventTracingBuilder

+ (id<EventTracingLogBuilder>)view:(UIView *)view pageId:(NSString *)pageId {
    EventTracingLogNodeBuilder *nodeBuilder = [[EventTracingLogNodeBuilder alloc] init];
    
    if (s_enable_check_node_oid_overwrite) {
        _check_node_oid_overwrite(view, true, pageId);
    }
    
    [view et_setPageId:pageId params:nodeBuilder.paramsBuilder.params];
    
    nodeBuilder.view = view;
    view.et_nodeBuilder = nodeBuilder;
    
    return nodeBuilder;
}

+ (id<EventTracingLogBuilder>)viewController:(UIViewController *)viewController pageId:(NSString *)pageId {
    EventTracingLogNodeBuilder *nodeBuilder = [[EventTracingLogNodeBuilder alloc] init];
    
    if (s_enable_check_node_oid_overwrite && viewController.isViewLoaded) {
        _check_node_oid_overwrite(viewController.view, true, pageId);
    }
    
    [viewController et_setPageId:pageId params:nodeBuilder.paramsBuilder.params];
    
    nodeBuilder.view = viewController.view;
    viewController.view.et_nodeBuilder = nodeBuilder;
    
    return nodeBuilder;
}

+ (id<EventTracingLogBuilder>)view:(UIView *)view elementId:(NSString *)elementId {
    EventTracingLogNodeBuilder *nodeBuilder = [[EventTracingLogNodeBuilder alloc] init];
    
    if (s_enable_check_node_oid_overwrite) {
        _check_node_oid_overwrite(view, false, elementId);
    }
    
    [view et_setElementId:elementId params:nodeBuilder.paramsBuilder.params];
    
    nodeBuilder.view = view;
    view.et_nodeBuilder = nodeBuilder;
    
    return nodeBuilder;
}

// 业务方自定义事件 构建
+ (void)logWithView:(UIView *)view event:(ET_BuildEventActionBlock NS_NOESCAPE)block {
    EventTracingLogNodeEventActionBuilder *actionBuilder = [[EventTracingLogNodeEventActionBuilder alloc] init];
    !block ?: block(actionBuilder);
    
    /// MARK: 开发&测试 包，会做一步检查
#ifdef DEBUG
    UIView *pipFixedView = [view.et_pipTargetEventViews objectForKey:actionBuilder.eventValue] ?: view;
    BOOL valid = pipFixedView.et_isElement || pipFixedView.et_isPage;
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
    
    [[EventTracingEngine sharedInstance] logWithEvent:actionBuilder.eventValue
                                                   view:view
                                                 params:actionBuilder.params
                                            eventAction:^(EventTracingEventActionConfig * _Nonnull config) {
        if (actionBuilder.useForReferValue) {
            config.useForRefer = [actionBuilder.useForReferValue boolValue];
        }
        if (actionBuilder.increaseActseqValue) {
            config.increaseActseq = [actionBuilder.increaseActseqValue boolValue];
        }
    }];
}

+ (void)logManuallyWithBuilder:(ET_BuildManuallyEventActionBlock NS_NOESCAPE)block {
    EventTracingLogNodeEventActionBuilder *actionBuilder = [[EventTracingLogNodeEventActionBuilder alloc] init];
    !block ?: block(actionBuilder);
    
    [[EventTracingEngine sharedInstance] logSimplyWithEvent:actionBuilder.eventValue
                                                       params:actionBuilder.params];
}

+ (void)logManuallyUseForReferWithBuilder:(ET_BuildManuallyUseForReferEventActionBlock NS_NOESCAPE)block {
    EventTracingLogNodeUseForReferEventActionBuilder *actionBuilder = [[EventTracingLogNodeUseForReferEventActionBuilder alloc] init];
    !block ?: block(actionBuilder);
    
    [[EventTracingEngine sharedInstance] logReferEvent:actionBuilder.eventValue
                                               referType:actionBuilder.referTypeValue
                                                referSPM:actionBuilder.referSPMValue
                                                referSCM:actionBuilder.referSCMValue
                                                  params:actionBuilder.params];
}

+ (id<EventTracingLogNodeParamsBuilder>)emptyParamsBuilder {
    return [EventTracingLogNodeParamsBuilder new];
}

+ (void)batchBuildParams:(ET_BuildBlock NS_NOESCAPE)block variableViews:(UIView *)view, ... {
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

+ (void)batchBuildViews:(NSArray<UIView *> *)views params:(ET_BuildBlock NS_NOESCAPE)block {
    [views enumerateObjectsUsingBlock:^(UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj.et_nodeBuilder build:block];
    }];
}

@end

@implementation EventTracingBuilder (VirtualParent)

+ (void)buildVirtualParentNodeForView:(UIView *)view
                            elementId:(NSString *)elementId
                           identifier:(id)identifier
                                block:(ET_BuildVirtualParentBlock NS_NOESCAPE _Nullable)block {
    EventTracingLogVirtualParentNodeBuilder *builder = [[EventTracingLogVirtualParentNodeBuilder alloc] init];
    !block ?: block(builder);
    
    [view et_setVirtualParentOid:elementId
                          isPage:NO
                  nodeIdentifier:identifier
                        position:builder.positionValue
  buildinEventLogDisableStrategy:builder.buildinEventLogDisableStrategyValue
                          params:builder.paramsBuilder.params];
}

+ (void)buildVirtualParentNodeForView:(UIView *)view
                               pageId:(NSString *)pageId
                           identifier:(id)identifier
                                block:(ET_BuildVirtualParentBlock NS_NOESCAPE _Nullable)block {
    EventTracingLogVirtualParentNodeBuilder *builder = [[EventTracingLogVirtualParentNodeBuilder alloc] init];
    !block ?: block(builder);
    
    [view et_setVirtualParentOid:pageId
                          isPage:YES
                  nodeIdentifier:identifier
                        position:builder.positionValue
  buildinEventLogDisableStrategy:builder.buildinEventLogDisableStrategyValue
                          params:builder.paramsBuilder.params];
}

@end

@interface EventTracingLogSCMBuilder : NSObject<EventTracingLogSCMBuilder>
@property(nonatomic, strong) NSMutableArray<NSDictionary<NSString *, NSString *> *> *components;
@end

@interface EventTracingLogSCMComponentBuilder : NSObject<EventTracingLogSCMComponentBuilder>
@property(nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *json;
@property(nonatomic, weak) EventTracingLogSCMBuilder *scmBuilder;
@end

@implementation EventTracingLogSCMComponentBuilder
+ (instancetype)componentBuilderWithSCMBuilder:(EventTracingLogSCMBuilder *)scmBuilder {
    EventTracingLogSCMComponentBuilder *builder = [self new];
    builder.json = @{}.mutableCopy;
    builder.scmBuilder = scmBuilder;
    return builder;
}

#define EventTracingLogSCMComponentBuilderMethod(name)                                        \
- (id<EventTracingLogSCMComponentBuilder>  _Nonnull (^)(NSString * _Nullable))name {          \
    return ^(NSString * _Nullable value) {                                                      \
        self->_json[@"s_"#name] = value ?: @"";                                                 \
        return self;                                                                            \
    };                                                                                          \
}

EventTracingLogSCMComponentBuilderMethod(cid)
EventTracingLogSCMComponentBuilderMethod(ctype)
EventTracingLogSCMComponentBuilderMethod(ctraceid)
EventTracingLogSCMComponentBuilderMethod(ctrp)

- (id<EventTracingLogSCMBuilder>  _Nonnull (^)(void))pop {
    return ^() {
        [self.scmBuilder.components addObject:self.json.copy];
        return self.scmBuilder;
    };
}
@end

@implementation EventTracingLogSCMBuilder
- (instancetype)init {
    self = [super init];
    if (self) {
        self.components = @[].mutableCopy;
    }
    return self;
}
- (id<EventTracingLogSCMComponentBuilder>  _Nonnull (^)(void))pushComponent {
    return ^(void) {
        return [EventTracingLogSCMComponentBuilder componentBuilderWithSCMBuilder:self];
    };
}
@end

@implementation EventTracingBuilder (SCM)

+ (NSString *)buildSCM:(ET_BuildSCMBlock NS_NOESCAPE)builder {
    return [self buildSCM:builder er:nil];
}

+ (NSString *)buildSCM:(ET_BuildSCMBlock NS_NOESCAPE)builder er:(BOOL *)er {
    EventTracingLogSCMBuilder *builderInstance = [EventTracingLogSCMBuilder new];
    builder(builderInstance);
    
    NSMutableString *scm = @"".mutableCopy;
    [builderInstance.components enumerateObjectsUsingBlock:^(NSDictionary<NSString *,NSString *> * _Nonnull params, NSUInteger idx, BOOL * _Nonnull stop) {
        if (scm.length) {
            [scm appendString:@"|"];
        }
        NSString *value = [[EventTracingEngine sharedInstance].context.referNodeSCMFormatter nodeSCMWithNodeParams:params];
        [scm appendString:value];
        if (er
            && !(*er)
            && [[EventTracingEngine sharedInstance].context.referNodeSCMFormatter needsEncodeSCMForNodeParams:params]) {
            *er = YES;
        }
    }];
    
    return scm.copy;
}

@end

@implementation EventTracingLogNodeParamContentIdBuilder

+ (instancetype)contentBuilderWithParamsBuilder:(EventTracingLogNodeParamsBuilder *)paramsBuilder {
    EventTracingLogNodeParamContentIdBuilder *builder = [self new];
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

#define EventTracingLogNodeParamContentIdBuilderMethod(name)                                        \
- (id<EventTracingLogNodeParamContentIdBuilder>  _Nonnull (^)(NSString * _Nullable))name {          \
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

EventTracingLogNodeParamContentIdBuilderMethod(user)
EventTracingLogNodeParamContentIdBuilderMethod(playlist)
EventTracingLogNodeParamContentIdBuilderMethod(song)

- (id<EventTracingLogNodeParamContentIdBuilder>  _Nonnull (^)(NSString * _Nonnull, NSString * _Nonnull))cidtype {
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
- (id<EventTracingLogNodeParamContentIdBuilder>  _Nonnull (^)(NSString * _Nullable))ctraceid {
    return ^(NSString *ctraceid) {
        NSString *ctraceid_key = [NSString stringWithFormat:@"s_ctraceid_%@", self.ctype];
        self->_json[ctraceid_key] = ctraceid ?: @"";
        
        [self.paramsBuilder syncToNodeBuilder];
        return self;
    };
}

- (id<EventTracingLogNodeParamContentIdBuilder>  _Nonnull (^)(NSString * _Nullable))ctrp {
    return ^(NSString *ctrp) {
        NSString *ctrp_key = [NSString stringWithFormat:@"s_ctrp_%@", self.ctype];
        self->_json[ctrp_key] = ctrp ?: @"";
        
        [self.paramsBuilder syncToNodeBuilder];
        return self;
    };
}

- (id<EventTracingLogNodeParamsBuilder>  _Nonnull (^)(void))pop {
    return ^() {
        if (self.paramsBuilder) {
            self.paramsBuilder.addParams(self->_json);
            [self.paramsBuilder syncToNodeBuilder];
        }
        return self.paramsBuilder;
    };
}

@end

#pragma mark - EventTracingLogNodeBuilder
@implementation EventTracingLogNodeParamsBuilder
- (instancetype)init {
    self = [super init];
    if (self) {
        _json = [@{} mutableCopy];
    }
    return self;
}

- (void)clean {
    [self->_json removeAllObjects];
    [self.nodeBuilder.view et_removeAllParams];
}

- (void)syncToNodeBuilder {
    NSDictionary *json = [self->_json copy];
    [EventTracingBuilder checkForBlackListParamKeys:json.allKeys];
    [self.nodeBuilder.view et_addParams:json];
}

- (id<EventTracingLogNodeParamsBuilder> _Nonnull (^)(NSDictionary<NSString *,NSString *> * _Nullable))addParams {
    return ^(NSDictionary<NSString *,NSString *> *params) {
        if ([params isKindOfClass:NSDictionary.class]) {
            [self->_json addEntriesFromDictionary:params];
            
            [self syncToNodeBuilder];
        }
        return self;
    };
}
- (id<EventTracingLogNodeParamsBuilder>  _Nonnull (^)(NSString * _Nonnull, NSString * _Nullable))set {
    return ^(NSString *key, NSString *value) {
        self->_json[key] = value ?: @"";
        [self syncToNodeBuilder];
        return self;
    };
}

#define EventTracingLogNodeParamsBuilderMethod(name)                                    \
- (id<EventTracingLogNodeParamsBuilder>  _Nonnull (^)(NSString * _Nullable))name {      \
    return ^(NSString * _Nullable value) {                                              \
        self->_json[@"s_"#name] = value ?: @"";                                         \
        [self syncToNodeBuilder];                                                       \
        return self;                                                                    \
    };                                                                                  \
}

#define EventTracingLogNodeParamsBuilderMethodBollean(name)                             \
- (id<EventTracingLogNodeParamsBuilder>  _Nonnull (^)(BOOL))name {                      \
    return ^(BOOL value) {                                                              \
        self->_json[@"s_"#name] = value ? @"1" : @"0";                                  \
        [self syncToNodeBuilder];                                                       \
        return self;                                                                    \
    };                                                                                  \
}

EventTracingLogNodeParamsBuilderMethod(cid)
EventTracingLogNodeParamsBuilderMethod(ctype)
EventTracingLogNodeParamsBuilderMethod(ctraceid)
EventTracingLogNodeParamsBuilderMethod(ctrp)

- (id<EventTracingLogNodeParamsBuilder>  _Nonnull (^)(NSUInteger))position {
    return ^(NSUInteger value) {
        self.nodeBuilder.view.et_position = value;
        NSString *key = [NSString stringWithFormat:@"s%@", ET_REFER_KEY_POSITION];
        self->_json[key] = @(value).stringValue;
        
        [self syncToNodeBuilder];
        
        // 虚拟父节点也需要
        self.virtualParentNodeBuilder.positionValue = value;
        return self;
    };
}

- (id<EventTracingLogNodeParamContentIdBuilder>  _Nonnull (^)(void))pushContent {
    return ^(void) {
        return [EventTracingLogNodeParamContentIdBuilder contentBuilderWithParamsBuilder:self];
    };
}

- (id<EventTracingLogNodeParamsBuilder>  _Nonnull (^)(NS_NOESCAPE void (^ _Nonnull)(id<EventTracingLogNodeParamContentIdBuilder> _Nonnull)))pushContentWithBlock {
    return ^(void (^ _Nonnull NS_NOESCAPE block)(id<EventTracingLogNodeParamContentIdBuilder> _Nonnull)) {
        EventTracingLogNodeParamContentIdBuilder *builder = [EventTracingLogNodeParamContentIdBuilder contentBuilderWithParamsBuilder:self.nodeBuilder.paramsBuilder];
        block(builder);
        builder.pop();
        
        return self;
    };
}

EventTracingLogNodeParamsBuilderMethod(device)
EventTracingLogNodeParamsBuilderMethod(resolution)
EventTracingLogNodeParamsBuilderMethod(carrier)
EventTracingLogNodeParamsBuilderMethod(network)
EventTracingLogNodeParamsBuilderMethod(code)
EventTracingLogNodeParamsBuilderMethod(toid)

EventTracingLogNodeParamsBuilderMethod(module)
EventTracingLogNodeParamsBuilderMethod(title)
EventTracingLogNodeParamsBuilderMethod(subtitle)
EventTracingLogNodeParamsBuilderMethod(label)
EventTracingLogNodeParamsBuilderMethod(url)
EventTracingLogNodeParamsBuilderMethod(status)
EventTracingLogNodeParamsBuilderMethod(name)

- (id<EventTracingLogNodeParamsBuilder>  _Nonnull (^)(NSTimeInterval))time_S {
    return ^(NSTimeInterval value) {
        self.time_MS(value * 1000);
        return self;
    };
}

- (id<EventTracingLogNodeParamsBuilder>  _Nonnull (^)(NSTimeInterval))time_MS {
    return ^(NSTimeInterval value) {
        self->_json[@"s_time"] = [NSString stringWithFormat:@"%zd", (NSInteger)value];
        [self syncToNodeBuilder];
        return self;
    };
}

- (id<EventTracingLogNodeParamsBuilder>  _Nonnull (^)(NSDate * _Nonnull))timeFromStartDate {
    return ^(NSDate *startDate) {
        return self.time_S([[NSDate date] timeIntervalSinceDate:startDate]);
    };
}

- (NSDictionary *)params {
    return self->_json.copy;
}

@end

@implementation EventTracingLogNodeEventActionBuilder

- (id<EventTracingLogNodeEventActionBuilder>  _Nonnull (^)(BOOL))increaseActseq {
    return ^(BOOL value) {
        self->_increaseActseqValue = @(value);
        return self;
    };
}
- (id<EventTracingLogNodeEventActionBuilder>  _Nonnull (^)(void))useForRefer {
    return ^(void) {
        self->_useForReferValue = @YES;
        if (!self->_increaseActseqValue) {
            self->_increaseActseqValue = @YES;
        }
        return self;
    };
}

#define EventTracingLogNodeEventActionBuilderMethod(p, event)               \
- (id<EventTracingLogNodeParamsBuilder>  _Nonnull (^)(void))p {             \
    return ^(void) {                                                \
        self->_eventValue = event;                                  \
        return self;                                                \
    };                                                              \
}

EventTracingLogNodeEventActionBuilderMethod(pv, ET_EVENT_ID_P_VIEW)
EventTracingLogNodeEventActionBuilderMethod(pd, ET_EVENT_ID_P_VIEW_END)
EventTracingLogNodeEventActionBuilderMethod(ev, ET_EVENT_ID_E_VIEW)
EventTracingLogNodeEventActionBuilderMethod(ed, ET_EVENT_ID_E_VIEW_END)
EventTracingLogNodeEventActionBuilderMethod(ec, ET_EVENT_ID_E_CLCK)
EventTracingLogNodeEventActionBuilderMethod(elc, ET_EVENT_ID_E_LONG_CLCK)
EventTracingLogNodeEventActionBuilderMethod(es, ET_EVENT_ID_E_SLIDE)
EventTracingLogNodeEventActionBuilderMethod(pgf, ET_EVENT_ID_P_REFRESH)
EventTracingLogNodeEventActionBuilderMethod(plv, ET_EVENT_ID_PLV)
EventTracingLogNodeEventActionBuilderMethod(pld, ET_EVENT_ID_PLD)

- (id<EventTracingLogNodeParamsBuilder> _Nonnull (^)(NSString * _Nonnull))event {
    return ^(NSString *event) {
        self->_eventValue = event;
        return self;
    };
}

@end

@implementation EventTracingLogNodeUseForReferEventActionBuilder

- (id<EventTracingLogManuallyUseForReferEventActionBuilder> _Nonnull (^)(NSString * _Nonnull))event {
    return ^(NSString *event) {
        self->_eventValue = event;
        return self;
    };
}
- (id<EventTracingLogManuallyUseForReferEventActionBuilder>  _Nonnull (^)(NSString * _Nonnull))referSPM {
    return ^(NSString *value) {
        self.referSPMValue = value;
        return self;
    };
}
- (id<EventTracingLogManuallyUseForReferEventActionBuilder>  _Nonnull (^)(NSString * _Nonnull))referSCM {
    return ^(NSString *value) {
        self.referSCMValue = value;
        return self;
    };
}
- (id<EventTracingLogNodeParamsBuilder>  _Nonnull (^)(NSString * _Nonnull))referType {
    return ^(NSString *value) {
        self.referTypeValue = value;
        return self;
    };
}

@end

@implementation EventTracingLogNodeBuilder
- (instancetype)init {
    self = [super init];
    if (self) {
        _paramsBuilder = [[EventTracingLogNodeParamsBuilder alloc] init];
        _paramsBuilder.nodeBuilder = self;
    }
    return self;
}

#define EventTracingLogNodeBuilderMethod(TYPE, p)                                       \
- (id<EventTracingLogNodeBuilder>  _Nonnull (^)(TYPE))p {                               \
    return ^(TYPE value) {                                                      \
        self.view.et_ ## p = value;                                             \
        return self;                                                            \
    };                                                                          \
}

#define NELogETNodeVisibleBuilderMethod(TYPE, p)                                \
- (id<EventTracingLogNodeBuilder>  _Nonnull (^)(CGFloat)) p {                           \
    return ^(CGFloat value) {                                                   \
        UIEdgeInsets insets = self.view.et_visibleEdgeInsets;                   \
        insets.TYPE = value;                                                    \
        self.visibleEdgeInsets(insets);                                         \
        return self;                                                            \
    };                                                                          \
}

EventTracingLogNodeBuilderMethod(BOOL, logicalVisible)
EventTracingLogNodeBuilderMethod(UIEdgeInsets, visibleEdgeInsets)
NELogETNodeVisibleBuilderMethod(top, visibleEdgeInsetsTop)
NELogETNodeVisibleBuilderMethod(left, visibleEdgeInsetsLeft)
NELogETNodeVisibleBuilderMethod(bottom, visibleEdgeInsetsBottom)
NELogETNodeVisibleBuilderMethod(right, visibleEdgeInsetsRight)
EventTracingLogNodeBuilderMethod(ETNodeVisibleRectCalculateStrategy, visibleRectCalculateStrategy)

- (id<EventTracingLogNodeBuilder>  _Nonnull (^)(BOOL))visiblePassthrough {
    return ^(BOOL passthrough) {
        self.visibleRectCalculateStrategy(passthrough ? ETNodeVisibleRectCalculateStrategyPassthrough : ETNodeVisibleRectCalculateStrategyOnParentNode);
        return self;
    };
}

- (id<EventTracingLogNodeBuilder>  _Nonnull (^)(CGFloat))impressRatioThreshold {
    return ^(CGFloat ratio) {
        return self;
    };
}
- (id<EventTracingLogNodeBuilder> _Nonnull (^)(NSTimeInterval))impressIntervalThreshold_S {
    return ^(NSTimeInterval timeInterval) {
        return self;
    };
}
- (id<EventTracingLogNodeBuilder> _Nonnull (^)(NSTimeInterval))impressIntervalThreshold_MS {
    return ^(NSTimeInterval timeInterval) {
        return self;
    };
}

- (id<EventTracingLogNodeBuilder>  _Nonnull (^)(ETNodeBuildinEventLogDisableStrategy))buildinEventLogDisableStrategy {
    return ^(ETNodeBuildinEventLogDisableStrategy value) {
        self.view.et_buildinEventLogDisableStrategy = value;
        return self;
    };
}
- (id<EventTracingLogNodeBuilder>  _Nonnull (^)(void))buildinEventLogDisableClick {
    return ^(void) {
        self.view.et_buildinEventLogDisableStrategy |= ETNodeBuildinEventLogDisableStrategyClick;
        return self;
    };
}
- (id<EventTracingLogNodeBuilder>  _Nonnull (^)(void))buildinEventLogDisableImpress {
    return ^(void) {
        self.view.et_buildinEventLogDisableStrategy |= ETNodeBuildinEventLogDisableStrategyImpress;
        return self;
    };
}
- (id<EventTracingLogNodeBuilder>  _Nonnull (^)(BOOL))buildinEventLogDisableImpressend {
    return ^(BOOL value) {
        if (value) {
            self.view.et_buildinEventLogDisableStrategy |= ETNodeBuildinEventLogDisableStrategyImpressend;
        } else if (self.view.et_buildinEventLogDisableStrategy & ETNodeBuildinEventLogDisableStrategyImpressend) {
            self.view.et_buildinEventLogDisableStrategy &= ~ETNodeBuildinEventLogDisableStrategyImpressend;
        }
        return self;
    };
}
- (id<EventTracingLogNodeBuilder>  _Nonnull (^)(void))buildinEventLogDisableAll {
    return ^(void) {
        self.view.et_buildinEventLogDisableStrategy = ETNodeBuildinEventLogDisableStrategyAll;
        return self;
    };
}

EventTracingLogNodeBuilderMethod(UIViewController *, logicalParentViewController)
EventTracingLogNodeBuilderMethod(UIView *, logicalParentView)
EventTracingLogNodeBuilderMethod(NSString *, logicalParentSPM)

- (id<EventTracingLogNodeBuilder>  _Nonnull (^)(BOOL))autoMountOnCurrentRootPage {
    return ^(BOOL mount) {
        if (mount) {
            [self.view et_autoMountOnCurrentRootPage];
        } else {
            [self.view et_cancelAutoMountOnCurrentRootPage];
        }
        return self;
    };
}

- (id<EventTracingLogNodeBuilder>  _Nonnull (^)(BOOL))autoMountOnCuurentRootPage {
    return self.autoMountOnCurrentRootPage;
}

- (id<EventTracingLogNodeBuilder> _Nonnull (^)(ETAutoMountRootPageQueuePriority))autoMountOnCuurentRootPageWithPriority {
    return self.autoMountOnCurrentRootPageWithPriority;
}

- (id<EventTracingLogNodeBuilder>  _Nonnull (^)(ETAutoMountRootPageQueuePriority))autoMountOnCurrentRootPageWithPriority {
    return ^(ETAutoMountRootPageQueuePriority priority) {
        [self.view et_autoMountOnCurrentRootPageWithPriority:priority];
        return self;
    };
}

- (id<EventTracingLogNodeBuilder>  _Nonnull (^)(BOOL))pageOcclusionEnable {
    return ^(BOOL pageOcclusionEnable) {
        self.view.et_pageOcclusionEnable = pageOcclusionEnable;
        return self;
    };
}

- (void)_et_setVirtualParentOid:(NSString *)oid
                         isPage:(BOOL)isPage
                     identifier:(id)identifier
                   builderBlock:(ET_BuildVirtualParentBlock)block
{
    if (![oid isKindOfClass:NSString.class] || oid.length == 0 || !identifier) {
        return;
    }
    
    EventTracingLogVirtualParentNodeBuilder *builder = [[EventTracingLogVirtualParentNodeBuilder alloc] init];
    !block ?: block(builder);
    
    [self.view et_setVirtualParentOid:oid
                               isPage:isPage
                       nodeIdentifier:identifier
                             position:builder.positionValue
       buildinEventLogDisableStrategy:builder.buildinEventLogDisableStrategyValue
                               params:builder.paramsBuilder.params];
}

- (id<EventTracingLogNodeBuilder>  _Nonnull (^)(NSString * _Nonnull, id _Nonnull, ET_BuildVirtualParentBlock NS_NOESCAPE _Nullable))virtualParent {
    return ^(NSString *elementId, id identifier, ET_BuildVirtualParentBlock block) {
        [self _et_setVirtualParentOid:elementId isPage:NO identifier:identifier builderBlock:block];
        return self;
    };
}

- (id<EventTracingLogNodeBuilder>  _Nonnull (^)(NSString * _Nonnull, id _Nonnull, ET_BuildVirtualParentBlock NS_NOESCAPE _Nullable))virtualPageParent {
    return ^(NSString *pageId, id identifier, ET_BuildVirtualParentBlock block) {
        [self _et_setVirtualParentOid:pageId isPage:YES identifier:identifier builderBlock:block];
        return self;
    };
}

- (id<EventTracingLogNodeBuilder> _Nonnull (^)(id _Nonnull))bindDataForReuse {
    return ^(id data) {
        [self.view et_bindDataForReuse:data];
        
        if ([data isKindOfClass:NSString.class] || [data isKindOfClass:NSArray.class] || [data isKindOfClass:NSDictionary.class]) {
            return self;
        }
        
        return self;
    };
}

- (id<EventTracingLogNodeBuilder>  _Nonnull (^)(BOOL))enableSubPageProducePvRefer {
    return ^(BOOL value) {
        self.view.et_subpagePvToReferEnable = value;
        return self;
    };
}

- (id<EventTracingLogNodeBuilder>  _Nonnull (^)(BOOL))enableSubPageConsumeAllRefer {
    return ^(BOOL value) {
        if (value) {
            [self.view et_makeSubpageConsumeAllRefer];
        } else {
            [self.view et_clearSubpageConsumeReferOption];
        }
        return self;
    };
}

- (id<EventTracingLogNodeBuilder>  _Nonnull (^)(BOOL))enableSubPageConsumeEventRefer {
    return ^(BOOL value) {
        if (value) {
            [self.view et_makeSubpageConsumeEventRefer];
        } else {
            [self.view et_clearSubpageConsumeReferOption];
        }
        return self;
    };
}

- (id<EventTracingLogNodeBuilder>  _Nonnull (^)(NSString * _Nonnull))bindDataForReuseWithAutoClassifyIdAppend {
    return ^(NSString *identifier) {
        [self.view et_bindDataForReuse:self.view.et_autoClassifyIdAppend(identifier)];
        return self;
    };
}
- (id<EventTracingLogNodeBuilder>  _Nonnull (^)(NSString * _Nonnull))referToid {
    return ^(NSString *toid) {
        [self.view et_makeReferToid:toid];
        return self;
    };
}

- (id<EventTracingLogNodeBuilder>  _Nonnull (^)(BOOL))ignoreReferCascade {
    return ^(BOOL value) {
        self.view.et_ignoreReferCascade = value;
        return self;
    };
}

- (id<EventTracingLogNodeBuilder>  _Nonnull (^)(BOOL))doNotParticipateMultirefer {
    return ^(BOOL value) {
        self.view.et_psreferMute = value;
        return self;
    };
}

- (id<EventTracingLogNodeParamsBuilder>)params {
    return self.paramsBuilder;
}
- (id<EventTracingLogNodeParamsBuilder>)emptyParams {
    [self.paramsBuilder clean];
    return self.paramsBuilder;
}

- (id<EventTracingLogNodeBuilder>  _Nonnull (^)(ET_BuildParamsBlock _Nullable))addParamsCallback {
    return ^(ET_BuildParamsBlock block) {
        [self.view et_addParamsCallback:^NSDictionary * _Nonnull{
            EventTracingLogNodeParamsBuilder *builder = [[EventTracingLogNodeParamsBuilder alloc] init];
            !block ?: block(builder);
            return builder.params;
        }];
        return self;
    };
}

- (id<EventTracingLogNodeBuilder>  _Nonnull (^)(ET_BuildParamsBlock _Nullable))addClickParamsCallback {
    return ^(ET_BuildParamsBlock block) {
        return self.addParamsCallbackForEvent(ET_EVENT_ID_E_CLCK, block);
    };
}

- (id<EventTracingLogNodeBuilder>  _Nonnull (^)(ET_BuildParamsBlock _Nullable))addLongClickParamsCallback {
    return ^(ET_BuildParamsBlock block) {
        return self.addParamsCallbackForEvent(ET_EVENT_ID_E_LONG_CLCK, block);
    };
}

- (id<EventTracingLogNodeBuilder>  _Nonnull (^)(NSString * _Nonnull, ET_BuildParamsBlock _Nullable))addParamsCallbackForEvent {
    return ^(NSString *event, ET_BuildParamsBlock block) {
        [self.view et_addParamsCallback:^NSDictionary * _Nonnull{
            EventTracingLogNodeParamsBuilder *builder = [[EventTracingLogNodeParamsBuilder alloc] init];
            !block ?: block(builder);
            return builder.params;
        } forEvent:event];
        return self;
    };
}
- (id<EventTracingLogNodeBuilder>  _Nonnull (^)(NSArray<NSString *> * _Nonnull, ET_BuildParamsBlock _Nullable))addParamsCallbackForEvents {
    return ^(NSArray<NSString *> *events, ET_BuildParamsBlock block) {
        [self.view et_addParamsCallback:^NSDictionary * _Nonnull{
            EventTracingLogNodeParamsBuilder *builder = [[EventTracingLogNodeParamsBuilder alloc] init];
            !block ?: block(builder);
            return builder.params;
        } forEvents:events];
        return self;
    };
}

- (id<EventTracingLogNodeBuilder>  _Nonnull (^)(NSArray<NSString *> * _Nonnull, ET_BuildParamsCarryEventsBlock _Nullable))addParamsCarryEventCallbackForEvents {
    return ^(NSArray<NSString *> *events, ET_BuildParamsCarryEventsBlock block) {
        [self.view et_addParamsCarryEventCallback:^NSDictionary * _Nonnull(NSString *event) {
            EventTracingLogNodeParamsBuilder *builder = [[EventTracingLogNodeParamsBuilder alloc] init];
            !block ?: block(builder, event);
            return builder.params;
        } forEvents:events];
        return self;
    };
}

- (void)build:(ET_BuildBlock NS_NOESCAPE)block {
    if (self.view && block) {
        block(self);
    }
}

@end

@implementation EventTracingLogVirtualParentNodeBuilder
- (instancetype)init {
    self = [super init];
    if (self) {
        _paramsBuilder = [[EventTracingLogNodeParamsBuilder alloc] init];
        _paramsBuilder.virtualParentNodeBuilder = self;
        
        _buildinEventLogDisableStrategyValue = [EventTracingEngine sharedInstance].context.isElementAutoImpressendEnable ? ETNodeBuildinEventLogDisableStrategyNone : ETNodeBuildinEventLogDisableStrategyImpressend;
    }
    return self;
}
- (id<EventTracingLogVirtualParentNodeBuilder>  _Nonnull (^)(ETNodeBuildinEventLogDisableStrategy))buildinEventLogDisableStrategy {
    return ^(ETNodeBuildinEventLogDisableStrategy value) {
        self.buildinEventLogDisableStrategyValue |= value;
        return self;
    };
}
- (id<EventTracingLogVirtualParentNodeBuilder>  _Nonnull (^)(void))buildinEventLogDisableImpress {
    return ^(void) {
        self.buildinEventLogDisableStrategyValue |= ETNodeBuildinEventLogDisableStrategyImpress;
        return self;
    };
}
- (id<EventTracingLogVirtualParentNodeBuilder>  _Nonnull (^)(BOOL))buildinEventLogDisableImpressend {
    return ^(BOOL value) {
        if (value) {
            self.buildinEventLogDisableStrategyValue |= ETNodeBuildinEventLogDisableStrategyImpressend;
        } else if (self.buildinEventLogDisableStrategyValue & ETNodeBuildinEventLogDisableStrategyImpressend) {
            self.buildinEventLogDisableStrategyValue &= ~ETNodeBuildinEventLogDisableStrategyImpressend;
        }
        return self;
    };
}
- (id<EventTracingLogVirtualParentNodeBuilder>  _Nonnull (^)(void))buildinEventLogDisableAll {
    return ^(void) {
        self.buildinEventLogDisableStrategyValue = ETNodeBuildinEventLogDisableStrategyAll;
        return self;
    };
}

- (id<EventTracingLogNodeParamsBuilder>)params {
    return _paramsBuilder;
}
@end

@implementation UIView (BILogBuilder)
- (EventTracingLogNodeBuilder *)et_nodeBuilder {
    return objc_getAssociatedObject(self, _cmd);
}
- (void)et_setNodeBuilder:(EventTracingLogNodeBuilder *)et_nodeBuilder {
    objc_setAssociatedObject(self, @selector(et_nodeBuilder), et_nodeBuilder, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)et_build:(ET_BuildBlock NS_NOESCAPE)block {
    EventTracingLogNodeBuilder *builder = self.et_nodeBuilder;
    if (!builder || !block) {
        return;
    }
    
    block(builder);
}

- (void)et_buildParams:(ET_BuildParamsBlock NS_NOESCAPE)block {
    EventTracingLogNodeBuilder *builder = self.et_nodeBuilder;
    if (!builder.params || !block) {
        return;
    }
    block(builder.params);
}

@end
@implementation UIViewController (BILogBuilder)
- (void)et_build:(ET_BuildBlock NS_NOESCAPE)block {
    [self.view et_build:block];
}

- (void)et_buildParams:(ET_BuildParamsBlock NS_NOESCAPE)block {
    [self.view et_buildParams:block];
}
@end

@interface UIView (ETNodeDynamicParams_Private) <EventTracingVTreeNodeDynamicParamsProtocol>
@end
@implementation UIView (ETNodeExtraParams)
- (NSDictionary *)et_dynamicParams {
    EventTracingLogNodeParamsBuilder *builder = [EventTracingLogNodeParamsBuilder new];
    
    UIViewController *vc = (UIViewController *)self.nextResponder;
    if ([vc isKindOfClass:UIViewController.class]) {
        [vc et_makeDynamicParams:builder];
    }
    
    ET_CallLogNodeDynamicParamsBuilder(self, et_makeDynamicParams:)
    [self et_makeDynamicParams:builder];
    
    // 将 position 同步到节点配置中
    id position = [builder.params objectForKey:ET_PARAM_CONST_KEY_POSITION];
    if (position) {
        self.et_position = [position unsignedIntegerValue];
    }
    
    return builder.params;
}

- (void)et_makeDynamicParams:(id<EventTracingLogNodeParamsBuilder>)builder { }
@end

@interface UIViewController (ETNodeDynamicParams_Private) <EventTracingVTreeNodeDynamicParamsProtocol>
@end
@implementation UIViewController (ETNodeExtraParams)
- (NSDictionary *)et_dynamicParams {
    return [self.view et_dynamicParams];
}
- (void)et_makeDynamicParams:(id<EventTracingLogNodeParamsBuilder>)builder {}
@end



static void _check_node_oid_overwrite(UIView *view, bool isPage, NSString *oid)
{
    if (!s_enable_check_node_oid_overwrite) {
        return;
    }
    id element = view;
    NSString *ori_oid = isPage ? [element et_pageId] : [element et_elementId];
    NSString *ori_anotherOid;
    if (isPage && [element respondsToSelector:@selector(et_elementId)]) {
        ori_anotherOid = [element et_elementId];
    } else if (!isPage && [element respondsToSelector:@selector(et_pageId)]) {
        ori_anotherOid = [element et_pageId];
    }
    
    bool isOidWillChanged = (oid && ori_oid && ![oid isEqualToString:ori_oid]); // oid 将发生变更
    bool isEidPidExistAtTheSameTime = ori_anotherOid != nil; // pid 和 eid 同时存在
    if (isOidWillChanged || isEidPidExistAtTheSameTime) {
        NSString *nodeDesc = NSStringFromClass([element class]);
        if ([element isKindOfClass:UIView.class]) {
            if ([(UIView *)element et_logicalParentViewController]) {
                nodeDesc = NSStringFromClass([(UIView *)element et_logicalParentViewController].class);
            } else if ([(UIView *)element respondsToSelector:@selector(et_currentViewController)]) {
                nodeDesc = NSStringFromClass([[(UIView *)element performSelector:@selector(et_currentViewController)] class]);
            }
        }
        NSString *message = [NSString stringWithFormat:@"⚠️节点oid变更 %@: 原oid:%@ => 新oid:%@⚠️\n%@\n%@\n%@",
                             nodeDesc, ori_oid ?: ori_anotherOid, oid,
                             @"1. 一个view设置了oid后，就是一个节点，如果该节点再次被设置成另外一个oid，那就成了另外一个节点，这样会把之前的oid覆盖掉",
                             @"2. 如果确实需要重新覆盖oid，请显式的「clean」掉之前的 oid（-[UIView et_clear]），再设置新的oid",
                             @"3. 建议和此埋点的相关同学进行充分沟通，以确保不对历史埋点产生意料之外的影响"];
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"[曙光]重复设置节点oid提示" message:message preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
    }
}


static NSMutableDictionary<NSString *, NSString *> *BlackListParamKeyMap;
static NSMutableArray<NSString *> *alertedParamKeys = nil;

@implementation EventTracingBuilder (BlackListParamKey)

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
