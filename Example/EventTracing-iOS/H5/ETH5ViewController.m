//
//  ETH5ViewController.m
//  EventTracing-iOS_Example
//
//  Created by dl on 2022/12/27.
//  Copyright © 2022 9446796. All rights reserved.
//

#import "ETH5ViewController.h"
#import "ETWebView.h"
#import "EventTracingTestLogComing.h"
#import "ETCommonDefines.h"
#import <EventTracing/NEEventTracingBuilder.h>

@interface ETH5ViewController ()
@property (nonatomic, strong) ETWebView *webView;
@end

@implementation ETH5ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.webView = [[ETWebView alloc] init];
    [self.view addSubview:self.webView];
    
    [self.webView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    
#ifdef H5_Demo_Use_Remote
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:H5_Demo_URL]];
    [self.webView loadRequest:urlRequest];
#else
    [self loadExamplePage:self.webView];
#endif
    
    [NEEventTracingBuilder viewController:self pageId:@"page_h5_biz"];
    
//    [self testBridgeFunc];
}

- (void) testBridgeFunc {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.webView execJsFunc:@"foo" inModule:@"module_in_js" params:@{
            @"tip": @"This is H5 Tip"
        } completionHandler:nil];

        [self.webView checkoutIfHasJsFunc:@"foo" inModule:@"module_in_js" completionHandler:^(id _Nullable result, NSError * _Nullable error) {
            NSLog(@"result: %@, error: %@", result, error);
        }];
    });
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [EventTracingAllTestLogComings() enumerateObjectsUsingBlock:^(EventTracingTestLogComing * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj webViewDidShow:self.webView];
    }];
}

- (void)loadExamplePage:(WKWebView*)webView {
    NSString* htmlPath = [[NSBundle mainBundle] pathForResource:@"h5" ofType:@"html"];
    NSString* appHtml = [NSString stringWithContentsOfFile:htmlPath encoding:NSUTF8StringEncoding error:nil];
    NSURL *baseURL = [NSURL fileURLWithPath:htmlPath];
    [webView loadHTMLString:appHtml baseURL:baseURL];
}

- (NSString *)tipText {
    return @""
    "1. 本 demo 中使用的 jsbridge 仅供参考\n"
    "  1.1 jsbridge 支持 js 调用oc方法，并且带 callback\n"
    "  1.2 jsbridge 支持主动调用一个 js 中注册的方法\n"
    "  1.3 js 中可以 checkout 判断native是否存在某个 bridge\n"
    "  1.4 native 可以判断 js 中是否注册了某个方法，可以供native调用\n"
    "";
}

@end
