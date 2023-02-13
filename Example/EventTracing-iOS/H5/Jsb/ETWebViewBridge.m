//
//  ETWebViewBridge.m
//  EventTracing-iOS_Example
//
//  Created by dl on 2022/12/27.
//  Copyright © 2022 9446796. All rights reserved.
//

#import "ETWebViewBridge.h"
#import "ETWebView.h"
#import "ETWebViewBridgeMessage.h"
#import "NSError+ETWebViewBridge.h"
#import "ETWebUtility.h"
#import "ETWebViewBridgeManager.h"
#import "NSError+ETWebViewBridge.h"
#import "ETWebViewBridgeModuleContext.h"

static NSString * const ETWebViewBrigeName = @"et_js_wk_bridge";      // 在 JSContext 中对应的对象名称
static NSString * const ETWebViewBrigeCallback = @"__et_call_cb_from_native";    // 固定的回调地址
static NSString * const ETWebViewBrigeAvaiable = @"__et_jsb_avaiable";    // 固定的回调地址

@interface ETWebViewBridgeContext : NSObject <ETWebViewBridgeContextProtocol>
+ (instancetype)contextWithWebView:(ETWebView *)webView;
@end

@interface ETWebViewBridgeCallContext : NSObject <ETWebViewBridgeCallContextProtocol>
+ (instancetype)contextWithSeq:(NSString *)seq
                        method:(NSString *)method
                        params:(NSDictionary * __nullable)params
                        bridge:(ETWebViewBridge *)bridge;
@end

@interface ETWebViewBridge ()
@property (nonatomic, strong, readwrite) id<ETWebViewBridgeContextProtocol> context;
@property (nonatomic, getter=isDestoryed) BOOL destoryed;

@property (nonatomic) NSMutableDictionary<NSString *, id<ETWebViewBridgeModuleProtocol>> *moduleInstances;

- (void)handlePostMessage:(ETWebViewBridgeMessage *)message;
- (id<ETWebViewBridgeModuleProtocol>)bridgeModuleWithModuleName:(NSString *)moduleName;
@end

@implementation ETWebViewBridge

- (instancetype)initWithWebView:(ETWebView *)webView {
    if (self = [super init]) {
        _context = [ETWebViewBridgeContext contextWithWebView:webView];
        _moduleInstances = @{}.mutableCopy;
    }
    return self;
}

- (void)buildBridgeWithUserContentController:(WKUserContentController *)userContentController {
    [userContentController addScriptMessageHandler:self name:ETWebViewBrigeName];
}

- (void)clearBridgeWithUserContentController:(WKUserContentController *)userContentController {
    [userContentController removeScriptMessageHandlerForName:ETWebViewBrigeName];
}

#pragma mark - ETWebViewJSBridgeProtocol
- (void)postMessage:(NSDictionary *)message {
    if (self.isDestoryed) {
        return;
    }
    
    NSString *seq = [message objectForKey:@"seq"];
    NSString *module = [message objectForKey:@"module"];
    NSString *method = [message objectForKey:@"method"];
    NSString *errorMessage = nil;
    if (! [ETWebViewBridgeMessage isValidMessageObject:message errorMessage:&errorMessage]) {
        [self callbackWithSeq:seq error:[NSError et_webkit_errorParamsWithMessage:errorMessage] result:nil module:module method:method];
        return;
    }
    
    ETWebViewBridgeMessage *bridgeMessage = [ETWebViewBridgeMessage webViewBridgeMessageWithMessageObject:message];
    [self handlePostMessage:bridgeMessage];
}

- (void)handlePostMessage:(ETWebViewBridgeMessage *)message {
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self handlePostMessageOnMainThread:message];
        });
    }
    else {
        [self handlePostMessageOnMainThread:message];
    }
}

- (id<ETWebViewBridgeModuleProtocol>)bridgeModuleWithModuleName:(NSString *)moduleName {
    ETWebViewBridgeModule *module = [self.moduleInstances objectForKey:moduleName];
    
    if (![self.moduleInstances.allKeys containsObject:moduleName]) {
        Class moduleClass = [[ETWebViewBridgeManager sharedInstance] moduleClassForModuleName:moduleName];
        NSAssert(moduleClass != NULL, @"moduleClass shoud not be NULL");
        NSAssert([moduleClass isSubclassOfClass:ETWebViewBridgeModule.class], @"moduleClass should inherit from `ETWebViewBridgeModule`");
        
        module = [moduleClass new];
        [module setValue:self forKey:NSStringFromSelector(@selector(bridge))];
        [self.moduleInstances setValue:module forKey:module.moduleName];
    }
    
    return module;
}

- (void)handlePostMessageOnMainThread:(ETWebViewBridgeMessage *)message {
    id<ETWebViewBridgeModuleProtocol> module = [self bridgeModuleWithModuleName:message.module];
    
    if (! module) {
        [self callbackWithSeq:message.seq error:[NSError et_webkit_errorNotFound] result:nil module:message.module method:message.method];
        return;
    }
    
    ETWebViewBridgeCallContext *context = [ETWebViewBridgeCallContext contextWithSeq:message.seq
                                                                              method:message.method
                                                                              params:message.params
                                                                              bridge:self];
    
    // 动态构造 sel
    SEL handleSel = NSSelectorFromString([NSString stringWithFormat:@"%@DidCallWithContext:callback:", message.method]);
    if (! [module respondsToSelector:handleSel]) {
        [self callbackWithSeq:message.seq error:[NSError et_webkit_errorNotFound] result:nil module:message.module method:message.method];
        return;
    }
    
    // handler 的回调
    @weakify(self);
    void (^completionHandler)(NSDictionary *result, NSDictionary *error) = ^(NSDictionary * result, NSDictionary * error) {
        @strongify(self)
        [self callbackWithSeq:message.seq error:error result:result module:message.module method:message.method];
    };
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [module performSelector:handleSel withObject:context withObject:completionHandler];
#pragma clang diagnostic pop
}

#pragma mark - WKScriptMessageHandler
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    if (![message.name isEqualToString:ETWebViewBrigeName]) {
        return;
    }
    
    [self postMessage:message.body];
}

#pragma mark - callback
- (void)callbackWithSeq:(NSString *)seq
                  error:(NSDictionary *)error
                 result:(NSDictionary *)result
                 module:(NSString *)module
                 method:(NSString *)method {
    NSNull *nullVal = [NSNull null];
    NSArray *args = @[
        seq ?: @"",
        error ?: nullVal,
        result ?: nullVal,
        @{
            @"module": module ?: nullVal,
            @"method": method ?: nullVal
        }
    ];
    NSString *script = [ETWebUtility scriptWithJSFunc:ETWebViewBrigeCallback withArgs:args];
    script = [NSString stringWithFormat:@"window.%@ !== 'undefined'&&%@", ETWebViewBrigeCallback, script];
    [self.context.webView evaluateJavaScript:script];
}

@end

@implementation ETWebViewBridgeContext
@synthesize webView = _webView;
@synthesize viewController = _viewController;

+ (instancetype)contextWithWebView:(ETWebView *)webView {
    ETWebViewBridgeContext *context = [self new];
    context->_webView = webView;
    return context;
}

- (UIViewController *)viewController {
    if (! _viewController) {
        _viewController = [self queryViewController];
    }
    return _viewController;
}

- (UIViewController *)queryViewController {
    if (! self.webView) {
        return nil;
    }
    
    UIViewController *viewController = nil;
    UIResponder *nextResponder = self.webView;
    while (nextResponder) {
        if ([nextResponder isKindOfClass:[UIViewController class]]) {
            viewController = (UIViewController *)nextResponder;
            break;
        }
        nextResponder = nextResponder.nextResponder;
    }
    return viewController;
}

@end

@implementation ETWebViewBridgeCallContext
@synthesize seq = _seq;
@synthesize method = _method;
@synthesize params = _params;
@synthesize bridge = _bridge;

+ (instancetype)contextWithSeq:(NSString *)seq
                        method:(NSString *)method
                        params:(NSDictionary * __nullable)params
                        bridge:(ETWebViewBridge *)bridge {
    ETWebViewBridgeCallContext *context = [self new];
    context->_seq = seq;
    context->_method = method;
    context->_params = params ?: @{};
    context->_bridge = bridge;
    return context;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"seq: %@, method: %@ params: %@", _seq, _method, _params];
}

@end
