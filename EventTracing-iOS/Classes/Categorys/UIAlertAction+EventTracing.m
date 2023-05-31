//
//  UIAlertAction+EventTracing.m
//  NEEventTracing
//
//  Created by dl on 2021/4/7.
//

#import <BlocksKit/BlocksKit.h>
#import "UIView+EventTracingPrivate.h"
#import "NEEventTracingEngine+Private.h"
#import "NEEventTracingEventActionConfig+Private.h"
#import <objc/runtime.h>

@implementation UIAlertAction (EventTracingParams)

- (UIAlertController *)ne_et_alertController {
    return [self bk_associatedValueForKey:_cmd];
}
- (void)ne_et_setAlertController:(UIAlertController *)ne_et_alertController {
    [self bk_weaklyAssociateValue:ne_et_alertController withKey:@selector(ne_et_alertController)];
}
- (NSMutableDictionary *)ne_et_innerParams {
    NSMutableDictionary *params = objc_getAssociatedObject(self, _cmd);
    if (!params) {
        params = [@{} mutableCopy];
        objc_setAssociatedObject(self, _cmd, params, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return params;
}
- (NSString *)ne_et_elementId {
    return objc_getAssociatedObject(self, _cmd);
}
- (NSUInteger)ne_et_position {
    return [objc_getAssociatedObject(self, _cmd) unsignedIntegerValue];
}
- (BOOL)ne_et_isElement {
    return self.ne_et_elementId.length > 0;
}
- (NEEventTracingEventActionConfig *)ne_et_logEventActionConfig {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)ne_et_setElementId:(NSString *)elementId
                 params:(NSDictionary<NSString *,NSString *> *)params {
    [self ne_et_setElementId:elementId position:0 params:params];
}

- (void)ne_et_setElementId:(NSString *)elementId
                  position:(NSUInteger)position
                 params:(NSDictionary<NSString *,NSString *> *)params {
    [self ne_et_setElementId:elementId position:position params:params eventAction:nil];
}

- (void)ne_et_setElementId:(NSString *)elementId
                    params:(NSDictionary<NSString *,NSString *> *)params
               eventAction:(void(^ NS_NOESCAPE _Nullable)(NEEventTracingEventActionConfig *config))block {
    [self ne_et_setElementId:elementId position:0 params:params eventAction:block];
}

- (void)ne_et_setElementId:(NSString *)elementId
                  position:(NSUInteger)position
                    params:(NSDictionary<NSString *,NSString *> *)params
               eventAction:(void(^ NS_NOESCAPE _Nullable)(NEEventTracingEventActionConfig *config))block {
    if (![elementId isKindOfClass:NSString.class] || !elementId.length) {
        return;
    }
    
    objc_setAssociatedObject(self, @selector(ne_et_elementId), elementId, OBJC_ASSOCIATION_COPY_NONATOMIC);
    objc_setAssociatedObject(self, @selector(ne_et_position), @(position), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    NSMutableDictionary *innerParams = [self ne_et_innerParams];
    
    if ([params isKindOfClass:NSDictionary.class] && params.count) {
        [innerParams addEntriesFromDictionary:params];
    }
    if (position > 0) {
        [innerParams setObject:@(position).stringValue forKey:NE_ET_PARAM_CONST_KEY_POSITION];
    }
    
    NEEventTracingEventActionConfig *actionConfig = [NEEventTracingEventActionConfig configWithEvent:NE_ET_EVENT_ID_E_CLCK];
    // UIAlertControler中的点击事件，默认 useForRefer == NO
    actionConfig.useForRefer = NO;
    !block ?: block(actionConfig);
    
    objc_setAssociatedObject(self, @selector(ne_et_logEventActionConfig), actionConfig, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
