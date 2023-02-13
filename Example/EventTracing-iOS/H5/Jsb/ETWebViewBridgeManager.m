//
//  ETWebViewBridgeManager.m
//  EventTracing-iOS_Example
//
//  Created by dl on 2022/12/27.
//  Copyright © 2022 9446796. All rights reserved.
//

#import "ETWebViewBridgeManager.h"

@interface ETWebViewBridgeManager ()
@property (nonatomic) NSMutableDictionary *modules;
@end

@implementation ETWebViewBridgeManager

+ (instancetype)sharedInstance {
    static ETWebViewBridgeManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [self new];
        sharedInstance.modules = @{}.mutableCopy;
    });
    return sharedInstance;
}

- (void)registModule:(Class)moduleClass forModuleName:(NSString *)moduleName {
    
    Class previousClass = self.modules[moduleName];
    NSAssert(previousClass == nil, @"%@ 存在可以处理的模块 %@", moduleName, previousClass);
    self.modules[moduleName] = moduleClass;
}

- (Class)moduleClassForModuleName:(NSString *)moduleName {
    return self.modules[moduleName];
}

@end

@implementation ETWebViewBridgeManager (Debug)

- (NSArray<NSString *> *)debug_allModuleNames {
    return self.modules.allKeys;
}

- (NSDictionary *)debug_allModuleMap {
    return [self.modules copy];;
}


@end

@implementation ETWebViewBridgeModule
@synthesize bridge = _bridge;

#pragma mark - ETWebViewBridgeModuleProtocol
- (NSString *)moduleName {
    NSAssert(NO, @"Sub module class need override");
    return nil;
}
@end
