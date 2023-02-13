//
//  ETMainTestInputCell.m
//  NEMemoryDetect_Example
//
//  Created by xxq on 2022/6/3.
//  Copyright © 2022 netease_music. All rights reserved.
//

#import "ETMainTestInputCell.h"

@implementation ETMainTestInputCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        _inputTextView = [[UITextView alloc] initWithFrame:CGRectMake(10, 10,
                                                                      self.bounds.size.width - 20,
                                                                      self.bounds.size.height - 20)];
        _inputTextView.layer.cornerRadius = 5;
        _inputTextView.layer.masksToBounds = YES;
        _inputTextView.backgroundColor = [UIColor lightGrayColor];
        [self.contentView addSubview:_inputTextView];
        [_inputTextView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(self.contentView);
            make.left.equalTo(self.contentView).offset(10);
            make.top.equalTo(self.contentView).offset(10);
        }];
    }
    return self;
}

- (void)configWithText:(NSString *)text {
    _inputTextView.text = text;
}

@end
