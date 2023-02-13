//
//  NSError+ETWebViewBridge.m
//  EventTracing-iOS_Example
//
//  Created by dl on 2022/12/27.
//  Copyright © 2022 9446796. All rights reserved.
//

#import "NSError+ETWebViewBridge.h"

@implementation NSError (ETWebViewBridge)

+ (NSDictionary *)et_webkit_errorParamsWithMessage:(NSString *)message {
    return [self et_webkit_errorWithMessage:message ?: @"参数错误" code:ETWebViewBridgeCodeInvalidParams userInfo:nil];
}

+ (NSDictionary *)et_webkit_errorParamsWithMessage:(NSString *)message userInfo:(NSDictionary *)userInfo {
    return [self et_webkit_errorWithMessage:message code:ETWebViewBridgeCodeInvalidParams userInfo:userInfo];
}

+ (NSDictionary *)et_webkit_errorParamsWithCode:(NSUInteger)code message:(NSString *)message {
    return [self et_webkit_errorWithMessage:message code:code userInfo:nil];
}

+ (NSDictionary *)et_webkit_errorNotFound {
    return [self et_webkit_errorWithMessage:@"找不到该协议" code:ETWebViewBridgeCodeNotFound userInfo:nil];
}

+ (NSDictionary *)et_webkit_errorWithMessage:(NSString *)message code:(ETWebViewBridgeCode)code {
    return [self et_webkit_errorWithMessage:message code:code userInfo:nil];
}

+ (NSDictionary *)et_webkit_errorWithMessage:(NSString *)message code:(ETWebViewBridgeCode)code userInfo:(NSDictionary * __nullable)userInfo {
    NSMutableDictionary *dict = @{}.mutableCopy;
    dict[@"code"] = @(code);
    dict[@"domain"] = @"com.et.webkit";
    dict[@"message"] = message;
    dict[@"userInfo"] = userInfo;
    return dict.copy;
}

@end
