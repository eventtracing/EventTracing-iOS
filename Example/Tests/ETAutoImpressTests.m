//
//  ETTestsForKIF.m
//  EventTracing-iOS_Tests
//
//  Created by xxq on 2022/12/8.
//  Copyright © 2022 9446796. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "EventTracingDefines.h"

@interface ETTestsForKIF : KIFTestCase

@end

@implementation ETTestsForKIF

- (void)beforeAll {
    [tester tapViewWithAccessibilityLabel:@"Home"];
}

- (void)setUp {
    self.continueAfterFailure = YES;
}

- (void)beforeEach {
    // 每个测试用例执行前
}

- (void)afterAll {
    // 所有测试用例执行后
    [tester tapViewWithAccessibilityLabel:@"List"];
}

- (void)afterEach {
    // 每个测试用例执行后
}

- (void)testDebugTool {
    NSLog(@"start");
    EventTracingTestLogComing *logComing = [EventTracingTestLogComing logComingWithRandomKey];
    NE_ET_Test_WaitForTime(2);
    NSLog(@"will");

    NE_ET_Test_WaitForTimeExecBlock(2, ^(XCTestExpectation * _Nonnull expectation) {
        NSLog(@"fulfill");
        [expectation fulfill];
    });
    NSLog(@"did");
    NE_ET_Test_WaitForTime(2);
    NSLog(@"%@", logComing);
    NSLog(@"end");
        
    [tester tapViewWithAccessibilityLabel:@"List"];
    [tester tryFindingViewWithAccessibilityLabel:@"SetOffset" error:nil];
    NE_ET_Test_WaitForTime(1);
    dispatch_async(dispatch_get_main_queue(), ^{
        [tester tapViewWithAccessibilityLabel:@"Home"];
    });
    
    NE_ET_Test_WaitForTimeAtVTreeGenerateWithCondition(3, logComing, ^BOOL(EventTracingTestLogComing * _Nonnull logComing) {
        return YES;
    });
    XCTAssert(logComing.logJsons.count > 0);
    XCTAssertTrue([tester tryFindingViewWithAccessibilityLabel:@"自动曝光" error:nil]);
}

- (void)testAutoImpress
{
    EventTracingTestLogComing *logComing = [EventTracingTestLogComing logComingWithRandomKey];
    [tester ne_et_asyncTapViewWithAccessibilityLabel:@"自动曝光"];
    
    NE_ET_Test_WaitForTimeAtVTreeGenerateWithCondition(3, logComing, ^BOOL(EventTracingTestLogComing * _Nonnull logComing) {
        return [logComing fetchJsonLogsForEvent:NE_ET_EVENT_ID_E_CLCK spm:@"TableCell|mod_list_table|mod_virtual_parent_of_table|mod_list_page"].count > 0;
//        return [logComing fetchJsonLogsForEvent:NE_ET_EVENT_ID_E_CLCK spm:@"TableCell:0|mod_list_table|mod_virtual_parent_of_table|mod_list_page"].count > 0;
    });
    NE_ET_Test_WaitForTime(0.1);
    
    NSError *error;
    NSString * listLabel = @"列表";
    UITableView *tableView;
    [tester waitForAccessibilityElement:NULL view:&tableView withIdentifier:listLabel tappable:NO];
    BOOL ret = [tester tryFindingViewWithAccessibilityLabel:listLabel error:&error];
    [tableView.delegate scrollViewWillBeginDragging:tableView]; // 伪造滚动开始
    [tester waitForCellAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:50] inTableView:tableView];
    [tableView.delegate scrollViewDidEndDecelerating:tableView]; // 伪造滚动结束
    // 曝光开始
    XCTAssertTrue([logComing fetchJsonLogsForEvent:NE_ET_EVENT_ID_P_VIEW spm:@"auto_impress_page"].count > 0);
    XCTAssertTrue([logComing fetchJsonLogsForEvent:NE_ET_EVENT_ID_E_VIEW spm:@"auto_impress_test_list|auto_impress_page"].count > 0);
    XCTAssertTrue([logComing fetchJsonLogsForEvent:NE_ET_EVENT_ID_E_VIEW spm:@"exit_btn|auto_impress_page"].count > 0);
    XCTAssertTrue([logComing fetchJsonLogsForEvent:NE_ET_EVENT_ID_E_VIEW spm:@"auto_impress_cell:1|auto_impress_test_list|auto_impress_page"].count > 0);
    XCTAssertTrue([logComing fetchJsonLogsForEvent:NE_ET_EVENT_ID_E_VIEW spm:@"auto_impress_cell:250|auto_impress_test_list|auto_impress_page"].count > 0);
    // es
    XCTAssertTrue([logComing fetchJsonLogsForEvent:NE_ET_EVENT_ID_E_SLIDE spm:@"auto_impress_test_list|auto_impress_page"].count > 0);
    [tester tapViewWithAccessibilityLabel:@"退出"];
    NE_ET_Test_WaitForTime(0.3);
    // 曝光结束
    XCTAssertTrue([logComing fetchJsonLogsForEvent:NE_ET_EVENT_ID_P_VIEW_END spm:@"auto_impress_page"].count > 0);
    XCTAssertTrue([logComing fetchJsonLogsForEvent:NE_ET_EVENT_ID_E_VIEW_END spm:@"auto_impress_test_list|auto_impress_page"].count > 0);
    XCTAssertTrue([logComing fetchJsonLogsForEvent:NE_ET_EVENT_ID_E_VIEW_END spm:@"exit_btn|auto_impress_page"].count == 0);
    XCTAssertTrue([logComing fetchJsonLogsForEvent:NE_ET_EVENT_ID_E_VIEW_END spm:@"auto_impress_cell:1|auto_impress_test_list|auto_impress_page"].count > 0);
    XCTAssertTrue([logComing fetchJsonLogsForEvent:NE_ET_EVENT_ID_E_VIEW_END spm:@"auto_impress_cell:250|auto_impress_test_list|auto_impress_page"].count > 0);
    // 事件参数校验
    XCTAssertTrue([logComing fetchJsonLogsForEvent:NE_ET_EVENT_ID_E_CLCK spm:@"exit_btn|auto_impress_page" hasParaKey:@"custom_para_time" isPage:NO]);
    NE_ET_Test_WaitForTime(0.1);
}

@end
