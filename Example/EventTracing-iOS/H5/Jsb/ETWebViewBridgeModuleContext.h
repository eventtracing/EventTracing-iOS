//
//  ETWebViewBridgeModuleContext.h
//  EventTracing-iOS_Example
//
//  Created by dl on 2022/12/27.
//  Copyright © 2022 9446796. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class ETWebView;

@class ETWebViewBridge;
@protocol ETWebViewBridgeCallContextProtocol <NSObject>

@property (nonatomic, copy, readonly) NSString *seq;                                  // call seq
@property (nonatomic, copy, readonly) NSString *method;                               // 请求名
@property (nonatomic, copy, readonly) NSDictionary *params;                           // 请求的参数

@property (nonatomic, weak, readonly) ETWebViewBridge *bridge;

@end

NS_ASSUME_NONNULL_END
