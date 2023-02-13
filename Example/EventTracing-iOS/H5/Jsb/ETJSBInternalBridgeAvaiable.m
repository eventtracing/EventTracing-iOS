//
//  ETJSBInternalBridgeAvaiable.m
//  EventTracing-iOS_Example
//
//  Created by dl on 2022/12/28.
//  Copyright © 2022 9446796. All rights reserved.
//

#import "ETWebViewBridgeManager.h"

@interface ETJSBInternalBridgeAvaiable : ETWebViewBridgeModule
@end

@implementation ETJSBInternalBridgeAvaiable

ETWEBKIT_BRIDGE_MODULE_EXPORT(__et_jsb_internal_bridge)

ETWEBKIT_BRIDGE_MODULE_METHDO_EXPORT(avaiable) {
    NSString *moduleName = [context.params objectForKey:@"module"];
    NSString *methodName = [context.params objectForKey:@"method"];
    
    Class moduleClass = [[ETWebViewBridgeManager sharedInstance] moduleClassForModuleName:moduleName];
    id module = [moduleClass new];
    SEL handleSel = NSSelectorFromString([NSString stringWithFormat:@"%@DidCallWithContext:completionHandler:", methodName]);
    
    callback(nil, @{@"avaiable": @([module respondsToSelector:handleSel])});
}

@end
