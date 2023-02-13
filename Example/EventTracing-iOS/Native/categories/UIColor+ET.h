//
//  UIColor+ET.h
//  EventTracing-iOS_Example
//
//  Created by dl on 2022/12/14.
//  Copyright © 2022 9446796. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIColor (ET)

+ (UIColor *)et_randomColorWithBrightness:(float)brightness;

+ (UIColor *)et_randomColor;

+ (UIColor *)et_bgColorWithHue:(float)hue;

+ (UIColor *)et_colorWithHexStr:(NSString *)hexStr;

@end

NS_ASSUME_NONNULL_END
