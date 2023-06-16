//
//  KIFUITestActor+NE_ET_Extra.h
//  EventTracing-iOS_Example
//
//  Created by dl on 2022/12/14.
//  Copyright © 2022 9446796. All rights reserved.
//

#import <KIF/KIF.h>
#import <KIF/UIAccessibilityElement-KIFAdditions.h>

NS_ASSUME_NONNULL_BEGIN

@interface KIFUITestActor (NE_ET_Extra)

- (BOOL)et_tryQuickFindingViewWithAccessibilityLabel:(NSString *)label;
- (BOOL)et_tryFindingViewWithAccessibilityLabel:(NSString *)label timeout:(NSTimeInterval)timeout;
- (BOOL)et_tryFindingViewWithAccessibilityLabel:(NSString *)label timeout:(NSTimeInterval)timeout tappable:(BOOL)tappable;

- (void)et_asyncTapViewWithAccessibilityLabel:(NSString *)label;

@end

NS_ASSUME_NONNULL_END
