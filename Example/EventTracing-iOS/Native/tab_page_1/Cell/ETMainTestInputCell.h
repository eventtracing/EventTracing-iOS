//
//  ETMainTestInputCell.h
//  NEMemoryDetect_Example
//
//  Created by xxq on 2022/6/3.
//  Copyright © 2022 netease_music. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ETMainTestInputCell : UITableViewCell
@property (nonatomic, strong) UITextView *inputTextView;

- (void)configWithText:(NSString *)text;
@end

NS_ASSUME_NONNULL_END
