//
//  ETWebViewBridgeManager.h
//  EventTracing-iOS_Example
//
//  Created by dl on 2022/12/27.
//  Copyright © 2022 9446796. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ETWebViewBridgeModuleContext.h"
#import "NSError+ETWebViewBridge.h"
#import "ETWebView.h"
#import "ETWebViewBridge.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^ETWebViewBridgeCallBack)(NSDictionary * _Nullable result, NSDictionary * _Nullable error);

#define ETWEB_BRIDGE_STRINGIFY(S) #S
#define ETWEBKIT_BRIDGE_MODULE_EXPORT(NAME) \
+ (void)load { \
    [[ETWebViewBridgeManager sharedInstance] registModule:self forModuleName:@ETWEB_BRIDGE_STRINGIFY(NAME)]; \
} \
- (NSString *)moduleName {\
    return @ETWEB_BRIDGE_STRINGIFY(NAME); \
}\

#define ETWEBKIT_BRIDGE_MODULE_METHDO_EXPORT(methodName) \
- (void)\
methodName ## DidCallWithContext:(id<ETWebViewBridgeCallContextProtocol>)context callback:(ETWebViewBridgeCallBack)callback

@protocol ETWebViewBridgeModuleProtocol <NSObject>
@property(nonatomic, weak, readonly) ETWebViewBridge *bridge;

- (NSString *)moduleName;
@end

@interface ETWebViewBridgeModule : NSObject<ETWebViewBridgeModuleProtocol>
@end

@protocol ETWebViewBridgeManagerProtocol <NSObject>

/// 注册一个可以处理该协议的模块
/// @param moduleClass 模块
/// @param moduleName 协议名称
- (void)registModule:(Class)moduleClass forModuleName:(NSString *)moduleName;

/// 根据 moduleName 找到对应可以处理的类
/// @param moduleName 模块名称
/// @return 可以处理改协议的类
- (Class __nullable)moduleClassForModuleName:(NSString *)moduleName;

@end

@interface ETWebViewBridgeManager : NSObject <ETWebViewBridgeManagerProtocol>
+ (instancetype)sharedInstance;
@end

@interface ETWebViewBridgeManager (Debug)

/// For Debug
/// 获取所有的 模块名字
- (NSArray<NSString *> *)debug_allModuleNames;

/// For Debug
/// 获取当前注册的所有的 模块
- (NSDictionary<NSString *, Class> *)debug_allModuleMap;
@end

NS_ASSUME_NONNULL_END
