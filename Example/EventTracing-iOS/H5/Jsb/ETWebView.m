//
//  ETWebView.m
//  EventTracing-iOS_Example
//
//  Created by dl on 2022/12/27.
//  Copyright © 2022 9446796. All rights reserved.
//

#import "ETWebView.h"
#import "ETWebViewBridge.h"
#import "ETWebUtility.h"

static NSString * const ETWebViewBrigeCallJsFunc = @"__et_call_f_from_native";
static NSString * const ETWebViewBrigeCheckoutIfHasJsFunc = @"__et_has_js_method";

@interface ETWebView ()
@property (nonatomic, strong) ETWebViewBridge *bridge;
@end

@implementation ETWebView

- (instancetype)initWithFrame:(CGRect)frame configuration:(WKWebViewConfiguration *)configuration {
    self = [super initWithFrame:frame configuration:configuration];
    if (self) {
        //Add ne_et_js_is_wk 便于前端区分
        {
            WKUserScript *script = [[WKUserScript alloc] initWithSource:@"var ne_et_js_is_wk = true;" injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:NO];
            [self.configuration.userContentController addUserScript:script];
        }
        
        {
            NSString* injectJsPath = [[NSBundle mainBundle] pathForResource:@"inject" ofType:@"js"];
            NSString* injectJsContent = [NSString stringWithContentsOfFile:injectJsPath encoding:NSUTF8StringEncoding error:nil];
            WKUserScript *script = [[WKUserScript alloc] initWithSource:injectJsContent injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:NO];
            [self.configuration.userContentController addUserScript:script];
        }
        
        {
            NSString* smulateClickJsPath = [[NSBundle mainBundle] pathForResource:@"smulate_click" ofType:@"js"];
            NSString* smulateClickJsContent = [NSString stringWithContentsOfFile:smulateClickJsPath encoding:NSUTF8StringEncoding error:nil];
            WKUserScript *script = [[WKUserScript alloc] initWithSource:smulateClickJsContent injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:NO];
            [self.configuration.userContentController addUserScript:script];
        }
        
        self.navigationDelegate = self;
        self.UIDelegate = self;
        self.backgroundColor = [UIColor clearColor];
        self.opaque = NO;
        
        _bridge = [[ETWebViewBridge alloc]initWithWebView:self];
        [_bridge buildBridgeWithUserContentController:self.configuration.userContentController];
    }
    return self;
}

- (void)dealloc {
    [self.bridge clearBridgeWithUserContentController:self.configuration.userContentController];
}

- (void)unsafeEvaluateJavaScript:(NSString *)javaScriptString completionHandler:(void (^)(id _Nullable, NSError * _Nullable))completionHandler {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self evaluateJavaScript:javaScriptString completionHandler:completionHandler];
    });
}

- (void)evaluateJavaScript:(NSString *)javaScriptString {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self evaluateJavaScript:javaScriptString completionHandler:nil];
    });
}

- (void)execJsFunc:(NSString *)jsFunc
          inModule:(NSString *)module
            params:(NSDictionary<NSString *, id> *)params
 completionHandler:(void (^)(id _Nullable, NSError * _Nullable))completionHandler {
    NSArray *args = @[
        module ?: @"", jsFunc ?: @"", params ?: @{}
    ];
    NSString *script = [ETWebUtility scriptWithJSFunc:ETWebViewBrigeCallJsFunc withArgs:args];
    [self unsafeEvaluateJavaScript:script completionHandler:completionHandler];
}

- (void)checkoutIfHasJsFunc:(NSString *)jsFunc inModule:(NSString * _Nullable)module completionHandler:(void (^ _Nullable)(id _Nullable, NSError * _Nullable))completionHandler {
    NSArray *args = @[
        module ?: @"", jsFunc ?: @""
    ];
    NSString *script = [ETWebUtility scriptWithJSFunc:ETWebViewBrigeCheckoutIfHasJsFunc withArgs:args];
    [self unsafeEvaluateJavaScript:script completionHandler:completionHandler];
}

#pragma mark - WKUIDelegate alert

- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler {
    NSString *hostString = [self alertTitleWithURL:webView.URL];
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:hostString message:message preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"关闭" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        completionHandler();
    }]];
    UIViewController * rootVc = [UIApplication sharedApplication].delegate.window.rootViewController;
    if (rootVc.isViewLoaded &&
        rootVc.view.window &&
        rootVc.presentedViewController == nil) {
        [rootVc presentViewController:alertController animated:YES completion:nil];
    } else {
        completionHandler();
    }
}

- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL))completionHandler {
    
    NSString *hostString = [self alertTitleWithURL:webView.URL];
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:hostString message:message preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"好的" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        completionHandler(YES);
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        completionHandler(NO);
    }]];
    
    UIViewController * rootVc = [UIApplication sharedApplication].delegate.window.rootViewController;
    if (rootVc.isViewLoaded &&
        rootVc.view.window &&
        rootVc.presentedViewController == nil) {
        [rootVc presentViewController:alertController animated:YES completion:nil];
    } else {
        completionHandler(NO);
    }
}

- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * _Nullable))completionHandler {
    
    NSString *hostString = [self alertTitleWithURL:webView.URL];
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:hostString message:prompt preferredStyle:UIAlertControllerStyleAlert];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.text = defaultText;
    }];
    [alertController addAction:[UIAlertAction actionWithTitle:@"好" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSString *input = ((UITextField *)alertController.textFields.firstObject).text;
        completionHandler(input);
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        completionHandler(nil);
    }]];
    
    UIViewController * rootVc = [UIApplication sharedApplication].delegate.window.rootViewController;
    if (rootVc.isViewLoaded &&
        rootVc.view.window &&
        rootVc.presentedViewController == nil) {
        [rootVc presentViewController:alertController animated:YES completion:nil];
    } else {
        completionHandler(nil);
    }
}

- (NSString *)alertTitleWithURL:(NSURL *)URL {
    return [NSString stringWithFormat:@"%@://%@", URL.scheme, URL.host];
}

@end
