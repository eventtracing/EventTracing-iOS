//
//  UIView+EventTracingReuse.m
//  NEEventTracing
//
//  Created by dl on 2021/3/18.
//

#import "UIView+EventTracing.h"
#import "NEEventTracingDefines.h"
#import "NEEventTracingSentinel.h"
#import "NEEventTracingEngine+Private.h"
#import "UIView+EventTracingPrivate.h"

#import <BlocksKit/BlocksKit.h>

@implementation UIViewController (EventTracingReuse)
- (NSString *)ne_et_reuseIdentifier {
    return self.p_ne_et_view.ne_et_reuseIdentifier;
}
- (NSString *)ne_et_bizLeafIdentifier {
    return self.p_ne_et_view.ne_et_bizLeafIdentifier;
}
- (NSString * _Nonnull (^)(NSString * _Nonnull))ne_et_autoClassifyIdAppend {
    return self.p_ne_et_view.ne_et_autoClassifyIdAppend;
}
- (void)ne_et_bindDataForReuse:(id)data {
    [self.p_ne_et_view ne_et_bindDataForReuse:data];
}
- (void)ne_et_setNeedsImpress {
    [self.p_ne_et_view ne_et_setNeedsImpress];
}
@end

@implementation UIView (EventTracingReuse)

- (NSString *)ne_et_reuseIdentifier {
    return self.ne_et_props.reuseIdentifier;
}
- (NSString *)ne_et_bizLeafIdentifier {
    return self.ne_et_props.bizLeafIdentifier;
}
- (NSString * _Nonnull (^)(NSString * _Nonnull))ne_et_autoClassifyIdAppend {
    return self.ne_et_props.autoClassifyIdAppend;
}
- (void)ne_et_bindDataForReuse:(id)data {
    [self.ne_et_props bindDataForReuse:data];
}

- (void)ne_et_setNeedsImpress {
    void(^block)(void) = ^() {
        [self.ne_et_props.reuseSEQ increase];
        [self.ne_et_props setResueIdentifierNeedsUpdate];
        
        [[NEEventTracingEngine sharedInstance] traverse:self];
    };
    
    NEETDispatchMainAsyncSafe(block);
}

@end
