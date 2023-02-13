//
//  NEAppDelegate.m
//  EventTracing-iOS
//
//  Created by 9446796 on 11/29/2021.
//  Copyright (c) 2021 9446796. All rights reserved.
//

#import "NEAppDelegate.h"
#import <EventTracing/EventTracingMultiReferPatch.h>
#import <EventTracing/EventTracingReferNodeSCMDefaultFormatter.h>
#import "EventTracingTestLogComing.h"

@interface NEAppDelegate ()
<
EventTracingVTreeObserver,
EventTracingOutputPublicDynamicParamsProvider,
EventTracingEventOutputChannel,
EventTracingOutputParamsFilter,
EventTracingContextVTreePerformanceObserver,
EventTracingExtraConfigurationProvider,
EventTracingInternalLogOutputInterface,
EventTracingExceptionDelegate
>

@property(nonatomic, strong) EventTracingTestLogComing *globalLogComing;
@end


@implementation NEAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [[EventTracingEngine sharedInstance] startWithContextBuilder:^(id<EventTracingContextBuilder>  _Nonnull builder) {

        // 1. 静态公参
        [builder configStaticPublicParams:@{
            @"g_public_static_p_key": @"_public_static_p_value_test"
        }];
        
        // 2. 动态公参
        [builder registePublicDynamicParamsProvider:self];
        
        // 3. 注册日志输出格式; 默认SDK内部就是注册了 `EventTracingOutputFlattenFormatter`
        [builder registeFormatter:[[EventTracingOutputFlattenFormatter alloc] init]];
        // 3.1 默认SDK内部就是注册了 `EventTracingReferNodeSCMDefaultFormatter`
        [builder setupReferNodeSCMFormatter:[[EventTracingReferNodeSCMDefaultFormatter alloc] init]];
        
        // 4. output 输出
        [builder addOutputChannel:self];
        
        // 5. params filter
        [builder addParamsFilter:self];
        
        // 6. multi refer history
        [[EventTracingMultiReferPatch sharedPatch] patchOnContextBuilder:builder];
        
        // 7. 允许滚动中增量构建 VTree
        [[EventTracingEngine sharedInstance] enableIncrementalVTreeWhenScroll];
        
        // 7.1 滚动限流: 滚动模式下，增量构建VTree，配置 最小滑动间隔时长 && 最小滑动间隔距离
        // default: 0.05s && {5.f, 5.f}
        [builder configScrollThrottleTolerentDuration:0.05f tolerentOffset:CGPointMake(5.f, 5.f)];
        
        // 8. 元素节点，默认不打 曝光结束埋点
        builder.elementAutoImpressendEnable = NO;
        
        // 9. 一些额外配置 extra configuration
        builder.extraConfigurationProvider = self;
        
        // For Debug
#ifdef DEBUG
        {
            // 1. internal log
            builder.internalLogOutputInterface = self;
            
            // 2. config exception handler
            builder.exceptionInterface = self;
            
            // 3. add VTree observer
            [builder addVTreeObserver:self];
            
            // 4. VTree performance observer
            [builder setVTreePerformanceObserver:self];
            
            // 5. 检查 参数命名 等是否规范，也检查是否业务侧使用了内置的参数key
            builder.paramGuardEnable = YES;
            
            // 6. ViewController did load view
            builder.viewControllerDidNotLoadViewExceptionTip = ETViewControllerDidNotLoadViewExceptionTipCostom;
            // For Assert Scene
//            builder.viewControllerDidNotLoadViewExceptionTip = ETViewControllerDidNotLoadViewExceptionTipAssert;
            
            // 7. Refer format `_dkey` component
            [builder configReferFormatHasDKeyComponent:YES];
            
            // 8. For Debug Inspect Tools
            [builder addOutputChannel:[EventTracingInspectEngine sharedInstance]];
            
            // 9. 添加参数key黑名单，以下参数key不可以出现
            [EventTracingBuilder addBlackListParamKey:@"blacklist_param_key" errorString:@"该参数是黑名单，不应该出现在埋点中"];
        }
#endif
    }];
 
    self.globalLogComing = [EventTracingTestLogComing logComingWithKey:@"Global"];
//    [self _debug_enableLogViewer];
    
    return YES;
}

- (void)_debug_enableLogViewer {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[EventTracingInspectEngine sharedInstance] startInspect2D];
        
        // 在你的工程中，开启该 Debug 工具，一般来说不需要 `手动` 关闭
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
        [[EventTracingInspectEngine sharedInstance] performSelector:@selector(endInspectUI)];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [[EventTracingInspectEngine sharedInstance] performSelector:@selector(inspectWindowResignKeyWindow)];
        });
#pragma clang diagnostic pop
    });
}

#pragma mark - EventTracingExtraConfigurationProvider
- (NSArray<NSString *> *)needIncreaseActseqLogEvents {
    return @[ET_EVENT_ID_E_CLCK];
}

- (NSArray<NSString *> *)needStartHsreferOids {
    return @[@"page_tab_vc_1", @"page_tab_vc_2"];
}

#pragma mark - EventTracingOutputParamsFilter
- (NSDictionary *)filteredJsonWithEvent:(NSString *)event
                           originalJson:(NSDictionary *)originalJson
                                   node:(EventTracingVTreeNode *)node
                                inVTree:(EventTracingVTree *)VTree {
    if ([event isEqualToString:ET_EVENT_ID_E_CLCK]) {
        NSMutableDictionary *json = [originalJson mutableCopy];
        [json setObject:@"value_from_filter" forKey:@"key_from_filter"];
        return json.copy;
    }
    return originalJson;
}

#pragma mark - EventTracingOutputPublicDynamicParamsProvider
- (NSDictionary *)outputPublicDynamicParamsForEvent:(NSString *)event node:(EventTracingVTreeNode *)node inVTree:(EventTracingVTree *)VTree {
    EventTracingEnumateAllLogComings(^(EventTracingTestLogComing * _Nonnull logComing, NSUInteger idx, BOOL * _Nonnull stop) {
        logComing.publicDynamicParamsCallCount ++;
    });
    return @{
        @"g_dynamic_p_key": @"g_dynamic_p_value"
    };
}

#pragma mark - EventTracingVTreeObserver
- (void)didGenerateVTree:(EventTracingVTree *)VTree lastVTree:(EventTracingVTree * _Nullable)lastVTree hasChanges:(BOOL)hasChanges {
    /// MARK: For UI Tests
    EventTracingEnumateAllLogComings(^(EventTracingTestLogComing * _Nonnull logComing, NSUInteger idx, BOOL * _Nonnull stop) {
        VTree.hasChangesToLastVTree = hasChanges;
        [logComing addVTree:VTree];
    });
    
    if (!hasChanges) {
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSDictionary *debugJson = [VTree debugJson];
//        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:debugJson options:NSJSONWritingFragmentsAllowed error:nil];
//        NSString *jsonFormateString = [[NSString alloc]initWithData:jsonData encoding:NSUTF8StringEncoding];
        
//        NSLog(@"## ET ##, did Generate VTree StringFormat: %@", jsonFormateString);
        
        [self _doOutputToLogRealtimeViewer:@"ET_VTree" json:debugJson];
    });
}

#pragma mark - NEEventTracingInternalLogOutputInterface
- (void)logLevel:(ETLogLevel)level content:(NSString *)content {
    
}

#pragma mark - EventTracingEventOutputChannel
- (void)eventOutput:(EventTracingEventOutput *)eventOutput didOutputEvent:(NSString *)event json:(NSDictionary *)json {
    // 把 event 塞到日志里
    if ([json objectForKey:ET_CONST_KEY_EVENT_CODE] == nil && event) {
        NSMutableDictionary * mutable_json = [json mutableCopy];
        [mutable_json addEntriesFromDictionary:@{ET_CONST_KEY_EVENT_CODE:event}];
        json = [mutable_json copy];
    }
    
    [self _doOutputToLogRealtimeViewer:event json:json];

    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:json options:NSJSONWritingFragmentsAllowed error:nil];
    NSString *jsonFormateString = [[NSString alloc]initWithData:jsonData encoding:NSUTF8StringEncoding];
    NSLog(@"[ET Log] Output => event: %@, json: %@", event, jsonFormateString);
    
    /// MARK: For UI Tests
    [EventTracingAllTestLogComings() enumerateObjectsUsingBlock:^(EventTracingTestLogComing * _Nonnull logComing, NSUInteger idx, BOOL * _Nonnull stop) {
        [logComing addLogJson:json];
    }];
    
    SEL delegateSelector = @selector(_UI_Test_performDelegateOutputLogJsonsAtVTreeGenerateLevel);
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:delegateSelector object:nil];
    [self performSelector:delegateSelector withObject:nil afterDelay:0.01];
}

- (void)_UI_Test_performDelegateOutputLogJsonsAtVTreeGenerateLevel {
    EventTracingEnumateAllLogComings(@selector(logComing:didOutputLogJsons:atVTreeGenerateLevel:), ^(EventTracingTestLogComing * _Nonnull logComing, id  _Nonnull delegate, NSUInteger idx, BOOL * _Nonnull stop) {
        [delegate logComing:logComing didOutputLogJsons:logComing.logJsons atVTreeGenerateLevel:logComing.lastVTree];
    });
}

#pragma mark - EventTracingContextVTreePerformanceObserver
- (void)didGenerateVTree:(EventTracingVTree *)VTree
                     tag:(NSString *)tag
                     idx:(NSUInteger)idx
                    cost:(NSTimeInterval)cost
                     ave:(NSTimeInterval)ave
                     min:(NSTimeInterval)min
                     max:(NSTimeInterval)max {
    NSLog(@"## ET ## Times: %@, tag: %@, cost: %.4f, ave: %.4f, max: %.4f, min: %.4f", tag, @(idx).stringValue, cost, ave, max, min);
    
    [self _doOutputToLogRealtimeViewer:@"ET_performance" json:@{
        @"idx": @(idx).stringValue,
        @"cost": [NSString stringWithFormat:@"cost: %.4f", cost],
        @"ave": [NSString stringWithFormat:@"cost: %.4f", ave],
        @"min": [NSString stringWithFormat:@"cost: %.4f", min],
        @"max": [NSString stringWithFormat:@"cost: %.4f", max]
    }];
}

#pragma mark - EventTracingExceptionDelegate
- (void)paramGuardExceptionKey:(NSString *)key code:(NSInteger)code paramKey:(NSString *)paramKey regex:(NSString *)regex error:(NSError *)error {
    NSLog(@"# EventTracing # exception[ParamsGuard Error]: paramKey: %@, error: %@", paramKey, error);
    
    [self _doOutputExceptionToLogRealtimeViewerWithKey:key code:code content:@{
        @"value": paramKey ?: @"",
        @"regx": regex ?: @""
    }];
}
- (void)internalExceptionKey:(NSString *)key
                        code:(NSInteger)code
                     message:(NSString *)message
                        node:(EventTracingVTreeNode *)node
       shouldNotEqualToOther:(EventTracingVTreeNode *)otherNode {
    NSLog(@"# EventTracing # exception[NodeEqual Error]: code: %@, message: %@", @(code).stringValue, message);
    
    [self _doOutputExceptionToLogRealtimeViewerWithKey:key code:code content:@{
        @"isPage": @(node.isPageNode),
        @"spm": node.spm ?: @"",
        @"identifier": [node et_diffIdentifier]
    }];
}
- (void)internalExceptionKey:(NSString *)key
                        code:(NSInteger)code
                     message:(NSString *)message
                        node:(EventTracingVTreeNode *)node
    spmShouldNotEqualToOther:(EventTracingVTreeNode *)otherNode {
    [self _doOutputExceptionToLogRealtimeViewerWithKey:key code:code content:@{
        @"isPage": @(node.isPageNode),
        @"spm": node.spm ?: @""
    }];
}
- (void)logicalMountEndlessLoopExceptionKey:(NSString *)key
                                       code:(NSInteger)code
                                    message:(NSString *)message
                                       view:(UIView *)view
                                viewToMount:(UIView *)viewToMount {
    NSLog(@"# EventTracing # exception[LogicalMount Error]: code: %@, message: %@", @(code).stringValue, message);
    
    [self _doOutputExceptionToLogRealtimeViewerWithKey:key code:code content:@{
        @"autoMount": @(view.et_isAutoMountOnCurrentRootPageEnable).stringValue,
        @"isPage": @(view.et_isPage),
        @"oid": (view.et_isPage ? view.et_pageId : view.et_elementId) ?: @"",
        @"targetSpm": (viewToMount.et_currentVTreeNode.spm ?: @""),
        @"targetOid": ((viewToMount.et_pageId ? : viewToMount.et_elementId) ?: @"")
    }];
}

- (void)viewControllerDidNotLoadView:(UIViewController *)viewController message:(NSString *)message {
    //
}

#pragma mark - private methods
- (void) _doOutputToLogRealtimeViewer:(NSString *)action json:(NSDictionary *)json {
    [[EventTracingLogRealtimeViewer sharedInstance] sendLogWithAction:action json:json];
}

- (void) _doOutputExceptionToLogRealtimeViewerWithKey:(NSString *)key
                                                 code:(NSInteger)code
                                              content:(NSDictionary *)content {
    NSDictionary *json = @{
        @"key": key ?: @"",
        @"code": @(code),
        @"content": content ?: @{}
    };
    [[EventTracingLogRealtimeViewer sharedInstance] sendLogWithAction:@"exception" json:json];
    [[EventTracingInspectEngine sharedInstance] exceptionDidOccuredWithKey:key code:code content:content];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
