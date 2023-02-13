//
//  ETMainTestCell.h
//  NEMemoryDetect_Example
//
//  Created by xxq on 2022/6/2.
//  Copyright © 2022 netease_music. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ETMainTestCellItem.h"

NS_ASSUME_NONNULL_BEGIN

@interface ETMainTestCell : UITableViewCell
@property (nonatomic, strong) UILabel *contentLabel;
@property (nonatomic, strong) ETMainTestCellItem *item;

- (void)configWithItem:(ETMainTestCellItem *)item;
@end

NS_ASSUME_NONNULL_END
