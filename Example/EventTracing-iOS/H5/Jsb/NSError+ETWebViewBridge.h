//
//  NSError+ETWebViewBridge.h
//  EventTracing-iOS_Example
//
//  Created by dl on 2022/12/27.
//  Copyright © 2022 9446796. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, ETWebViewBridgeCode) {
    ETWebViewBridgeCodeSuccess  = 200,
    
    ETWebViewBridgeCodeInvalidParams = 400,
    ETWebViewBridgeCodeNotFound = 404,
};

@interface NSError (ETWebViewBridge)

+ (NSDictionary *)et_webkit_errorNotFound;
+ (NSDictionary *)et_webkit_errorParamsWithCode:(NSUInteger)code message:(NSString * __nullable)message;
+ (NSDictionary *)et_webkit_errorParamsWithMessage:(NSString * __nullable)message;
+ (NSDictionary *)et_webkit_errorParamsWithMessage:(NSString *)message userInfo:(NSDictionary * __nullable)userInfo;

+ (NSDictionary *)et_webkit_errorWithMessage:(NSString *)message code:(ETWebViewBridgeCode)code;
+ (NSDictionary *)et_webkit_errorWithMessage:(NSString *)message code:(ETWebViewBridgeCode)code userInfo:(NSDictionary * __nullable)userInfo;

@end

NS_ASSUME_NONNULL_END
