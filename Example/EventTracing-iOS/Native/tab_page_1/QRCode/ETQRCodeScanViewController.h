//
//  ETQRCodeScanViewController.h
//  EventTracing-iOS_Example
//
//  Created by 熊勋泉 on 2023/1/4.
//  Copyright © 2023 9446796. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ETQRCodeScanViewController : UIViewController
@property (nonatomic, copy) void(^didFinishScanBlk)(NSString * text);
@end

NS_ASSUME_NONNULL_END
