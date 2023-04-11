//
//  UIView+EventTracingRefer.m
//  EventTracing
//
//  Created by dl on 2021/4/1.
//

#import "UIView+EventTracingPrivate.h"
#import <BlocksKit/BlocksKit.h>

@implementation UIView (EventTracingRefer)

- (void)et_makeReferToid:(NSString *)toid {/*废弃*/}

- (void)et_makeReferToids:(NSString *)toid, ... {/*废弃*/}

- (void)et_remakeReferToid:(NSString *)toid {/*废弃*/}

- (void)et_remakeReferToids:(NSString *)toid, ... {/*废弃*/}

- (void)_et_makeReferToids:(NSArray<NSString *> *)toids reset:(BOOL)reset __attribute__((objc_direct)) {/*废弃*/}

- (void)et_clearReferToids {/*废弃*/}

#pragma mark - getters & setters
- (NSArray<NSString *> *)et_toids {/*废弃*/ return nil;}

@end
