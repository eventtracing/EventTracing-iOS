//
//  ETHomeCollectionViewCell.h
//  EventTracing_Example
//
//  Created by dl on 2021/4/1.
//  Copyright © 2021 ShakeShakeMe. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ETHomeCollectionViewCell : UICollectionViewCell
@property(nonatomic, strong) UILabel *titleLabel;

- (void) refreshWithData:(NSDictionary *)data;
@end

NS_ASSUME_NONNULL_END
