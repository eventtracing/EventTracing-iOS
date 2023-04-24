//
//  UIScrollView+EventTracingES.h
//  NEEventTracing
//
//  Created by dl on 2021/8/2.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// MARK: SDK内置了 _es 滑动事件，可以按需开启
@interface UIScrollView (EventTracingES)

// default: NO
@property(nonatomic, assign, getter=ne_et_isESEventEnable, setter=ne_et_setESEventEnable:) BOOL ne_et_esEventEnable;

@end

NS_ASSUME_NONNULL_END
