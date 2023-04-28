//
//  NEEventTracingMultiReferPatch.m
//  NEEventTracing
//
//  Created by dl on 2022/12/6.
//

#import "NEEventTracingMultiReferPatch.h"
#import "NEEventTracingReferObserver.h"
#import "NEEventTracingOutputFormatter.h"
#import "NEEventTracingEngine+Private.h"

@interface NEEventTracingMultiReferPatch()<NEEventTracingReferObserver, NEEventTracingOutputParamsFilter>
@property(nonatomic, strong) NSMutableArray<NSString *> *multiRefersStack;
@end

@implementation NEEventTracingMultiReferPatch
- (instancetype)init {
    self = [super init];
    if (self) {
        _multiRefersStack = @[].mutableCopy;
    }
    return self;
}

+ (instancetype)sharedPatch {
    static NEEventTracingMultiReferPatch *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[NEEventTracingMultiReferPatch alloc] init];
    });
    return instance;
}

- (void)patchOnContextBuilder:(id<NEEventTracingContextBuilder>)builder {
    [builder addParamsFilter:self];
    [builder addReferObserver:self];
}

#pragma mark - NEEventTracingReferObserver
- (void)pgreferNeedsUpdatedTo:(NSString *)pgrefer
                      psrefer:(NSString *)psrefer
                         node:(NEEventTracingVTreeNode *)node
                      inVTree:(NEEventTracingVTree *)VTree
                       option:(NEETReferUpdateOption)option {
    if (psrefer.length == 0) {
        return;
    }

    if (option & NEETReferUpdateOptionPsreferMute) {
        // psrefer 静默，不添加到 multiRefersStack 中
        return;
    }
    
    NEEventTracingVTreeNode *rootPageNode = [VTree rootPageNode];
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
                                   node:(NEEventTracingVTreeNode * _Nullable)node
                                inVTree:(NEEventTracingVTree * _Nullable)VTree {
    NSString *eventListStr = [NEEventTracingEngine sharedInstance].ctx.extraConfigurationProvider.multiReferAppliedEventList;
    NSArray<NSString *> *events = [eventListStr componentsSeparatedByString:@","];
    if (!events.count) {
        events = @[NE_ET_EVENT_ID_E_CLCK, NE_ET_EVENT_ID_P_VIEW];
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
    NSInteger multiReferCount = [NEEventTracingEngine sharedInstance].ctx.extraConfigurationProvider.multiReferMaxItemCount;
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
