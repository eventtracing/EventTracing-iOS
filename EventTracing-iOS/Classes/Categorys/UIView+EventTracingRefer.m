//
//  UIView+EventTracingRefer.m
//  EventTracing
//
//  Created by dl on 2021/4/1.
//

#import "UIView+EventTracingPrivate.h"
#import <BlocksKit/BlocksKit.h>

@implementation UIView (EventTracingRefer)

- (void)et_makeReferToid:(NSString *)toid {
    if (!toid || toid.length == 0) {
        return;
    }
    [self _et_makeReferToids:@[toid] reset:NO];
}

- (void)et_makeReferToids:(NSString *)toid, ... {
    NSMutableArray<NSString *> *toids = [@[] mutableCopy];
    ETGetArgsArr(toids, toid, NSString)
    
    [self _et_makeReferToids:toids reset:NO];
}

- (void)et_remakeReferToid:(NSString *)toid {
    if (!toid || toid.length == 0) {
        return;
    }
    
    [self _et_makeReferToids:@[toid] reset:YES];
}

- (void)et_remakeReferToids:(NSString *)toid, ... {
    NSMutableArray<NSString *> *toids = [@[] mutableCopy];
    ETGetArgsArr(toids, toid, NSString)
    
    [self _et_makeReferToids:toids reset:YES];
}

- (void)_et_makeReferToids:(NSArray<NSString *> *)toids reset:(BOOL)reset __attribute__((objc_direct)) {
    NSMutableArray<NSString *> *toidArr = [self et_toids].mutableCopy;
    if (!toidArr || reset) {
        toidArr = [@[] mutableCopy];
    }
    
    if (toids) {
        [toidArr addObjectsFromArray:[toids bk_select:^BOOL(NSString *obj) {
            return [obj isKindOfClass:NSString.class] && obj.length > 0;
        }]];
    }
    
    self.et_props.toids = toids;
}

- (void)et_clearReferToids {
    self.et_props.toids = nil;
}

#pragma mark - getters & setters
- (NSArray<NSString *> *)et_toids {
    return self.et_props.toids;
}

@end
