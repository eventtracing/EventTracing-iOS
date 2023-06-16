//
//  KIFUITestActor+NE_ET_Extra.m
//  EventTracing-iOS_Example
//
//  Created by dl on 2022/12/14.
//  Copyright © 2022 9446796. All rights reserved.
//

#import "KIFUITestActor+NE_ET_Extra.h"

@implementation KIFUITestActor (NE_ET_Extra)

- (BOOL)et_tryQuickFindingViewWithAccessibilityLabel:(NSString *)label {
    return [self ne_et_tryFindingViewWithAccessibilityLabel:label timeout:0.05];
}

- (BOOL)et_tryFindingViewWithAccessibilityLabel:(NSString *)label timeout:(NSTimeInterval)timeout {
    return [self ne_et_tryFindingViewWithAccessibilityLabel:label timeout:timeout tappable:NO];
}

- (BOOL)et_tryFindingViewWithAccessibilityLabel:(NSString *)label timeout:(NSTimeInterval)timeout tappable:(BOOL)tappable {
    return [tester tryRunningBlock:^KIFTestStepResult(NSError *__autoreleasing *error) {
        return [UIAccessibilityElement accessibilityElement:NULL view:nil withLabel:label value:nil traits:UIAccessibilityTraitNone tappable:tappable error:nil] ? KIFTestStepResultSuccess : KIFTestStepResultWait;
    } complete:nil timeout:timeout error:nil];
}

- (void)et_asyncTapViewWithAccessibilityLabel:(NSString *)label {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self tapViewWithAccessibilityLabel:label];
    });
}

@end
