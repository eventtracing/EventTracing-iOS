//
//  ETHomeParamsViewController.m
//  EventTracing-iOS_Example
//
//  Created by dl on 2022/12/14.
//  Copyright © 2022 9446796. All rights reserved.
//

#import "ETHomeParamsViewController.h"
#import "UIColor+ET.h"
#import <EventTracing/NEEventTracingBuilder.h>

// 通用UI组件，埋点代码内聚
// 外部建议通过 callback 形式对埋点额外修改
@interface ETReuseCommonBtn : UIButton
@property(nonatomic, copy) NSString *stateString;
@end

@implementation ETReuseCommonBtn
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor et_randomColor];
        self.stateString = @"init";
        
        [[NEEventTracingBuilder view:self elementId:@"btn_common_item"] build:^(id<NEEventTracingLogNodeBuilder>  _Nonnull builder) {
            builder
            .params
            // 【推荐】便捷方法 添加，这种方式参数 `key` 不容易出错，统一封装的
            // 方法需要不断的扩展
            .ctype(@"btn")
            .cid([NSUUID UUID].UUIDString)
            .ctraceid(@"btn_traceid_value")
            .ctrp(@"btn_trvalue")
            .set(@"btn_static_set_key", @"btn_staticm_set_value")
            
            // 添加组件内部的其他资源
            .pushContent().user(@"user_id_0").ctraceid(@"user_traceid_0").ctrp(@"user_trp_0").pop()
            .pushContentWithBlock(^(id<NEEventTracingLogNodeParamContentIdBuilder>  _Nonnull content) {
                content.song(@"song_id_0");
            })
            // 批量添加
            .addParams(@{
                @"btn_static_batch_key_1": @"btn_static_batch_value_1",
                @"btn_overwrite_batch_key_2": @"btn_batch_value_2"
            });
        }];
        
        [self bk_addEventHandler:^(id sender) {
            NSLog(@"Btn clicked");
            self.stateString = @"clicked";
        } forControlEvents:UIControlEventTouchUpInside];
    }
    return self;
}

// 【推荐！！】代码内聚，而且可以支持动态参数
// 优先级高于先前`静态参数`，可覆盖前者
- (void)ne_etb_makeDynamicParams:(id<NEEventTracingLogNodeParamsBuilder>)builder {
    builder
        .set(@"state_string", self.stateString)
        .set(@"btn_dynamic_set_key", @"btn_dynamic_set_value")
        .addParams(@{
            @"btn_dynamic_batch_key_1": @"btn_dynamic_batch_value_1",
            @"btn_overwrite_batch_key_2": @"btn_overwrited_batch_value_2"
        });
}

@end

@interface ETHomeParamsViewController ()
@property(nonatomic, strong) UISwitch *switchBtn;
@property(nonatomic, strong) ETReuseCommonBtn *reuseBtn;
@end

@implementation ETHomeParamsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    [[NEEventTracingBuilder viewController:self pageId:@"page_params"] build:^(id<NEEventTracingLogNodeBuilder>  _Nonnull builder) {
        builder
        .params
        // 一些便捷方法，来添加静态参数
        .ctype(@"vc")
        .cid([NSUUID UUID].UUIDString)
        .set(@"custom_set_key", @"custom_set_value")
        .addParams(@{
            @"batch_key_1": @"batch_value_1",
            @"batch_key_2": @"batch_value_2"
        });
    }];
    
    self.reuseBtn = [[ETReuseCommonBtn alloc] init];
    [self.reuseBtn setTitle:@"通用Btn组件" forState:UIControlStateNormal];
    [self.view addSubview:self.reuseBtn];
    [self.reuseBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(200, 30));
        make.top.mas_equalTo(100);
        make.centerX.equalTo(self.view);
    }];
    
    [self.reuseBtn ne_etb_build:^(id<NEEventTracingLogNodeBuilder>  _Nonnull builder) {
        // 【callback】添加 对象&事件 维度的参数，并且在callback中可以拿到 `event` 参数
        builder.addParamsCarryEventCallbackForEvents(@[NE_ET_EVENT_ID_E_CLCK], ^(id<NEEventTracingLogNodeParamsBuilder>  _Nonnull params, NSString * _Nonnull event) {
            params.set(@"btn_callback_carry_event_key", [NSString stringWithFormat:@"btn_callback_carry_event_value_%@", event]);
        })
        // 【callback】多事件 添加 对象&事件 维度的参数
        .addParamsCallbackForEvents(@[NE_ET_EVENT_ID_E_CLCK], ^(id<NEEventTracingLogNodeParamsBuilder>  _Nonnull params) {
            params.set(@"btn_callback_batch_event_ec_key", @"btn_callback_batch_event_ec_value");
        })
        // 【callback】【点击事件】添加 对象&事件 维度的参数
        .addClickParamsCallback(^(id<NEEventTracingLogNodeParamsBuilder>  _Nonnull params) {
            params.set(@"btn_callback_ec_key", @"btn_callback_ec_value");
        })
        // 【callback】【指定事件】添加 对象&事件 维度的参数
        .addParamsCallbackForEvent(NE_ET_EVENT_ID_E_CLCK, ^(id<NEEventTracingLogNodeParamsBuilder>  _Nonnull params) {
            params.set(@"btn_callback_event_ec_key", @"btn_callback_event_ec_value");
        })
        // 【callback】添加 对象 维度的参数
        .addParamsCallback(^(id<NEEventTracingLogNodeParamsBuilder>  _Nonnull params) {
            params.set(@"btn_callback_key", @"btn_callback_value");
        })
        .params
        // 添加 对象 维度的参数
        .set(@"btn_other_key", @"btn_other_value");
    }];
}

- (NSString *)tipText {
    return @""
    "参数分为如下几类:\n"
    "  1. 公参 => 静态公参, 动态公参\n"
    "    1.1 静态公参: SDK初始化的时候，添加进来的固定参数, 比如 `deviceId`\n"
    "    1.2 动态公参: 每一条日志输出，都会调用Delegate方法来获取的动态公参，比如 `userId`\n"
    "\n"
    "  2. 对象参数 => 纯对象参数, 对象&事件参数\n"
    "    2.1 纯对象参数: 隶属于对象本身, 在对象上的任何埋点都会携带, 位置处于对象内部(_elist | _plist)\n"
    "    2.2 对象&事件参数: 该对象发生某个事件的埋点，才会携带的参数, 位置处于对象内部(_elist | _plist)\n"
    "\n"
    "  3. 事件参数 => 事件级别的参数, 位置处于对象外部, 跟_elist | _plist 平级\n"
    "\n"
    "参数的添加方式: \n"
    "  1. 静态添加: 直接调用 set(,) 方法，或者通过便捷方法, 比如 `cid, ctype`\n"
    "  2. Protocol协议添加: 动态，每次构建VTree或者发生事件等，都会调用，以获取最新参数，较适合放一些会变化的参数\n"
    "  3. callback形式: 对象维度添加参数方式, 推荐UI组件内聚埋点代码，但是通用UI组件可以在不同场景参数不一样\n"
    "    3.1 这种形式可以添加 `对象&事件` 维度的参数\n"
    "";
}

@end
