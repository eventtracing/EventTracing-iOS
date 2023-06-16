//
//  ETHomeCollectionViewCell.m
//  EventTracing_Example
//
//  Created by dl on 2021/4/1.
//  Copyright © 2021 ShakeShakeMe. All rights reserved.
//

#import "ETHomeCollectionViewCell.h"
#import <EventTracing/NEEventTracingBuilder.h>

@interface ETHomeCollectionViewCell ()
@property(nonatomic, strong) NSDictionary *data;
@end

@implementation ETHomeCollectionViewCell
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.titleLabel = [[UILabel alloc] init];
        self.titleLabel.font = [UIFont systemFontOfSize:15];
        self.titleLabel.textAlignment = NSTextAlignmentCenter;
        [self.contentView addSubview:self.titleLabel];
        
        [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.contentView);
        }];
        
        [[NEEventTracingBuilder view:self elementId:@"CollectionCell"] build:^(id<NEEventTracingLogNodeBuilder>  _Nonnull builder) {
            builder.params.set(@"cell_key", @"cell_val_123");
        }];
    }
    return self;
}

- (void)refreshWithData:(NSDictionary *)data {
    self.data = data;
    
    self.contentView.backgroundColor = [data objectForKey:@"color"];
    self.titleLabel.text = [data objectForKey:@"idx"];
    
    [self ne_etb_build:^(id<NEEventTracingLogNodeBuilder>  _Nonnull builder) {
        builder.bindDataForReuse(data)
        .params
        .set(@"idx", [data objectForKey:@"idx"]);
    }];
}

- (void)ne_etb_makeDynamicParams:(id<NEEventTracingLogNodeParamsBuilder>)builder {
    builder.set(@"d_idx", [self.data objectForKey:@"idx"]);
}

@end
