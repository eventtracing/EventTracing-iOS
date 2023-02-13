//
//  UIColor+ET.m
//  EventTracing-iOS_Example
//
//  Created by dl on 2022/12/14.
//  Copyright © 2022 9446796. All rights reserved.
//

#import "UIColor+ET.h"

@implementation UIColor (ET)

+ (UIColor *)et_randomColorWithBrightness:(float)brightness {
    return [UIColor colorWithHue:drand48() saturation:1.0 brightness:brightness alpha:1.0];
}

+ (UIColor *)et_randomColor {
    return [UIColor colorWithHue:drand48() saturation:1.0 brightness:0.5 alpha:1.0];
}

+ (UIColor *)et_bgColorWithHue:(float)hue {
    return [UIColor colorWithHue:hue saturation:1.0 brightness:0.5 alpha:1];
}

+ (UIColor *)et_colorWithHexStr:(NSString *)hexStr {
    if ([hexStr hasPrefix:@"#"]) {
        hexStr = [hexStr stringByReplacingOccurrencesOfString:@"#" withString:@""];
    }
    
    if (hexStr.length == 3) {
        NSUInteger value = 0;
        if (sscanf(hexStr.UTF8String, "%tx", &value)) {
            NSUInteger r, g, b;
            r = (value & 0x0f00) >> 8;
            g = (value & 0x00f0) >> 4;
            b = (value & 0x000f) >> 0;
            return [UIColor colorWithRed:1.f * (r) / 0x0f
                                   green:1.f * (g) / 0x0f
                                    blue:1.f * (b) / 0x0f
                                   alpha:1];
        }
        return nil;
    }
    else if (hexStr.length == 6) {
        NSUInteger value = 0;
        if (sscanf(hexStr.UTF8String, "%tx", &value)) {
            return [UIColor colorWithRed:1.f * (value >> 16 & 0xff) / 0xff
                                   green:1.f * (value >>  8 & 0xff) / 0xff
                                    blue:1.f * (value >>  0 & 0xff) / 0xff
                                   alpha:1];
        }
        return nil;
    }
    else {
        return nil;
    }
}

@end
