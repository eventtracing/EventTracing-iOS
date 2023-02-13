//
//  ETWebViewBridgeMessage.m
//  EventTracing-iOS_Example
//
//  Created by dl on 2022/12/27.
//  Copyright © 2022 9446796. All rights reserved.
//

#import "ETWebViewBridgeMessage.h"

@interface ETWebViewBridgeMessage ()

@property (nonatomic, copy, readwrite) NSString *seq;
@property (nonatomic, copy, readwrite) NSString *module;
@property (nonatomic, copy, readwrite) NSString *method;
@property (nonatomic, copy, readwrite) NSDictionary *params;

@end

@implementation ETWebViewBridgeMessage

+ (BOOL)isValidMessageObject:(id)message errorMessage:(NSString *__autoreleasing *)errorMessage {

    if (! [message isKindOfClass:[NSDictionary class]]) {
        return NO;
    }
    
    // seq 用于唯一确定一次请求 回调的时候需要带回去
    NSString *seq = [message objectForKey:@"seq"];
    if (![seq isKindOfClass:NSString.class] || seq.length == 0) {
        *errorMessage = @"seq 不能为空";
        return NO;
    }
    
    // method 表示需要调用的什么服务
    NSString *method = [message objectForKey:@"method"];
    if (![method isKindOfClass:NSString.class] || method.length == 0) {
        *errorMessage = @"method 不能为空";
        return NO;
    }
    
    // params 表示调用服务时传递过来的参数
    NSDictionary *params = [message objectForKey:@"params"];
    if (![params isKindOfClass:NSDictionary.class]) {
        *errorMessage = @"params 只能为字典";
        return NO;
    }
    
    return YES;
}

+ (instancetype)webViewBridgeMessageWithMessageObject:(NSDictionary *)messageObject {
    ETWebViewBridgeMessage *webViewBridgeMessage = [ETWebViewBridgeMessage new];
    
    webViewBridgeMessage.seq = [messageObject objectForKey:@"seq"];
    webViewBridgeMessage.module = [messageObject objectForKey:@"module"];
    webViewBridgeMessage.method = [messageObject objectForKey:@"method"];
    webViewBridgeMessage.params = [messageObject objectForKey:@"params"];
    
    return webViewBridgeMessage;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"seq: %@\n class: %@\n method: %@\n params: %@\n", _seq, _module, _method, _params];
}

@end
