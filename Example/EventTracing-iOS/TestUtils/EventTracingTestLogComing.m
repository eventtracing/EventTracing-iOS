//
//  EventTracingTestLogComing.m
//  EventTracing-iOS_Example
//
//  Created by dl on 2022/12/13.
//  Copyright © 2022 9446796. All rights reserved.
//

#import "EventTracingTestLogComing.h"
#import <objc/runtime.h>
#import <BlocksKit/NSObject+A2DynamicDelegate.h>

static NSHashTable<EventTracingTestLogComing *> *static_allTestLogComings;

static void EventTracingInitTestLogComingsIfNeeded(void) {
    if (!static_allTestLogComings) {
        static_allTestLogComings = [NSHashTable hashTableWithOptions:NSPointerFunctionsWeakMemory];
    }
}

NSArray<EventTracingTestLogComing *> *EventTracingAllTestLogComings(void) {
    EventTracingInitTestLogComingsIfNeeded();
    
    return static_allTestLogComings.allObjects;
}

EventTracingTestLogComing *EventTracingTestLogComingForKey(NSString *key) {
    return [EventTracingAllTestLogComings() bk_match:^BOOL(EventTracingTestLogComing *logComing) {
        return [logComing.key isEqualToString:key];
    }];
}

__attribute__((overloadable))
void EventTracingEnumateAllLogComings(void (NS_NOESCAPE ^block)(EventTracingTestLogComing *logComing, NSUInteger idx, BOOL *stop)) {
    [EventTracingAllTestLogComings() enumerateObjectsUsingBlock:block];
}

void EventTracingEnumateAllLogComings(SEL delegateSEL, void (NS_NOESCAPE ^block)(EventTracingTestLogComing *logComing, id delegate, NSUInteger idx, BOOL *stop)) {
    [EventTracingAllTestLogComings() enumerateObjectsUsingBlock:^(EventTracingTestLogComing * _Nonnull logComing, NSUInteger idx, BOOL * _Nonnull stop) {
        id delegate = [logComing bk_dynamicDelegateForProtocol:@protocol(EventTracingTestLogComingDelegate)];
        if ([delegate respondsToSelector:delegateSEL]) {
            block(logComing, delegate, idx, stop);
        }
    }];
}

NSString * EventTracingDescForEvent(NSString * event)
{
    static NSDictionary <NSString *, NSString *> * eventToDesc;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        eventToDesc = @{NE_ET_EVENT_ID_APP_ACTIVE:@"冷启动",
                        NE_ET_EVENT_ID_APP_IN:@"进入前台",
                        NE_ET_EVENT_ID_APP_OUT:@"进入后台",
                        NE_ET_EVENT_ID_P_VIEW:@"页面曝光",
                        NE_ET_EVENT_ID_P_VIEW_END:@"页面结束曝光",
                        NE_ET_EVENT_ID_E_VIEW:@"元素曝光",
                        NE_ET_EVENT_ID_E_VIEW_END:@"元素结束曝光",
                        NE_ET_EVENT_ID_E_CLCK:@"元素点击",
                        NE_ET_EVENT_ID_E_LONG_CLCK:@"元素长按",
                        NE_ET_EVENT_ID_E_SLIDE:@"列表滚动",
                        NE_ET_EVENT_ID_P_REFRESH:@"页面刷新"};
    });
    return eventToDesc[event] ?: event;
}

@interface EventTracingTestLogComing ()
@property(nonatomic, strong) NSMutableArray<NSDictionary *> *allJsonLogs;
@property(nonatomic, strong) NSMutableArray<NEEventTracingVTree *> *allVTrees;
@property(nonatomic, copy, readwrite) NSString *key;
@property(nonatomic, copy) NSMutableDictionary<NSString *, NSNumber *> *innerAlertActionClickCountMap;
@property(nonatomic, weak, readwrite) ETWebView *currentShowingWebView;
@end
@implementation EventTracingTestLogComing

- (instancetype)init {
    self = [super init];
    if (self) {
        _allJsonLogs = @[].mutableCopy;
        _allVTrees = @[].mutableCopy;
        _innerAlertActionClickCountMap = @{}.mutableCopy;
    }
    return self;
}

+ (instancetype)logComingWithKey:(NSString *)key {
    EventTracingInitTestLogComingsIfNeeded();
    
    EventTracingTestLogComing *logComing = [[EventTracingTestLogComing alloc] init];
    logComing.key = key;
    [static_allTestLogComings addObject:logComing];
    
    return logComing;
}

+ (instancetype)logComingWithRandomKey {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd hh:mm:ss"];
    [formatter setLocale:[NSLocale currentLocale]];
    
    NSString *timeString = [formatter stringFromDate:[NSDate date]];
    NSString *key = [NSString stringWithFormat:@"%@#%@#%u", @"Random", timeString, arc4random() % 1000];
    return [self logComingWithKey:key];
}

- (void)addLogJson:(NSDictionary *)logJson {
    [self.allJsonLogs addObject:logJson];
}

- (void)addVTree:(NEEventTracingVTree *)VTree {
    [self.allVTrees addObject:VTree];
}

- (void)alertController:(NSString *)pageId didClickActionWithElementId:(NSString *)elementId position:(NSUInteger)position {
    NSMutableString *spm = elementId.mutableCopy;
    if (position > 0) {
        [spm appendFormat:@":%ld", position];
    }
    if (pageId.length > 0) {
        [spm appendFormat:@"|%@", pageId];
    }
    NSInteger count = [self.innerAlertActionClickCountMap[spm] integerValue];
    count ++;
    self.innerAlertActionClickCountMap[spm] = @(count);
}

- (void)webViewDidShow:(ETWebView *)webView {
    _currentShowingWebView = webView;
}

- (NSArray<NSDictionary *> *)fetchJsonLogsForEvent:(NSString *)event spm:(NSString *)spm {
    return [self.logJsons bk_select:^BOOL(NSDictionary *logJson) {
        return [logJson[NE_ET_CONST_KEY_EVENT_CODE] isEqualToString:event] && [logJson[NE_ET_REFER_KEY_SPM] isEqualToString:spm];
    }];
}

- (NSArray<NSDictionary *> *)fetchJsonLogsForEvent:(NSString *)event spm:(NSString *)spm hasParaKey:(NSString *)paraKey isPage:(BOOL)isPage {
    return [self.logJsons bk_select:^BOOL(NSDictionary *logJson) {
        BOOL ret = [logJson[NE_ET_CONST_KEY_EVENT_CODE] isEqualToString:event] && [logJson[NE_ET_REFER_KEY_SPM] isEqualToString:spm];
        if (ret == NO) {
            return NO;
        }
        NSString * list_key = isPage ? NE_ET_CONST_KEY_PLIST : NE_ET_CONST_KEY_ELIST;
        NSArray<NSDictionary *> * list = logJson[list_key];
        __block BOOL hasPara = NO;
        [list enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj objectForKey:paraKey]) {
                hasPara = YES;
                *stop = YES;
            }
        }];
        return hasPara;
    }];
}

- (NSDictionary *)fetchLastJsonLogForEvent:(NSString *)event {
    return
    [self.logJsons.reverseObjectEnumerator.allObjects bk_match:^BOOL(NSDictionary *logJson) {
        return [logJson[NE_ET_CONST_KEY_EVENT_CODE] isEqualToString:event];
    }];
}

- (NSDictionary *)fetchLastJsonLogForEvent:(NSString *)event spm:(NSString *)spm {
    return
    [self.logJsons.reverseObjectEnumerator.allObjects bk_match:^BOOL(NSDictionary *logJson) {
        return [logJson[NE_ET_CONST_KEY_EVENT_CODE] isEqualToString:event] && [logJson[NE_ET_REFER_KEY_SPM] isEqualToString:spm];
    }];
}

- (NSDictionary *)fetchLastJsonLogForEvent:(NSString *)event oid:(NSString *)oid {
    return
    [self.logJsons.reverseObjectEnumerator.allObjects bk_match:^BOOL(NSDictionary *logJson) {
        if (![logJson[NE_ET_CONST_KEY_EVENT_CODE] isEqualToString:event]) {
            return NO;
        }
        NSString * c_oid = [[logJson[NE_ET_REFER_KEY_SPM] componentsSeparatedByString:@"|"] firstObject];
        return [c_oid isEqualToString:oid];
    }];
}

- (NSString *)fetchValueForEvent:(NSString *)event spm:(NSString *)spm key:(NSString *)key {
    NSDictionary * jsonLog = [self fetchLastJsonLogForEvent:event spm:spm];
    return jsonLog[key];
}

- (NSArray *)fetchMultirefersForEvent:(NSString *)event spm:(NSString *)spm {
    NSString * string = [self fetchValueForEvent:event spm:spm key:@"_multirefers"];
    return [NSJSONSerialization JSONObjectWithData:[string dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:nil];
}

- (NSDictionary *)fetchPageInfoForEvent:(NSString *)event spm:(NSString *)spm oid:(NSString *)oid {
    NSDictionary * jsonLog = [self fetchLastJsonLogForEvent:event spm:spm];
    NSArray<NSDictionary *> * plist = jsonLog[NE_ET_CONST_KEY_PLIST];
    __block NSDictionary * pageInfo;
    [plist.reverseObjectEnumerator.allObjects enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj[NE_ET_CONST_KEY_OID] isEqualToString:oid]) {
            pageInfo = obj;
            *stop = YES;
        }
    }];
    return pageInfo;
}

- (NSString *)fetchPageInfoValueForEvent:(NSString *)event spm:(NSString *)spm oid:(NSString *)oid key:(NSString *)key {
    NSDictionary * pageInfo = [self fetchPageInfoForEvent:event spm:spm oid:oid];
    return pageInfo[key];
}

- (NEEventTracingVTree *)lastVTree {
    return self.allVTrees.lastObject;
}

- (NSArray<NSDictionary *> *)logJsons {
    return self.allJsonLogs.copy;
}

- (NSArray<NEEventTracingVTree *> *)VTrees {
    return self.allVTrees.copy;
}

- (NSDictionary<NSString *,NSNumber *> *)alertActionClickCountMap {
    return self.innerAlertActionClickCountMap.copy;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"[LogComming]: %@", self.key];
}

@end


@implementation NEEventTracingVTree (UITest_LogComing)

- (void)setHasChangesToLastVTree:(BOOL)hasChangesToLastVTree {
    objc_setAssociatedObject(self, @selector(hasChangesToLastVTree), @(hasChangesToLastVTree), OBJC_ASSOCIATION_COPY_NONATOMIC);
}
- (BOOL)hasChangesToLastVTree {
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

@end
