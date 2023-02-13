//
//  UIAlertController+EventTracing.m
//  EventTracing
//
//  Created by dl on 2021/4/7.
//

#import "UIAlertController+EventTracingParams.h"
#import "UIView+EventTracing.h"

@implementation UIAlertController (EventTracing)

- (BOOL)et_isIgnoreReferCascade {
    return self.view.et_ignoreReferCascade;
}

- (void)et_setIgnoreReferCascade:(BOOL)et_ignoreReferCascade {
    self.view.et_ignoreReferCascade = et_ignoreReferCascade;
}

- (BOOL)et_psreferMute {
    return self.view.et_psreferMute;
}
- (void)et_setPsreferMute:(BOOL)et_psreferMute {
    self.view.et_psreferMute = et_psreferMute;
}

- (void)et_configLastestActionWithElementId:(NSString *)elementId
                                     params:(NSDictionary<NSString *,NSString *> *)params {
    [self et_configLastestActionWithElementId:elementId position:0 params:params];
}

- (void)et_configLastestActionWithElementId:(NSString *)elementId
                                      position:(NSUInteger)position
                                     params:(NSDictionary<NSString *,NSString *> *)params {
    [self et_configLastestActionWithElementId:elementId position:position params:params eventAction:nil];
}

- (void)et_configLastestActionWithElementId:(NSString *)elementId
                                        params:(NSDictionary<NSString *,NSString *> *)params
                                   eventAction:(void (^ NS_NOESCAPE _Nullable)(EventTracingEventActionConfig *))block {
    [self et_configLastestActionWithElementId:elementId position:0 params:params eventAction:block];
}

- (void)et_configLastestActionWithElementId:(NSString *)elementId
                                      position:(NSUInteger)position
                                     params:(NSDictionary<NSString *,NSString *> *)params
                                eventAction:(void (^ NS_NOESCAPE _Nullable)(EventTracingEventActionConfig *))block {
    UIAlertAction *alertAction = [self.actions lastObject];
    
    [alertAction et_setElementId:elementId position:position params:params eventAction:block];
}
@end
