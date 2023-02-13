//
//  ETParamsTests.m
//  EventTracing-iOS_Tests
//
//  Created by dl on 2022/12/14.
//  Copyright © 2022 9446796. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "EventTracingDefines.h"

@interface ETParamsTests : KIFTestCase
@end

@implementation ETParamsTests

- (void)beforeAll {
    [tester tapViewWithAccessibilityLabel:@"Home"];
}

- (void)setUp {
    self.continueAfterFailure = NO;
}

- (void)afterAll {
    [tester tapViewWithAccessibilityLabel:@"Home"];
}

- (void)testPublicParamsCall {
    [tester tapViewWithAccessibilityLabel:@"List"];
    [tester et_asyncTapViewWithAccessibilityLabel:@"Home"];
    EventTracingTestLogComing *logComing = [EventTracingTestLogComing logComingWithRandomKey];
    ET_Test_WaitForTimeAtVTreeGenerateWithCondition(3, logComing, ^BOOL(EventTracingTestLogComing * _Nonnull logComing) {
        return [tester et_tryQuickFindingViewWithAccessibilityLabel:@"自动曝光"];
    });
    
    // 每条日志的产生，都会调用 动态公参 方法
    XCTAssertEqual(logComing.logJsons.count, logComing.publicDynamicParamsCallCount);
    
    // 每条日志都包含了动态公参
    XCTAssertTrue(![logComing.logJsons bk_any:^BOOL(NSDictionary *logJson) {
        return ![logJson.allKeys containsObject:@"g_dynamic_p_key"];
    }]);
    
    // 每条日志都包含了静态公参
    XCTAssertTrue(![logComing.logJsons bk_any:^BOOL(NSDictionary *logJson) {
        return ![logJson.allKeys containsObject:@"g_public_static_p_key"];
    }]);
}

- (void)testStaticParams {
    [tester et_asyncTapViewWithAccessibilityLabel:@"参数"];
    EventTracingTestLogComing *logComing = [EventTracingTestLogComing logComingWithRandomKey];
    NSString *btnSPM = @"btn_common_item|page_params";
    ET_Test_WaitForTimeAtVTreeGenerateWithCondition(1, logComing, ^BOOL(EventTracingTestLogComing * _Nonnull logComing) {
        return [logComing.logJsons bk_any:^BOOL(NSDictionary *logJson) {
            // _ev && _spm值判断
            return [logJson[ET_CONST_KEY_EVENT_CODE] isEqualToString:ET_EVENT_ID_E_VIEW]
                    && [logJson[ET_REFER_KEY_SPM] isEqualToString:btnSPM];
        }];
    });
    
    NSDictionary *btnImpressLogJson = [logComing.logJsons bk_match:^BOOL(NSDictionary *logJson) {
        return [logJson[ET_REFER_KEY_SPM] isEqualToString:btnSPM];
    }];
    // _elist count == 1
    XCTAssertTrue([btnImpressLogJson[ET_CONST_KEY_ELIST] isKindOfClass:NSArray.class] && [btnImpressLogJson[ET_CONST_KEY_ELIST] count] == 1);
    // _plist count == 1
    XCTAssertTrue([btnImpressLogJson[ET_CONST_KEY_PLIST] isKindOfClass:NSArray.class] && [btnImpressLogJson[ET_CONST_KEY_PLIST] count] == 1);
    
    NSDictionary *btnObjJson = [btnImpressLogJson[ET_CONST_KEY_ELIST] firstObject];
    
    // 对象静态私参
    XCTAssertTrue([btnObjJson[@"s_ctype"] isEqualToString:@"btn"]);
    XCTAssertTrue([btnObjJson[@"s_cid"] length] > 0);
    XCTAssertTrue([btnObjJson[@"s_ctraceid"] isEqualToString:@"btn_traceid_value"]);
    XCTAssertTrue([btnObjJson[@"s_ctrp"] isEqualToString:@"btn_trvalue"]);
    
    // 对象静态参数
    XCTAssertTrue([btnObjJson[@"btn_static_set_key"] isEqualToString:@"btn_staticm_set_value"]);
    XCTAssertTrue([btnObjJson[@"btn_static_batch_key_1"] isEqualToString:@"btn_static_batch_value_1"]);
    
    // 对象动态参数
    XCTAssertTrue([btnObjJson[@"btn_dynamic_set_key"] isEqualToString:@"btn_dynamic_set_value"]);
    XCTAssertTrue([btnObjJson[@"btn_dynamic_batch_key_1"] isEqualToString:@"btn_dynamic_batch_value_1"]);
    // 对象动态参数，可覆盖静态参数
    XCTAssertTrue([btnObjJson[@"btn_overwrite_batch_key_2"] isEqualToString:@"btn_overwrited_batch_value_2"]);
    XCTAssertTrue([btnObjJson[@"state_string"] isEqualToString:@"init"]);
    
    // 对象 callback 形式的 “对象参数”
    XCTAssertTrue([btnObjJson[@"btn_callback_key"] isEqualToString:@"btn_callback_value"]);
    
    // 对象内其他资源的内容
    XCTAssertTrue([btnObjJson[@"s_ctype_user"] isEqualToString:@"user"]);
    XCTAssertTrue([btnObjJson[@"s_cid_user"] isEqualToString:@"user_id_0"]);
    XCTAssertTrue([btnObjJson[@"s_ctraceid_user"] isEqualToString:@"user_traceid_0"]);
    XCTAssertTrue([btnObjJson[@"s_ctrp_user"] isEqualToString:@"user_trp_0"]);
    
    XCTAssertTrue([btnObjJson[@"s_ctype_song"] isEqualToString:@"song"]);
    XCTAssertTrue([btnObjJson[@"s_cid_song"] isEqualToString:@"song_id_0"]);
    
    /// MARK: 点击
    [tester et_asyncTapViewWithAccessibilityLabel:@"通用Btn组件"];
    logComing = [EventTracingTestLogComing logComingWithRandomKey];
    ET_Test_WaitForTimeAtVTreeGenerateWithCondition(1, logComing, ^BOOL(EventTracingTestLogComing * _Nonnull logComing) {
        return [logComing fetchJsonLogsForEvent:ET_EVENT_ID_E_CLCK spm:btnSPM].count > 0;
    });
    
    NSDictionary *btnClcksLogJson = [logComing.logJsons bk_match:^BOOL(NSDictionary *logJson) {
        return [logJson[ET_REFER_KEY_SPM] isEqualToString:btnSPM];
    }];
    // _elist count == 1
    XCTAssertTrue([btnClcksLogJson[ET_CONST_KEY_ELIST] isKindOfClass:NSArray.class] && [btnImpressLogJson[ET_CONST_KEY_ELIST] count] == 1);
    // _plist count == 1
    XCTAssertTrue([btnClcksLogJson[ET_CONST_KEY_PLIST] isKindOfClass:NSArray.class] && [btnImpressLogJson[ET_CONST_KEY_PLIST] count] == 1);
    
    btnObjJson = [btnClcksLogJson[ET_CONST_KEY_ELIST] firstObject];
    
    // 对象点击事件特有参数
    XCTAssertTrue([btnObjJson[@"btn_callback_ec_key"] isEqualToString:@"btn_callback_ec_value"]);
    XCTAssertTrue([btnObjJson[@"btn_callback_event_ec_key"] isEqualToString:@"btn_callback_event_ec_value"]);
    XCTAssertTrue([btnObjJson[@"btn_callback_batch_event_ec_key"] isEqualToString:@"btn_callback_batch_event_ec_value"]);
    XCTAssertTrue([btnObjJson[@"btn_callback_carry_event_key"] isEqualToString:@"btn_callback_carry_event_value__ec"]);
    
    // _ec 埋点，通过filter添加了参数
    XCTAssertTrue([btnClcksLogJson[@"key_from_filter"] isEqualToString:@"value_from_filter"]);
    
    // 点击之后，在 click handler 中增加的参数，可以在 _ec 埋点中体现
    XCTAssertTrue([btnObjJson[@"state_string"] isEqualToString:@"clicked"]);
    
    ET_Test_WaitForTime(1);
    [tester tapViewWithAccessibilityLabel:@"Back"];
}

@end
