//
//  UICollectionView+ETDemo.m
//  NEEventTracingDataCompass
//
//  Created by xxq on 2022/10/9.
//

#import "UICollectionView+ETDemo.h"

@implementation UICollectionView (ETDemo)
+ (instancetype)et_demo_horiListWithFrame:(CGRect)frame
                            itemSize:(CGSize)itemSize
                            horiEdge:(CGFloat)horiEdge
                           horiSpace:(CGFloat)horiSpace {
    return [self et_demo_collectionWithFrame:frame itemSize:itemSize horiEdge:horiEdge horiSpace:horiSpace vertEdge:0 vertSpace:0 isHori:YES layoutClass:UICollectionViewFlowLayout.class];
}

+ (instancetype)et_demo_collectionWithFrame:(CGRect)frame
                              itemSize:(CGSize)itemSize
                              horiEdge:(CGFloat)horiEdge
                             horiSpace:(CGFloat)horiSpace
                              vertEdge:(CGFloat)vertEdge
                             vertSpace:(CGFloat)vertSpace {
    return [self et_demo_collectionWithFrame:frame itemSize:itemSize horiEdge:horiEdge horiSpace:horiSpace vertEdge:vertEdge vertSpace:vertSpace isHori:NO layoutClass:UICollectionViewFlowLayout.class];
}

+ (instancetype)et_demo_collectionWithFrame:(CGRect)frame
                                     itemSize:(CGSize)itemSize
                                     horiEdge:(CGFloat)horiEdge
                                    horiSpace:(CGFloat)horiSpace
                                     vertEdge:(CGFloat)vertEdge
                                    vertSpace:(CGFloat)vertSpace
                                       isHori:(BOOL)isHori
                                  layoutClass:(Class)layoutClass {
    UICollectionViewFlowLayout *layout = [[layoutClass alloc] init];
    if (isHori) {
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        layout.minimumInteritemSpacing = vertSpace;
        layout.minimumLineSpacing = horiSpace;
    } else {
        layout.scrollDirection = UICollectionViewScrollDirectionVertical;
        layout.minimumInteritemSpacing = horiSpace;
        layout.minimumLineSpacing = vertSpace;
    }
    layout.itemSize = itemSize;
    layout.sectionInset = UIEdgeInsetsMake(vertEdge, horiEdge, vertEdge, horiEdge);
    UICollectionView *collection = [[self alloc] initWithFrame:frame collectionViewLayout:layout];
    collection.userInteractionEnabled = YES;
    collection.bounces = NO;
    collection.showsHorizontalScrollIndicator = NO;
    collection.showsVerticalScrollIndicator = NO;
    collection.decelerationRate = UIScrollViewDecelerationRateNormal;
    collection.backgroundColor = [UIColor clearColor];
    return collection;
}
@end
