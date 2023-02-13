//
//  ETTipViewController.h
//  EventTracing-iOS_Example
//
//  Created by dl on 2022/12/16.
//  Copyright © 2022 9446796. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT void ETShowTipText(NSString *tipText);
FOUNDATION_EXPORT void ETShowTipAttributeText(NSAttributedString *tipAttributeText);

@interface ETTipViewController : UIViewController

- (void)showWithTipText:(NSString *)tipText;
- (void)showWithTipAttributeText:(NSAttributedString *)tipAttributeText;

@end

NS_ASSUME_NONNULL_END
