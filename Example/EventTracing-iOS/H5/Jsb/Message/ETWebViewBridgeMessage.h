//
//  ETWebViewBridgeMessage.h
//  EventTracing-iOS_Example
//
//  Created by dl on 2022/12/27.
//  Copyright © 2022 9446796. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ETWebViewBridgeMessage : NSObject

@property (nonatomic, copy, readonly) NSString *seq;                // 用于唯一确定一次请求
@property (nonatomic, copy, readonly) NSString *module;             // 模块名称
@property (nonatomic, copy, readonly) NSString *method;             // 调用的接口
@property (nonatomic, copy, readonly) NSDictionary *params;         // 调用的参数

+ (BOOL)isValidMessageObject:(id)message errorMessage:(NSString * _Nullable * _Nullable)errorMessage;

+ (instancetype)webViewBridgeMessageWithMessageObject:(NSDictionary *)messageObject;

@end

NS_ASSUME_NONNULL_END
