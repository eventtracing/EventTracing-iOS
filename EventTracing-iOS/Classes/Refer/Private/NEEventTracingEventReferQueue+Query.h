//
//  EventTracingEventReferQueue+Query.h
//  EventTracing
//
//  Created by 熊勋泉 on 2023/2/22.
//

#import "EventTracingEventReferQueue.h"
#import "EventTracingEventRefer+Private.h"

NS_ASSUME_NONNULL_BEGIN

@interface EventTracingEventReferQueryParams : NSObject

/// 站在 refer 消费侧，关心的 refer 类型有哪些
@property (nonatomic, assign) EventTracingPageReferConsumeOption referConsumeOption;

/// 针对获取事件 refer 场景，可以指定事件来获取refer
@property (nonatomic, copy, nullable) NSString *event;

/// 对于 `subpage_pv`  场景，refer的生成和消费，是需要限定在一个 rootPage 曝光周期内的
@property (nonatomic, strong, nullable) EventTracingVTreeNode *rootPageNode;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

@interface EventTracingEventReferQueryResult : NSObject

@property(nonatomic, assign, readonly, getter=isValid) BOOL valid; //如果发生降级，则为 false，否则为 true
@property(nonatomic, strong, readonly, nullable) id<EventTracingEventRefer> refer; // psrefer

/// 在 refer 查找过程中，以下refer可能都获取，从而得出最终该使用的refer
@property(nonatomic, strong, readonly, nullable) EventTracingFormattedEventRefer * latestRootPageRefer;
@property(nonatomic, strong, readonly, nullable) EventTracingFormattedEventRefer * latestSubPageRefer;
@property(nonatomic, strong, readonly, nullable) EventTracingFormattedEventRefer * latestEventRefer;

@property(nonatomic, strong, readonly, nullable) id<EventTracingEventRefer> latestUndefinedXpathRefer;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
@end


typedef void(^EventTracingReferQueryBuilder)(EventTracingEventReferQueryParams *params);

/// MARK: AOP pre 时机，将 event refer 放入队列，供业务方在 event handler 内部即可获取refer
/// MARK: 内部会 actseq 做 `预+1` 操作
@interface EventTracingEventReferQueue (Query)

- (EventTracingEventReferQueryResult *)queryWithBuilder:(EventTracingReferQueryBuilder NS_NOESCAPE)block;

@end

NS_ASSUME_NONNULL_END
