//
//  UIAlertController+EventTracing.m
//  NEEventTracing
//
//  Created by dl on 2021/4/7.
//

#import "UIAlertController+EventTracingParams.h"
#import "UIView+EventTracing.h"

@implementation UIAlertController (EventTracing)

- (BOOL)ne_et_isIgnoreReferCascade {
    return self.view.ne_et_ignoreReferCascade;
}

- (void)ne_et_setIgnoreReferCascade:(BOOL)ne_et_ignoreReferCascade {
    self.view.ne_et_ignoreReferCascade = ne_et_ignoreReferCascade;
}

- (BOOL)ne_et_psreferMute {
    return self.view.ne_et_psreferMute;
}
- (void)ne_et_setPsreferMute:(BOOL)ne_et_psreferMute {
    self.view.ne_et_psreferMute = ne_et_psreferMute;
}

- (BOOL)ne_et_subpagePvToReferEnable {
    return self.view.ne_et_subpagePvToReferEnable;
}
- (void)ne_et_setSubpagePvToReferEnable:(BOOL)ne_et_subpagePvToReferEnable {
    self.view.ne_et_subpagePvToReferEnable = ne_et_subpagePvToReferEnable;
}
- (NEEventTracingPageReferConsumeOption)ne_et_subpageConsumeOption {
    return self.view.ne_et_subpageConsumeOption;
}
- (void)ne_et_setSubpageConsumeOption:(NEEventTracingPageReferConsumeOption)ne_et_subpageConsumeOption {
    self.view.ne_et_subpageConsumeOption = ne_et_subpageConsumeOption;
}
- (void)ne_et_clearSubpageConsumeReferOption {
    [self.view ne_et_clearSubpageConsumeReferOption];
}
- (void)ne_et_makeSubpageConsumeAllRefer {
    [self.view ne_et_makeSubpageConsumeAllRefer];
}
- (void)ne_et_makeSubpageConsumeEventRefer {
    [self.view ne_et_makeSubpageConsumeEventRefer];
}

- (void)ne_et_configLastestActionWithElementId:(NSString *)elementId
                                     params:(NSDictionary<NSString *,NSString *> *)params {
    [self ne_et_configLastestActionWithElementId:elementId position:0 params:params];
}

- (void)ne_et_configLastestActionWithElementId:(NSString *)elementId
                                      position:(NSUInteger)position
                                     params:(NSDictionary<NSString *,NSString *> *)params {
    [self ne_et_configLastestActionWithElementId:elementId position:position params:params eventAction:nil];
}

- (void)ne_et_configLastestActionWithElementId:(NSString *)elementId
                                        params:(NSDictionary<NSString *,NSString *> *)params
                                   eventAction:(void (^ NS_NOESCAPE _Nullable)(NEEventTracingEventActionConfig *))block {
    [self ne_et_configLastestActionWithElementId:elementId position:0 params:params eventAction:block];
}

- (void)ne_et_configLastestActionWithElementId:(NSString *)elementId
                                      position:(NSUInteger)position
                                     params:(NSDictionary<NSString *,NSString *> *)params
                                eventAction:(void (^ NS_NOESCAPE _Nullable)(NEEventTracingEventActionConfig *))block {
    UIAlertAction *alertAction = [self.actions lastObject];
    
    [alertAction ne_et_setElementId:elementId position:position params:params eventAction:block];
}
@end
