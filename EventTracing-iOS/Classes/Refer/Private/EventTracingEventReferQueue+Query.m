//
//  EventTracingEventReferQueue+Query.m
//  EventTracing
//
//  Created by 熊勋泉 on 2023/2/22.
//

#import "EventTracingEventReferQueue+Query.h"

@interface EventTracingEventReferQueryParams()

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
@end

@implementation EventTracingEventReferQueryParams
+ (instancetype)params {
    EventTracingEventReferQueryParams *params = [[EventTracingEventReferQueryParams alloc] init];
    params.referConsumeOption = EventTracingPageReferConsumeOptionExceptSubPagePV;
    return params;
}
@end


@interface EventTracingEventReferQueryResult()
@property (nonatomic, strong) EventTracingEventReferQueryParams * params;

@property(nonatomic, assign, readwrite, getter=isValid) BOOL valid; //如果发生降级，则为 false，否则为 true

/// 在 refer 查找过程中，以下refer可能都获取，从而得出最终该使用的refer
@property(nonatomic, strong, readwrite, nullable) EventTracingFormattedEventRefer * latestRootPageRefer;
@property(nonatomic, strong, readwrite, nullable) EventTracingFormattedEventRefer * latestSubPageRefer;
@property(nonatomic, strong, readwrite, nullable) EventTracingFormattedEventRefer * latestEventRefer;
@end

@implementation EventTracingEventReferQueryResult

@synthesize latestUndefinedXpathRefer = _latestUndefinedXpathRefer;

- (instancetype)initWithParams:(EventTracingEventReferQueryParams *)params
     latestUndefinedXpathRefer:(id<EventTracingEventRefer> _Nullable)latestUndefinedXpathRefer
{
    if (self = [super init]) {
        _params = params;
        _latestUndefinedXpathRefer = latestUndefinedXpathRefer;
    }
    return self;
}

- (BOOL)checkRootReferOK
{
    return self.latestRootPageRefer != nil;
}

- (BOOL)checkConsumeOptionReferOK
{
    if (self.params.event.length > 0 &&
        (nil == self.latestEventRefer ||
         NO == [self.latestEventRefer.event isEqualToString:self.params.event])) {
        // 需要匹配 event 时，没有正确的 event refer
        return NO;
    }
    if ((self.params.referConsumeOption & EventTracingPageReferConsumeOptionSubPagePV)
        && self.latestSubPageRefer == nil) {
        // 需要 subpage pv refer 却没有
        return NO;
    }
    BOOL needEcEventRefer = self.params.referConsumeOption & EventTracingPageReferConsumeOptionEventEc;
    BOOL needCustomEventRefer = self.params.referConsumeOption & EventTracingPageReferConsumeOptionCustom;
    if ((needEcEventRefer || needCustomEventRefer) && self.latestEventRefer == nil) {
        // 需要 event refer 却没有
        return NO;
    }
    return YES;
}

- (void)updateForConsumeOptionWithRefer:(EventTracingFormattedEventRefer *)refer inCurrentRoot:(BOOL)inCurrentRoot
{
    if (refer == nil) {
        return;
    }
    // 根节点更新
    if (refer.isRootPagePV) {
        if (self->_latestRootPageRefer.eventTime < refer.eventTime) {
            self->_latestRootPageRefer = refer;
        }
    }
    // 当前 rootpage 名下的子节点
    else if ([refer.event isEqualToString:ET_EVENT_ID_P_VIEW]) {
        if (inCurrentRoot && (self.params.referConsumeOption & EventTracingPageReferConsumeOptionSubPagePV)) {
            if (self->_latestSubPageRefer.eventTime < refer.eventTime) {
                self->_latestSubPageRefer = refer;
            }
        }
    }
    // 当前根页面名下的 ec 事件
    else
    {
        // 是否是 ec 事件，如果不是 ec 事件，则一定是自定义事件
        BOOL isEcEvent = ([refer.event isEqualToString:ET_EVENT_ID_E_CLCK]);
        BOOL isEcEventRefer =
        isEcEvent && (self.params.referConsumeOption & EventTracingPageReferConsumeOptionEventEc);
        
        BOOL isCustomEventRefer =
        !isEcEvent && (self.params.referConsumeOption & EventTracingPageReferConsumeOptionCustom);
        
        if (isEcEventRefer || isCustomEventRefer) {
            if (self->_latestEventRefer.eventTime < refer.eventTime) {
                self->_latestEventRefer = refer;
            }
        }
    }
}

- (id<EventTracingEventRefer>)refer {
    /// MARK: 1.兜底的 page refer，含 subpage refer 和 rootpage refer
    if (self->_latestRootPageRefer == nil) {
        /// root page refer 兜底
        self->_latestRootPageRefer = [[EventTracingEventReferQueue queue] fetchLastestRootPagePVRefer];
    }
    EventTracingFormattedEventRefer *latestPageRefer =
    self.latestRootPageRefer.eventTime > self.latestSubPageRefer.eventTime ?
    self.latestRootPageRefer           : self.latestSubPageRefer;
    
    /// MARK: 2.降级策略
    ///   <1> 如果匹配的 `refer -> actionTime` 比 `rootPage -> _pv -> actionTime` 还提前，则降级
    ///   <2> 或者 该事件未发生在该 `rootPage` 内，则也降级
    
    // 判断该次找到的 event refer 是否可用，不可用则「降级」
    BOOL eventReferValid =
    /// MARK: 1. event refer 要比最近的 page pv 要晚，否则不可用
    self.latestEventRefer.eventTime >= latestPageRefer.eventTime &&
    /// MARK: 2. event refer 还要比最近的「非节点的view事件」要晚，否则不可用
    self.latestEventRefer.eventTime >= _latestUndefinedXpathRefer.eventTime;
    
    
    _valid = eventReferValid;
    if (_valid) {
        /// 优先考虑 event refer
        return self.latestEventRefer;
    } else {
        /// 降级到 page refer
        return latestPageRefer;
    }
}

@end

@implementation EventTracingEventReferQueue (Query)

- (EventTracingEventReferQueryResult *)queryWithBuilder:(EventTracingReferQueryBuilder NS_NOESCAPE)block
{
    EventTracingEventReferQueryParams *params = [EventTracingEventReferQueryParams params];
    !block ?: block(params);
    
    EventTracingUndefinedXpathEventRefer *latestUndefinedXpathRefer;
    if (params.event.length > 0) {
        latestUndefinedXpathRefer = [self undefinedXpath_fetchLastestEventReferForEvent:params.event];
    } else {
        latestUndefinedXpathRefer = [self undefinedXpath_fetchLastestEventRefer];
    }
    
    EventTracingEventReferQueryResult * result =
    [[EventTracingEventReferQueryResult alloc] initWithParams:params
                                      latestUndefinedXpathRefer:latestUndefinedXpathRefer];
    
    [self _pickupPsreferForResult:result];
    return result;
}

- (void)_pickupPsreferForResult:(EventTracingEventReferQueryResult *)result {
    if (!result.params) {
        // 参数错误
        NSParameterAssert(false);
        return;
    }
    NSArray<EventTracingFormattedEventRefer *> * allRefers = self.allRefers;
    [allRefers enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(EventTracingFormattedEventRefer * _Nonnull refer, NSUInteger idx, BOOL * _Nonnull stop) {
        if (refer.isRootPagePV && ![result checkConsumeOptionReferOK]) {
            BOOL inCurrentRoot = (result.params.rootPageNode &&
                                  [refer.formattedRefer.spm isEqualToString:result.params.rootPageNode.spm] &&
                                  [refer.formattedRefer.scm isEqualToString:result.params.rootPageNode.scm]);

            [refer.subRefers enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(EventTracingFormattedEventRefer * _Nonnull subrefer, NSUInteger idx, BOOL * _Nonnull stop) {
                // `event refer` or `subpage pv refer`
                [result updateForConsumeOptionWithRefer:subrefer inCurrentRoot:inCurrentRoot];
                
                if ([result checkConsumeOptionReferOK]) {
                    *stop = YES;
                }
            }];
        }
        // `event refer` or `rootpage pv refer`
        [result updateForConsumeOptionWithRefer:refer inCurrentRoot:NO];

        // 如果 option's event refer 和 rootpage refer 都OK了，退出循环
        if ([result checkRootReferOK] && [result checkConsumeOptionReferOK])
        {
            *stop = YES;
        }
    }];
}

@end
