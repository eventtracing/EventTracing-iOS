//
//  ETMainTestCellItem.h
//  NEMemoryDetect_Example
//
//  Created by xxq on 2022/6/2.
//  Copyright © 2022 netease_music. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ETMainTestCellItem : NSObject
@property (nonatomic, copy) NSString *title;
@property (nonatomic, weak) id target;
@property (nonatomic, assign) SEL action;

+ (instancetype)itemWithTitle:(NSString *)title target:(nullable id)target action:(SEL)action;
@end

NS_ASSUME_NONNULL_END
