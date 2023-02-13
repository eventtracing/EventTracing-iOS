//
//  ETMainTestCellItem.m
//  NEMemoryDetect_Example
//
//  Created by xxq on 2022/6/2.
//  Copyright © 2022 netease_music. All rights reserved.
//

#import "ETMainTestCellItem.h"

@implementation ETMainTestCellItem
+ (instancetype)itemWithTitle:(NSString *)title target:(id)target action:(SEL)action {
    ETMainTestCellItem *item = [[ETMainTestCellItem alloc] init];
    item.title = title;
    item.target = target;
    item.action = action;
    return item;
}

@end
