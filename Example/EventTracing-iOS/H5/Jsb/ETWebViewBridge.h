//
//  ETWebViewBridge.h
//  EventTracing-iOS_Example
//
//  Created by dl on 2022/12/27.
//  Copyright © 2022 9446796. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@class ETWebView;

@protocol ETWebViewJSBridgeProtocol <JSExport>
- (void)postMessage:(NSDictionary *)message;
@end

@protocol ETWebViewBridgeContextProtocol <NSObject>
@property (nonatomic, weak, readonly) ETWebView *webView;                             // 当前的 webView 对象
@property (nonatomic, weak, nullable, readonly) UIViewController *viewController;     // 当前的控制器
@end

@interface ETWebViewBridge : NSObject <ETWebViewJSBridgeProtocol, WKScriptMessageHandler>

@property(nonatomic, strong, readonly) id<ETWebViewBridgeContextProtocol> context;

- (instancetype)initWithWebView:(ETWebView *)webView;

- (void)buildBridgeWithUserContentController:(WKUserContentController *)userContentController;
- (void)clearBridgeWithUserContentController:(WKUserContentController *)userContentController;

@end

NS_ASSUME_NONNULL_END
