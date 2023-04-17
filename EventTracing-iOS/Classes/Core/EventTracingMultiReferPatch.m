//
//  EventTracingMultiReferPatch.m
//  EventTracing
//
//  Created by dl on 2022/12/6.
//

#import "EventTracingMultiReferPatch.h"
#import "EventTracingReferObserver.h"
#import "EventTracingOutputFormatter.h"
#import "EventTracingEngine+Private.h"

@interface EventTracingMultiReferPatch()<EventTracingReferObserver, EventTracingOutputParamsFilter>
@property(nonatomic, strong) NSMutableArray<NSString *> *multiRefersStack;
@end

@implementation EventTracingMultiReferPatch
- (instancetype)init {
    self = [super init];
    if (self) {
        _multiRefersStack = @[].mutableCopy;
    }
    return self;
}

+ (instancetype)sharedPatch {
    static EventTracingMultiReferPatch *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[EventTracingMultiReferPatch alloc] init];
    });
    return instance;
}

- (void)patchOnContextBuilder:(id<EventTracingContextBuilder>)builder {
    [builder addParamsFilter:self];
    [builder addReferObserver:self];
}

#pragma mark - EventTracingReferObserver
- (void)pgreferNeedsUpdatedTo:(NSString *)pgrefer
                      psrefer:(NSString *)psrefer
                         node:(EventTracingVTreeNode *)node
                      inVTree:(EventTracingVTree *)VTree
                       option:(ETReferUpdateOption)option {
    if (psrefer.length == 0) {
        return;
    }

    if (option & ETReferUpdateOptionPsreferMute) {
        // psrefer 静默，不添加到 multiRefersStack 中
        return;
    }
    
    EventTracingVTreeNode *rootPageNode = [VTree rootPageNode];
    BOOL isRootPagePV = rootPageNode == node;
    if (!isRootPagePV) {
        // 非根节点曝光，不参与 multirefers
        return;
    }
    NSInteger location = [self.multiRefersStack indexOfObject:psrefer];

    // 出栈
    if (location != NSNotFound) {
        [self.multiRefersStack removeObjectsInRange:NSMakeRange(0, location)];
    }
    // 进栈
    else {
        [self.multiRefersStack insertObject:psrefer atIndex:0];
    }
}

- (NSDictionary *)filteredJsonWithEvent:(NSString *)event
                           originalJson:(NSDictionary *)originalJson
                                   node:(EventTracingVTreeNode * _Nullable)node
                                inVTree:(EventTracingVTree * _Nullable)VTree {
    NSString *eventListStr = [EventTracingEngine sharedInstance].ctx.eventTracingReferEventList;
    NSArray<NSString *> *events = [eventListStr componentsSeparatedByString:@","];
    if (!events.count) {
        events = @[ET_EVENT_ID_E_CLCK, ET_EVENT_ID_P_VIEW];
    }
    // MARK: 业务侧参数优先级更高，不覆盖
    if ([events containsObject:event] && ![originalJson.allKeys containsObject:@"_multirefers"]) {
        NSMutableDictionary *json = originalJson.mutableCopy;
        [json setObject:([self multiRefersJsonString] ?: @"") forKey:@"_multirefers"];
        
        return json.copy;
    }
    return originalJson;
}

- (NSArray<NSString *> *)multiRefers {
    NSInteger multiReferCount = [EventTracingEngine sharedInstance].ctx.eventTracingPsReferNum;
    NSArray<NSString *> *refers = self.multiRefersStack;
    if (refers.count > multiReferCount) {
        refers = [refers subarrayWithRange:NSMakeRange(0, multiReferCount)];
    }
    
    return refers.copy;
}

- (NSString *)multiRefersJsonString {
    NSError * err;
    NSData * jsonData = [NSJSONSerialization  dataWithJSONObject:self.multiRefers options:0 error:&err];
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

@end
