//
//  ETMountTests.m
//  EventTracing-iOS_Tests
//
//  Created by 熊勋泉 on 2022/12/14.
//  Copyright © 2022 9446796. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "EventTracingDefines.h"

@interface ETMountTests : KIFTestCase

@end

@implementation ETMountTests

- (void)beforeAll {
    [tester tapViewWithAccessibilityLabel:@"Home"];
}

- (void)setUp {
    self.continueAfterFailure = NO;
}

- (void)afterAll {
    [tester tapViewWithAccessibilityLabel:@"Home"];
}

- (void)testVisible {
    EventTracingTestLogComing *logComing = [EventTracingTestLogComing logComingWithRandomKey];
    [tester ne_et_asyncTapViewWithAccessibilityLabel:@"逻辑挂载"];
    
    NE_ET_Test_WaitForTimeAtVTreeGenerateWithCondition(3, logComing, ^BOOL(EventTracingTestLogComing * _Nonnull logComing) {
        return [logComing fetchJsonLogsForEvent:NE_ET_EVENT_ID_E_CLCK spm:@"TableCell:3|mod_list_table|mod_virtual_parent_of_table|mod_list_page"].count > 0;
    });
    NE_ET_Test_WaitForTime(0.1);
    // MARK: 自动根节点
    XCTAssertTrue([logComing fetchJsonLogsForEvent:NE_ET_EVENT_ID_P_VIEW spm:@"mount_root_1"].count > 0);
    // MARK: 自动挂载
    XCTAssertTrue([logComing fetchJsonLogsForEvent:NE_ET_EVENT_ID_P_VIEW spm:@"mount_view_page_1|mount_root_1"].count > 0);
    // MARK: 手动根节点
    XCTAssertTrue([logComing fetchJsonLogsForEvent:NE_ET_EVENT_ID_P_VIEW spm:@"mount_root_logic"].count > 0);
    // MARK: 逻辑 page 挂载
    XCTAssertTrue([logComing fetchJsonLogsForEvent:NE_ET_EVENT_ID_P_VIEW spm:@"mount_view_page_2|mount_root_logic"].count > 0);
    // MARK: spm 挂载
    XCTAssertTrue([logComing fetchJsonLogsForEvent:NE_ET_EVENT_ID_E_VIEW spm:@"mount_subview_1|mount_root_logic"].count > 0);
    // MARK: logic 挂载
    XCTAssertTrue([logComing fetchJsonLogsForEvent:NE_ET_EVENT_ID_E_VIEW spm:@"mount_subview_2|mount_view_page_1|mount_root_1"].count > 0);
    // MARK: 虚拟父节点 + logic 挂载
    XCTAssertTrue([logComing fetchJsonLogsForEvent:NE_ET_EVENT_ID_E_VIEW spm:@"mount_subview_3|virtual_parent_oid|mount_view_page_1|mount_root_1"].count > 0);
    
    // MARK: 可见区域穿透
    [tester tapViewWithAccessibilityLabel:@"点击弹出浮层"];
    NSDictionary * jsonLog =
    [logComing fetchLastJsonLogForEvent:NE_ET_EVENT_ID_E_VIEW spm:@"float_alert|float_btn|mount_root_1"];
    NSArray<NSDictionary *> * elist = jsonLog[NE_ET_CONST_KEY_ELIST];
    XCTAssertTrue(elist.count > 0);
    NSDictionary * jsonInfo =
    [elist bk_match:^BOOL(NSDictionary * obj) {
        return [obj[NE_ET_CONST_KEY_OID] isEqualToString:@"float_alert"];
    }];
    XCTAssertTrue(jsonInfo[@"_debug_visible_rect"] != nil);
    NSString * oriStr = jsonInfo[@"_debug_visible_rect"];
    NSMutableArray<NSString *> * components = [[oriStr componentsSeparatedByString:@","] mutableCopy];
    components[3] = [components[3] stringByAppendingString:@"}"];
    components[2] = [@"{" stringByAppendingString:components[2]];
    components[1] = [components[1] stringByAppendingString:@"}"];
    components[0] = [@"{" stringByAppendingString:components[0]];
    NSString * rectStr = [components componentsJoinedByString:@","];
    CGRect visibleRect = CGRectFromString(rectStr);
    XCTAssertTrue(CGRectEqualToRect(visibleRect, UIScreen.mainScreen.bounds));
    [tester tapViewWithAccessibilityLabel:@"点击弹出浮层"];
    
    // MARK: page 遮挡
    [tester tapViewWithAccessibilityLabel:@"弹出遮挡浮层"];
    XCTAssertTrue([logComing fetchJsonLogsForEvent:NE_ET_EVENT_ID_P_VIEW spm:@"cover_alert_page"].count > 0);
    // 完全挡住的
    XCTAssertTrue([logComing fetchJsonLogsForEvent:NE_ET_EVENT_ID_E_VIEW_END spm:@"mount_subview_1|mount_root_logic"].count > 0);
    XCTAssertTrue([logComing fetchJsonLogsForEvent:NE_ET_EVENT_ID_P_VIEW_END spm:@"mount_view_page_2|mount_root_logic"].count > 0);
    XCTAssertTrue([logComing fetchJsonLogsForEvent:NE_ET_EVENT_ID_P_VIEW_END spm:@"mount_root_logic"].count > 0);
    XCTAssertTrue([logComing fetchJsonLogsForEvent:NE_ET_EVENT_ID_E_VIEW_END spm:@"mount_subview_2|mount_view_page_1|mount_root_1"].count > 0);
    XCTAssertTrue([logComing fetchJsonLogsForEvent:NE_ET_EVENT_ID_P_VIEW_END spm:@"mount_view_page_1|mount_root_1"].count > 0);
    // 没有完全挡住的
    XCTAssertTrue([logComing fetchJsonLogsForEvent:NE_ET_EVENT_ID_P_VIEW_END spm:@"mount_root_1"].count == 0);
    [tester tapViewWithAccessibilityLabel:@"CoverLabel"];
}

@end
