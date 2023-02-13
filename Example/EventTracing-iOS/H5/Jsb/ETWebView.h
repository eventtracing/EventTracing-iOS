//
//  ETWebView.h
//  EventTracing-iOS_Example
//
//  Created by dl on 2022/12/27.
//  Copyright © 2022 9446796. All rights reserved.
//

#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ETWebView : WKWebView <WKNavigationDelegate, WKUIDelegate>

- (void)unsafeEvaluateJavaScript:(NSString * _Nonnull)javaScriptString
               completionHandler:(void (^ _Nullable)(_Nullable id, NSError * _Nullable error))completionHandler;
- (void)evaluateJavaScript:(NSString * _Nonnull)javaScriptString;

- (void)execJsFunc:(NSString *)jsFunc
          inModule:(NSString * _Nullable)module
            params:(NSDictionary<NSString *, id> *)params
 completionHandler:(void (^ _Nullable)(_Nullable id, NSError * _Nullable error))completionHandler;

- (void)checkoutIfHasJsFunc:(NSString *)jsFunc
                   inModule:(NSString * _Nullable)module
          completionHandler:(void (^ _Nullable)(_Nullable id, NSError * _Nullable error))completionHandler;

@end

NS_ASSUME_NONNULL_END
