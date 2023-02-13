//
//  UICollectionView+ETDemo.h
//  NEEventTracingDataCompass
//
//  Created by xxq on 2022/10/9.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UICollectionView (ETDemo)

+ (instancetype)et_demo_horiListWithFrame:(CGRect)frame
                                   itemSize:(CGSize)itemSize
                                   horiEdge:(CGFloat)horiEdge
                                  horiSpace:(CGFloat)horiSpace;

+ (instancetype)et_demo_collectionWithFrame:(CGRect)frame
                                     itemSize:(CGSize)itemSize
                                     horiEdge:(CGFloat)horiEdge
                                    horiSpace:(CGFloat)horiSpace
                                     vertEdge:(CGFloat)vertEdge
                                    vertSpace:(CGFloat)vertSpace;

+ (instancetype)et_demo_collectionWithFrame:(CGRect)frame
                                     itemSize:(CGSize)itemSize
                                     horiEdge:(CGFloat)horiEdge
                                    horiSpace:(CGFloat)horiSpace
                                     vertEdge:(CGFloat)vertEdge
                                    vertSpace:(CGFloat)vertSpace
                                       isHori:(BOOL)isHori
                                  layoutClass:(Class)layoutClass;

@end

NS_ASSUME_NONNULL_END
