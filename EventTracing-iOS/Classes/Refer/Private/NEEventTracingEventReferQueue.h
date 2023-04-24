//
//  NEEventTracingEventReferQueue.h
//  NEEventTracing
//
//  Created by dl on 2021/4/1.
//

#import <Foundation/Foundation.h>
#import "NEEventTracingEventRefer+Private.h"

NS_ASSUME_NONNULL_BEGIN

@interface NEEventTracingEventReferQueue : NSObject

@property(nonatomic, strong, readonly) NSArray<NEEventTracingFormattedEventRefer *> *allRefers;

+ (instancetype)queue;

- (void)pushEventRefer:(NEEventTracingFormattedEventRefer *)refer;
- (void)pushEventRefer:(NEEventTracingFormattedEventRefer *)refer
                  node:(NEEventTracingVTreeNode * _Nullable)node
             isSubPage:(BOOL)isSubPage;
- (void)removeEventRefer:(NEEventTracingFormattedEventRefer *)refer;
- (void)clear;

@end

/// MARK: AOP pre 时机，将 event refer 放入队列，供业务方在 event handler 内部即可获取refer
/// MARK: 内部会 actseq 做 `预+1` 操作
@interface NEEventTracingEventReferQueue (EventRefer)

- (BOOL)pushEventReferForEvent:(NSString *)event
                          view:(UIView *)view
                          node:(NEEventTracingVTreeNode * _Nullable)node
                   useForRefer:(BOOL)useForRefer
                 useNextActseq:(BOOL)useNextActseq;

- (void)rootPageNodeDidImpress:(NEEventTracingVTreeNode * _Nullable)node
                       inVTree:(NEEventTracingVTree * _Nullable)VTree;

- (void)subPageNodeDidImpress:(NEEventTracingVTreeNode * _Nullable)node
                      inVTree:(NEEventTracingVTree * _Nullable)VTree;

- (NEEventTracingFormattedEventRefer *)fetchLastestRootPagePVRefer;

@end

/// MARK: AOP场景，基于原始 View 而生产的 `SPM Refer`
/// MARK: 目前仅针对各种 click 场景
@interface NEEventTracingEventReferQueue (UndefinedXpathEventRefer)
- (void)undefinedXpath_pushEventReferForEvent:(NSString *)event view:(UIView *)view;
- (NEEventTracingUndefinedXpathEventRefer * _Nullable)undefinedXpath_fetchLastestEventRefer;
- (NEEventTracingUndefinedXpathEventRefer * _Nullable)undefinedXpath_fetchLastestEventReferForEvent:(NSString *)event;
@end

/// MARK: hsrefer
@interface NEEventTracingEventReferQueue (Hsrefer)
- (NSString * _Nullable)hsrefer;
- (void)hsreferNeedsUpdateTo:(NSString *)hsrefer;
@end

NS_ASSUME_NONNULL_END
