//
//  ETBaseViewController.m
//  EventTracing-iOS_Example
//
//  Created by dl on 2022/12/16.
//  Copyright © 2022 9446796. All rights reserved.
//

#import "ETBaseViewController.h"
#import "ETTipViewController.h"

@interface ETBaseViewController ()

@end

@implementation ETBaseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Tip" style:UIBarButtonItemStylePlain target:self action:@selector(showTip:)];
}

- (void)showTip:(id)sender {
    NSAttributedString *tipAttributeText = [self tipAttributeText];
    if (!tipAttributeText || tipAttributeText.length == 0) {
        NSString *tipText = [self tipText];
        if (tipText.length) {
            ETShowTipText(tipText);
        }
    } else {
        ETShowTipAttributeText(tipAttributeText);
    }
}

- (NSString *)tipText {
    return nil;
}

- (NSAttributedString *)tipAttributeText {
    return nil;
}

@end
