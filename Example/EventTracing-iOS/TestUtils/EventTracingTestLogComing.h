//
//  EventTracingTestLogComing.h
//  EventTracing-iOS_Example
//
//  Created by dl on 2022/12/13.
//  Copyright © 2022 9446796. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <EventTracing/EventTracing.h>
#import "ETWebView.h"

NS_ASSUME_NONNULL_BEGIN

@interface EventTracingVTree (UITest_LogComing)
@property(nonatomic, assign) BOOL hasChangesToLastVTree;
@end

@class EventTracingTestLogComing;
FOUNDATION_EXTERN NSArray<EventTracingTestLogComing *> *EventTracingAllTestLogComings(void);
FOUNDATION_EXTERN EventTracingTestLogComing *EventTracingTestLogComingForKey(NSString *key);
__attribute__((overloadable))
FOUNDATION_EXTERN void EventTracingEnumateAllLogComings(void (NS_NOESCAPE ^block)(EventTracingTestLogComing *logComing, NSUInteger idx, BOOL *stop));
FOUNDATION_EXTERN void EventTracingEnumateAllLogComings(SEL delegateSEL, void (NS_NOESCAPE ^block)(EventTracingTestLogComing *logComing, id delegate, NSUInteger idx, BOOL *stop));

FOUNDATION_EXTERN NSString * EventTracingDescForEvent(NSString * event);

@protocol EventTracingTestLogComingDelegate <NSObject>
/// MARK: 生成一次 VTree 并产生日志 级别，回调一次
@optional
- (void)logComing:(EventTracingTestLogComing *)logComing
didOutputLogJsons:(NSArray<NSDictionary *> *)logJsons
atVTreeGenerateLevel:(EventTracingVTree *)VTree;
@end

@interface EventTracingTestLogComing : NSObject

@property(nonatomic, copy, readonly) NSString *key;
@property(nonatomic, strong, readonly) NSArray<NSDictionary *> *logJsons;
@property(nonatomic, strong, readonly) NSArray<EventTracingVTree *> *VTrees;
@property(nonatomic, strong, readonly) EventTracingVTree *lastVTree;

@property(nonatomic, weak) id<EventTracingTestLogComingDelegate> delegate;

/// MARK: Alert
@property(nonatomic, copy, readonly) NSDictionary<NSString *, NSNumber *> *alertActionClickCountMap;

/// MARK: current showing H5
@property(nonatomic, weak, readonly) ETWebView *currentShowingWebView;

// ### 公参 ###
@property(nonatomic, assign) NSInteger publicDynamicParamsCallCount;

+ (instancetype)logComingWithKey:(NSString *)key;
+ (instancetype)logComingWithRandomKey;

- (void)addLogJson:(NSDictionary *)logJson;
- (void)addVTree:(EventTracingVTree *)VTree;

- (void)alertController:(NSString *)pageId didClickActionWithElementId:(NSString *)elementId position:(NSUInteger)position;
- (void)webViewDidShow:(ETWebView *)webView;

- (NSArray<NSDictionary *> *)fetchJsonLogsForEvent:(NSString *)event spm:(NSString *)spm;
- (NSArray<NSDictionary *> *)fetchJsonLogsForEvent:(NSString *)event spm:(NSString *)spm hasParaKey:(NSString *)paraKey isPage:(BOOL)isPage;
- (NSDictionary *)fetchLastJsonLogForEvent:(NSString *)event spm:(NSString *)spm;
- (NSDictionary *)fetchLastJsonLogForEvent:(NSString *)event oid:(NSString *)oid;

- (NSDictionary *)fetchLastJsonLogForEvent:(NSString *)event;

- (NSString *)fetchValueForEvent:(NSString *)event spm:(NSString *)spm key:(NSString *)key;
- (NSArray *)fetchMultirefersForEvent:(NSString *)event spm:(NSString *)spm;
- (NSDictionary *)fetchPageInfoForEvent:(NSString *)event spm:(NSString *)spm oid:(NSString *)oid;
- (NSString *)fetchPageInfoValueForEvent:(NSString *)event spm:(NSString *)spm oid:(NSString *)oid key:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
