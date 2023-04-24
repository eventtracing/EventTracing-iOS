//
//  NEEventTracingEventRefer+Private.h
//  NEEventTracing
//
//  Created by dl on 2022/2/23.
//

#import "NEEventTracingEventRefer.h"
#import "NEEventTracingFormattedRefer.h"
#import "NEEventTracingVTreeNode.h"

NS_ASSUME_NONNULL_BEGIN

/// MARK: 非公开的几个内部方法
FOUNDATION_EXPORT
id<NEEventTracingFormattedRefer> NE_ET_formattedReferForNode(NEEventTracingVTreeNode *node, BOOL useNextActseq);


@class NEEventTracingFormattedEventRefer;
@interface NEEventTracingEventRefer : NSObject <NEEventTracingEventRefer>

@property(nonatomic, copy, readwrite) NSString *event;
@property(nonatomic, assign, readwrite) NSTimeInterval eventTime;

@end

/// MARK: 1.1 rootpage 名下，或者app全局级别 生成的refer
/// MARK: 1.2 rootpage 曝光对应的refer
@interface NEEventTracingFormattedEventRefer : NEEventTracingEventRefer

@property(nonatomic, assign) BOOL shouldStartHsrefer;

@property(nonatomic, assign, readonly, getter=isRootPagePV) BOOL rootPagePV;     // 是否是 root page PV
@property(nonatomic, weak, nullable) NEEventTracingFormattedEventRefer *parentRefer;    // 普通的refer可能存在 parentRefer(rootPagePV == YES)
@property(nonatomic, strong, readonly) NSArray<NEEventTracingFormattedEventRefer *> *subRefers;   // 当 rootPagePV == YES时，subRefers可能有多个
@property(nonatomic, assign) NSInteger appEnterBackgroundSeq;

@property(nonatomic, strong) id<NEEventTracingFormattedRefer> formattedRefer;

@property(nonatomic, assign) BOOL psreferMute; //psrefer 静默

+(instancetype)referWithEvent:(NSString *)event
               formattedRefer:(id<NEEventTracingFormattedRefer>)formattedRefer
                   rootPagePV:(BOOL)rootPagePV
           shouldStartHsrefer:(BOOL)shouldStartHsrefer
           isNodePsreferMuted:(BOOL)isNodePsreferMuted;

- (void)addSubRefer:(NEEventTracingFormattedEventRefer *)refer;

@end

/// MARK: 2. undefined-xpath refer
// 一个 undefined-xpath 可能会关联一个 formetted refer，如果关联不上，则可认为
@interface NEEventTracingUndefinedXpathEventRefer : NEEventTracingEventRefer

+(instancetype)referWithEvent:(NSString *)event
          undefinedXpathRefer:(NSString *)undefinedXpathRefer;

@end

/// MARK: 便捷工具方法
@interface NEEventTracingFormattedEventRefer (Util)
+ (instancetype)becomeActiveRefer;
+ (instancetype)enterForegroundRefer;
@end

/// MARK: 对外临时封装，对应的refer中可能不包含sessid，业务侧获取 event refer 的时候，需要带上
@interface NEEventTracingFormattedWithSessidUndefinedXpathEventRefer : NEEventTracingEventRefer

+(instancetype)referFromFormattedEventRefer:(NEEventTracingFormattedEventRefer *)formattedEventRefer
                                 withSessid:(BOOL)withSessid
                             undefinedXpath:(BOOL)undefinedXPath;

@end

NS_ASSUME_NONNULL_END
