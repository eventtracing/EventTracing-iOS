//
//  UIAlertAction+EventTracing.m
//  EventTracing
//
//  Created by dl on 2021/4/7.
//

#import <BlocksKit/BlocksKit.h>
#import "UIView+EventTracingPrivate.h"
#import "EventTracingEngine+Private.h"
#import "EventTracingEventActionConfig+Private.h"
#import <objc/runtime.h>

@implementation UIAlertAction (EventTracingParams)

- (UIAlertController *)et_alertController {
    return [self bk_associatedValueForKey:_cmd];
}
- (void)et_setAlertController:(UIAlertController *)et_alertController {
    [self bk_weaklyAssociateValue:et_alertController withKey:@selector(et_alertController)];
}
- (NSMutableDictionary *)et_innerParams {
    NSMutableDictionary *params = objc_getAssociatedObject(self, _cmd);
    if (!params) {
        params = [@{} mutableCopy];
        objc_setAssociatedObject(self, _cmd, params, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return params;
}
- (NSString *)et_elementId {
    return objc_getAssociatedObject(self, _cmd);
}
- (NSUInteger)et_position {
    return [objc_getAssociatedObject(self, _cmd) unsignedIntegerValue];
}
- (BOOL)et_isElement {
    return self.et_elementId.length > 0;
}
- (EventTracingEventActionConfig *)et_logEventActionConfig {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)et_setElementId:(NSString *)elementId
                 params:(NSDictionary<NSString *,NSString *> *)params {
    [self et_setElementId:elementId position:0 params:params];
}

- (void)et_setElementId:(NSString *)elementId
                  position:(NSUInteger)position
                 params:(NSDictionary<NSString *,NSString *> *)params {
    [self et_setElementId:elementId position:position params:params eventAction:nil];
}

- (void)et_setElementId:(NSString *)elementId
                    params:(NSDictionary<NSString *,NSString *> *)params
               eventAction:(void(^ NS_NOESCAPE _Nullable)(EventTracingEventActionConfig *config))block {
    [self et_setElementId:elementId position:0 params:params eventAction:block];
}

- (void)et_setElementId:(NSString *)elementId
                  position:(NSUInteger)position
                    params:(NSDictionary<NSString *,NSString *> *)params
               eventAction:(void(^ NS_NOESCAPE _Nullable)(EventTracingEventActionConfig *config))block {
    if (![elementId isKindOfClass:NSString.class] || !elementId.length) {
        return;
    }
    
    objc_setAssociatedObject(self, @selector(et_elementId), elementId, OBJC_ASSOCIATION_COPY_NONATOMIC);
    objc_setAssociatedObject(self, @selector(et_position), @(position), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    NSMutableDictionary *innerParams = [self et_innerParams];
    
    if ([params isKindOfClass:NSDictionary.class] && params.count) {
        [innerParams addEntriesFromDictionary:params];
    }
    if (position > 0) {
        [innerParams setObject:@(position).stringValue forKey:ET_PARAM_CONST_KEY_POSITION];
    }
    
    EventTracingEventActionConfig *actionConfig = [EventTracingEventActionConfig configWithEvent:ET_EVENT_ID_E_CLCK];
    // UIAlertControler中的点击事件，默认 useForRefer == NO
    actionConfig.useForRefer = NO;
    !block ?: block(actionConfig);
    
    objc_setAssociatedObject(self, @selector(et_logEventActionConfig), actionConfig, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
