//
//  EventTracingEventReferQueue.h
//  EventTracing
//
//  Created by dl on 2021/4/1.
//

#import <Foundation/Foundation.h>
#import "EventTracingEventRefer+Private.h"

NS_ASSUME_NONNULL_BEGIN

@interface EventTracingEventReferQueue : NSObject

@property(nonatomic, strong, readonly) NSArray<EventTracingFormattedEventRefer *> *allRefers;

+ (instancetype)queue;

- (void)pushEventRefer:(EventTracingFormattedEventRefer *)refer;
- (void)pushEventRefer:(EventTracingFormattedEventRefer *)refer
                  node:(EventTracingVTreeNode * _Nullable)node
             isSubPage:(BOOL)isSubPage;
- (void)removeEventRefer:(EventTracingFormattedEventRefer *)refer;
- (void)clear;

@end

/// MARK: AOP pre 时机，将 event refer 放入队列，供业务方在 event handler 内部即可获取refer
/// MARK: 内部会 actseq 做 `预+1` 操作
@interface EventTracingEventReferQueue (EventRefer)

- (BOOL)pushEventReferForEvent:(NSString *)event
                          view:(UIView *)view
                          node:(EventTracingVTreeNode * _Nullable)node
                   useForRefer:(BOOL)useForRefer
                 useNextActseq:(BOOL)useNextActseq;

- (void)rootPageNodeDidImpress:(EventTracingVTreeNode * _Nullable)node
                       inVTree:(EventTracingVTree * _Nullable)VTree;

- (void)subPageNodeDidImpress:(EventTracingVTreeNode * _Nullable)node
                      inVTree:(EventTracingVTree * _Nullable)VTree;

- (EventTracingFormattedEventRefer *)fetchLastestRootPagePVRefer;

@end

/// MARK: AOP场景，基于原始 View 而生产的 `SPM Refer`
/// MARK: 目前仅针对各种 click 场景
@interface EventTracingEventReferQueue (UndefinedXpathEventRefer)
- (void)undefinedXpath_pushEventReferForEvent:(NSString *)event view:(UIView *)view;
- (EventTracingUndefinedXpathEventRefer * _Nullable)undefinedXpath_fetchLastestEventRefer;
- (EventTracingUndefinedXpathEventRefer * _Nullable)undefinedXpath_fetchLastestEventReferForEvent:(NSString *)event;
@end

/// MARK: hsrefer
@interface EventTracingEventReferQueue (Hsrefer)
- (NSString * _Nullable)hsrefer;
- (void)hsreferNeedsUpdateTo:(NSString *)hsrefer;
@end

NS_ASSUME_NONNULL_END
