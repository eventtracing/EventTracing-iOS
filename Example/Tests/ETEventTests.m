//
//  ETEventTests.m
//  EventTracing-iOS_Tests
//
//  Created by 熊勋泉 on 2022/12/19.
//  Copyright © 2022 9446796. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "EventTracingDefines.h"

@interface ETEventTests : KIFTestCase

@end

@implementation ETEventTests

- (void)beforeAll {
    [tester tapViewWithAccessibilityLabel:@"Home"];
}

- (void)setUp {
    self.continueAfterFailure = NO;
}

- (void)afterAll {
    [tester tapViewWithAccessibilityLabel:@"Home"];
}

- (void)testEvents {
    EventTracingTestLogComing *logComing = [EventTracingTestLogComing logComingWithRandomKey];
    [tester et_asyncTapViewWithAccessibilityLabel:@"事件测试"];
    
    ET_Test_WaitForTimeAtVTreeGenerateWithCondition(3, logComing, ^BOOL(EventTracingTestLogComing * _Nonnull logComing) {
        return [logComing fetchJsonLogsForEvent:ET_EVENT_ID_E_CLCK spm:@"TableCell:5|mod_list_table|mod_virtual_parent_of_table|mod_list_page"].count > 0;
    });
    
    // 按钮点击，自动ec
    XCTAssertTrue([logComing fetchJsonLogsForEvent:ET_EVENT_ID_E_CLCK spm:@"button|event_test_page"].count == 0);
    [tester tapViewWithAccessibilityLabel:@"按钮点击"];
    XCTAssertTrue([logComing fetchJsonLogsForEvent:ET_EVENT_ID_E_CLCK spm:@"button|event_test_page"].count == 1);
    
    // 手势点击，自动ec
    XCTAssertTrue([logComing fetchJsonLogsForEvent:ET_EVENT_ID_E_CLCK spm:@"label_1|event_test_page"].count == 0);
    [tester tapViewWithAccessibilityLabel:@"手势点击，自动ec"];
    XCTAssertTrue([logComing fetchJsonLogsForEvent:ET_EVENT_ID_E_CLCK spm:@"label_1|event_test_page"].count == 1);
    
    // 手势点击，手动ec
    XCTAssertTrue([logComing fetchJsonLogsForEvent:ET_EVENT_ID_E_CLCK spm:@"label_2|event_test_page"].count == 0);
    [tester tapViewWithAccessibilityLabel:@"手势点击，手动ec"];
    XCTAssertTrue([logComing fetchJsonLogsForEvent:ET_EVENT_ID_E_CLCK spm:@"label_2|event_test_page"].count == 1);
    
    // 手动事件，无链路追踪
    XCTAssertTrue([logComing fetchLastJsonLogForEvent:@"manual_ec"].count == 0);
    [tester tapViewWithAccessibilityLabel:@"手动事件，无链路追踪"];
    XCTAssertTrue([logComing fetchLastJsonLogForEvent:@"manual_ec"].count > 0);
    
    // 手动事件，参与链路追踪
    XCTAssertTrue([logComing fetchJsonLogsForEvent:@"manual_ec_2" spm:@"custom_label|event_test_page"].count == 0);
    [tester tapViewWithAccessibilityLabel:@"手动事件，参与链路追踪"];
    XCTAssertTrue([logComing fetchJsonLogsForEvent:@"manual_ec_2" spm:@"custom_label|event_test_page"].count == 1);
    NSArray * multirefers = [logComing fetchMultirefersForEvent:ET_EVENT_ID_P_VIEW spm:@"refer_page_0"];
    XCTAssertTrue(multirefers.count > 0);
    // 链路追踪验证
    XCTAssertTrue([ET_FormattedReferParseFromReferString(multirefers.firstObject).spm isEqualToString:@"custom_label|event_test_page"]);
}

@end
