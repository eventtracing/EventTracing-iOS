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

- (BOOL)et_subpagePvToReferEnable {
    return self.view.et_subpagePvToReferEnable;
}
- (void)et_setSubpagePvToReferEnable:(BOOL)et_subpagePvToReferEnable {
    self.view.et_subpagePvToReferEnable = et_subpagePvToReferEnable;
}
- (EventTracingPageReferConsumeOption)et_subpageConsumeOption {
    return self.view.et_subpageConsumeOption;
}
- (void)et_setSubpageConsumeOption:(EventTracingPageReferConsumeOption)et_subpageConsumeOption {
    self.view.et_subpageConsumeOption = et_subpageConsumeOption;
}
- (void)et_clearSubpageConsumeReferOption {
    [self.view et_clearSubpageConsumeReferOption];
}
- (void)et_makeSubpageConsumeAllRefer {
    [self.view et_makeSubpageConsumeAllRefer];
}
- (void)et_makeSubpageConsumeEventRefer {
    [self.view et_makeSubpageConsumeEventRefer];
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
