//
//  ETReferViewController.h
//  EventTracing-iOS_Example
//
//  Created by 熊勋泉 on 2022/12/15.
//  Copyright © 2022 9446796. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ETReferViewController : UIViewController
@property (nonatomic, assign, readonly) NSInteger depth;

@property (nonatomic, strong, readonly) UIButton * pushVCBtn;
@property (nonatomic, strong, readonly) UIButton * presentVCBtn;
@property (nonatomic, strong, readonly) UIButton * exitBtn;
@property (nonatomic, strong, readonly) UIButton * pushBridgeVCBtn;

- (instancetype)initWithDepth:(NSInteger)depth;
@end

NS_ASSUME_NONNULL_END
