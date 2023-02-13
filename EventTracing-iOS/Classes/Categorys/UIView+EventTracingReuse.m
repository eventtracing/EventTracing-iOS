//
//  UIView+EventTracingReuse.m
//  EventTracing
//
//  Created by dl on 2021/3/18.
//

#import "UIView+EventTracing.h"
#import "EventTracingDefines.h"
#import "EventTracingSentinel.h"
#import "EventTracingEngine+Private.h"
#import "UIView+EventTracingPrivate.h"

#import <BlocksKit/BlocksKit.h>

@implementation UIViewController (EventTracingReuse)
- (NSString *)et_reuseIdentifier {
    return self.p_et_view.et_reuseIdentifier;
}
- (NSString *)et_bizLeafIdentifier {
    return self.p_et_view.et_bizLeafIdentifier;
}
- (NSString * _Nonnull (^)(NSString * _Nonnull))et_autoClassifyIdAppend {
    return self.p_et_view.et_autoClassifyIdAppend;
}
- (void)et_bindDataForReuse:(id)data {
    [self.p_et_view et_bindDataForReuse:data];
}
- (void)et_setNeedsImpress {
    [self.p_et_view et_setNeedsImpress];
}
@end

@implementation UIView (EventTracingReuse)

- (NSString *)et_reuseIdentifier {
    return self.et_props.reuseIdentifier;
}
- (NSString *)et_bizLeafIdentifier {
    return self.et_props.bizLeafIdentifier;
}
- (NSString * _Nonnull (^)(NSString * _Nonnull))et_autoClassifyIdAppend {
    return self.et_props.autoClassifyIdAppend;
}
- (void)et_bindDataForReuse:(id)data {
    [self.et_props bindDataForReuse:data];
}

- (void)et_setNeedsImpress {
    void(^block)(void) = ^() {
        [self.et_props.reuseSEQ increase];
        [self.et_props setResueIdentifierNeedsUpdate];
        
        [[EventTracingEngine sharedInstance] traverse:self];
    };
    
    ETDispatchMainAsyncSafe(block);
}

@end
