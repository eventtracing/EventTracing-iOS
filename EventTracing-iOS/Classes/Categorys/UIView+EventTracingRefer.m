//
//  UIView+EventTracingRefer.m
//  NEEventTracing
//
//  Created by dl on 2021/4/1.
//

#import "UIView+EventTracingPrivate.h"
#import <BlocksKit/BlocksKit.h>

@implementation UIView (EventTracingRefer)

- (void)ne_et_makeReferToid:(NSString *)toid {/*已废弃*/}

- (void)ne_et_makeReferToids:(NSString *)toid, ... {/*已废弃*/}

- (void)ne_et_remakeReferToid:(NSString *)toid {/*已废弃*/}

- (void)ne_et_remakeReferToids:(NSString *)toid, ... {/*已废弃*/}

- (void)_et_makeReferToids:(NSArray<NSString *> *)toids reset:(BOOL)reset __attribute__((objc_direct)) {/*已废弃*/}

- (void)ne_et_clearReferToids {/*已废弃*/}

#pragma mark - getters & setters
- (NSArray<NSString *> *)ne_et_toids {/*已废弃*/ return nil;}

@end
