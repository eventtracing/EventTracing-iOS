//
//  ETMainTestCell.m
//  NEMemoryDetect_Example
//
//  Created by xxq on 2022/6/2.
//  Copyright © 2022 netease_music. All rights reserved.
//

#import "ETMainTestCell.h"
#import <EventTracing/NEEventTracingBuilder.h>

@implementation ETMainTestCell

- (void)awakeFromNib {
    [super awakeFromNib];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        _contentLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 5, self.bounds.size.width - 20, self.bounds.size.height - 10)];
        _contentLabel.backgroundColor = [UIColor et_colorWithHexStr:@"#4895ef"];
        _contentLabel.font = [UIFont systemFontOfSize:20];
        _contentLabel.textColor = [UIColor whiteColor];
        _contentLabel.textAlignment = NSTextAlignmentCenter;
        _contentLabel.layer.masksToBounds = YES;
        _contentLabel.layer.cornerRadius = 6;
        [self.contentView addSubview:_contentLabel];
        [_contentLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(self.contentView);
            make.left.equalTo(self.contentView).offset(20);
            make.top.equalTo(self.contentView).offset(6);
        }];
        
        [[NEEventTracingBuilder view:self elementId:@"TableCell"] build:^(id<NEEventTracingLogNodeBuilder>  _Nonnull builder) {
            builder.params.set(@"cell_key", @"cell_val_456");
        }];
    }
    return self;
}

- (void)configWithItem:(ETMainTestCellItem *)item {
    self.item = item;
    _contentLabel.text = item.title;
    
    [self ne_etb_build:^(id<NEEventTracingLogNodeBuilder>  _Nonnull builder) {
        builder.bindDataForReuse(item)
            .params
            .set(@"title", item.title ?: @"");
    }];
}

- (void)ne_etb_makeDynamicParams:(id<NEEventTracingLogNodeParamsBuilder>)builder {
    NSString *title1 = self.item.title;
    NSString *title2 = [self.ne_et_currentVTreeNode.nodeParams objectForKey:@"title"];
    if (title1 && title2 && ![title1 isEqualToString:title2]) {
        NSLog(@"title not equal");
    }
    
    builder.set(@"d_title", self.item.title);
}

@end
