//
//  EventTracingEventRefer+Private.h
//  EventTracing
//
//  Created by dl on 2022/2/23.
//

#import "EventTracingEventRefer.h"
#import "EventTracingFormattedRefer.h"
#import "EventTracingVTreeNode.h"

NS_ASSUME_NONNULL_BEGIN

/// MARK: 非公开的几个内部方法
FOUNDATION_EXPORT
id<EventTracingFormattedRefer> ET_formattedReferForNode(EventTracingVTreeNode *node, BOOL useNextActseq);


@class EventTracingFormattedEventRefer;
@interface EventTracingEventRefer : NSObject <EventTracingEventRefer>

@property(nonatomic, copy, readwrite) NSString *event;
@property(nonatomic, assign, readwrite) NSTimeInterval eventTime;

@end

/// MARK: 1.1 rootpage 名下，或者app全局级别 生成的refer
/// MARK: 1.2 rootpage 曝光对应的refer
@interface EventTracingFormattedEventRefer : EventTracingEventRefer

@property(nonatomic, copy, nullable) NSArray<NSString *> *toids;
@property(nonatomic, assign) BOOL shouldStartHsrefer;

@property(nonatomic, assign, readonly, getter=isRootPagePV) BOOL rootPagePV;     // 是否是 root page PV
@property(nonatomic, weak, nullable) EventTracingFormattedEventRefer *parentRefer;    // 普通的refer可能存在 parentRefer(rootPagePV == YES)
@property(nonatomic, strong, readonly) NSArray<EventTracingFormattedEventRefer *> *subRefers;   // 当 rootPagePV == YES时，subRefers可能有多个
@property(nonatomic, assign) NSInteger appEnterBackgroundSeq;

@property(nonatomic, strong) id<EventTracingFormattedRefer> formattedRefer;

@property(nonatomic, assign) BOOL psreferMute; //psrefer 静默

+(instancetype)referWithEvent:(NSString *)event
               formattedRefer:(id<EventTracingFormattedRefer>)formattedRefer
                   rootPagePV:(BOOL)rootPagePV
                        toids:(NSArray<NSString *> * _Nullable)toids
           shouldStartHsrefer:(BOOL)shouldStartHsrefer
           isNodePsreferMuted:(BOOL)isNodePsreferMuted;

- (void)addSubRefer:(EventTracingFormattedEventRefer *)refer;

@end

/// MARK: 2. undefined-xpath refer
// 一个 undefined-xpath 可能会关联一个 formetted refer，如果关联不上，则可认为
@interface EventTracingUndefinedXpathEventRefer : EventTracingEventRefer

+(instancetype)referWithEvent:(NSString *)event
          undefinedXpathRefer:(NSString *)undefinedXpathRefer;

@end

/// MARK: 便捷工具方法
@interface EventTracingFormattedEventRefer (Util)
+ (instancetype)becomeActiveRefer;
+ (instancetype)enterForegroundRefer;
@end

/// MARK: 对外临时封装，对应的refer中可能不包含sessid，业务侧获取 event refer 的时候，需要带上
@interface EventTracingFormattedWithSessidUndefinedXpathEventRefer : EventTracingEventRefer

+(instancetype)referFromFormattedEventRefer:(EventTracingFormattedEventRefer *)formattedEventRefer
                                 withSessid:(BOOL)withSessid
                             undefinedXpath:(BOOL)undefinedXPath;

@end

NS_ASSUME_NONNULL_END
