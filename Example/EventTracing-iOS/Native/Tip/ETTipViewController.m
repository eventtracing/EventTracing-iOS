//
//  ETTipViewController.m
//  EventTracing-iOS_Example
//
//  Created by dl on 2022/12/16.
//  Copyright © 2022 9446796. All rights reserved.
//

#import "ETTipViewController.h"

void ETShowTipText(NSString *tipText) {
    ETTipViewController *tip = [[ETTipViewController alloc] init];
    [tip showWithTipText:tipText];
}

void ETShowTipAttributeText(NSAttributedString *tipAttributeText) {
    ETTipViewController *tip = [[ETTipViewController alloc] init];
    [tip showWithTipAttributeText:tipAttributeText];
}

@interface ETTipViewController ()
@property(nonatomic, strong) UIView *exitBgView;
@property(nonatomic, strong) UIView *contentBgView;
@property(nonatomic, strong) UILabel *titleLabel;
@property(nonatomic, strong) UIButton *closeBtn;
@property(nonatomic, strong) UITextView *tipTv;
@end

@implementation ETTipViewController

- (instancetype)init {
    self = [super init];
    if (self) {
        self.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        self.view.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
 
    [self.view addSubview:self.exitBgView];
    [self.view addSubview:self.contentBgView];
    [self.contentBgView addSubview:self.titleLabel];
    [self.contentBgView addSubview:self.closeBtn];
    [self.contentBgView addSubview:self.tipTv];
    
    @weakify(self)
    [self.exitBgView bk_whenTapped:^{
        @strongify(self)
        [self dimiss];
    }];
    [self.closeBtn bk_addEventHandler:^(id sender) {
        @strongify(self)
        [self dimiss];
    } forControlEvents:UIControlEventTouchUpInside];
    
    [self setUpLayout];
}

- (void)setUpLayout {
    [self.exitBgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    
    [self.contentBgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(12.f);
        make.right.bottom.mas_equalTo(-12.f);
        make.height.lessThanOrEqualTo(self.view).multipliedBy(0.7f);
        make.height.greaterThanOrEqualTo(self.view).multipliedBy(0.5f);
    }];
    
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(12.f);
        make.centerY.equalTo(self.closeBtn);
    }];
    [self.closeBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(-8.f);
        make.top.mas_equalTo(8.f);
        make.size.mas_equalTo(CGSizeMake(36, 36));
    }];
    [self.tipTv mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.contentBgView);
        make.left.equalTo(self.titleLabel);
        make.top.equalTo(self.titleLabel.mas_bottom).offset(12.f);
        make.bottom.mas_equalTo(-12.f);
    }];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    self.exitBgView.alpha = 0.f;
    self.contentBgView.transform = CGAffineTransformMakeTranslation(0.f, self.contentBgView.bounds.size.height);
    [UIView animateWithDuration:0.2 animations:^{
        self.exitBgView.alpha = .15f;
        self.contentBgView.transform = CGAffineTransformIdentity;
    }];
}

- (void)dimiss {
    [UIView animateWithDuration:0.2 animations:^{
        self.exitBgView.alpha = 0.f;
        self.contentBgView.transform = CGAffineTransformMakeTranslation(0.f, self.contentBgView.bounds.size.height);
    } completion:^(BOOL finished) {
        [self dismissViewControllerAnimated:NO completion:nil];
    }];
}

- (void)showWithTipText:(NSString *)tipText {
    NSAttributedString *attString = [[NSAttributedString alloc] initWithString:tipText attributes:@{
        NSForegroundColorAttributeName: [UIColor et_colorWithHexStr:@"333333"],
        NSFontAttributeName: [UIFont systemFontOfSize:12]
    }];
    [self showWithTipAttributeText:attString];
}

- (void)showWithTipAttributeText:(NSAttributedString *)tipAttributeText {
    self.tipTv.attributedText = tipAttributeText;
    
    UIViewController *rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    [rootViewController presentViewController:self animated:NO completion:nil];
}

#pragma mark - getters
- (UIView *)exitBgView {
    if (!_exitBgView) {
        _exitBgView = [UIView new];
        _exitBgView.alpha = 0;
        _exitBgView.backgroundColor = [UIColor blackColor];
    }
    return _exitBgView;
}

- (UIView *)contentBgView {
    if (!_contentBgView) {
        _contentBgView = [[UIView alloc] init];
        _contentBgView.backgroundColor = [UIColor whiteColor];
        _contentBgView.clipsToBounds = YES;
        _contentBgView.layer.cornerRadius = 8.f;
    }
    return _contentBgView;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.text = @"功能说明";
        _titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    }
    return _titleLabel;
}

- (UIButton *)closeBtn {
    if (!_closeBtn) {
        _closeBtn = [[UIButton alloc] init];
        [_closeBtn setImage:[UIImage imageNamed:@"close"] forState:UIControlStateNormal];
    }
    return _closeBtn;
}

- (UITextView *)tipTv {
    if (!_tipTv) {
        _tipTv = [[UITextView alloc] init];
        _tipTv.editable = NO;
        _tipTv.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.03];
        _tipTv.clipsToBounds = 1;
        _tipTv.layer.cornerRadius = 8.f;
        _tipTv.contentInset = UIEdgeInsetsMake(12.f, 12.f, 12.f, 12.f);
    }
    return _tipTv;
}

@end
