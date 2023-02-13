//
//  ETAlertTests.m
//  EventTracing-iOS_Tests
//
//  Created by dl on 2022/12/15.
//  Copyright © 2022 9446796. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "EventTracingDefines.h"

@interface ETAlertTests : KIFTestCase
@end

@implementation ETAlertTests

- (void)beforeAll {
    [tester tapViewWithAccessibilityLabel:@"Home"];
}

- (void)setUp {
    self.continueAfterFailure = NO;
}

- (void)tearDown {
    
}

- (void)afterAll {
    [tester tapViewWithAccessibilityLabel:@"Home"];
}

- (void)afterEach {
    [tester tapViewWithAccessibilityLabel:@"Home"];
}

- (void)testAlert {
    EventTracingTestLogComing *logComing = [EventTracingTestLogComing logComingWithRandomKey];
    [tester et_asyncTapViewWithAccessibilityLabel:@"系统Alert"];
    
    NSString *show_alert_btn_spm = @"btn_show_alert|page_alert";
    ET_Test_WaitForTimeAtVTreeGenerateWithCondition(3, logComing, ^BOOL(EventTracingTestLogComing * _Nonnull logComing) {
        return [logComing fetchJsonLogsForEvent:ET_EVENT_ID_E_VIEW spm:show_alert_btn_spm].count > 0;
    });
    ET_Test_WaitForTime(0.5);
    
    EventTracingVTree *VTree = logComing.lastVTree;
    EventTracingVTreeNode *page_alert_node = [self _findNodeBySPM:@"page_alert" inVTree:VTree];
    
    // 根页面曝光，全局 pgstep + 1, actseq == 1
    XCTAssertNotNil(page_alert_node);
    XCTAssertTrue(page_alert_node.pgstep != 0);
    NSInteger actseq = page_alert_node.actseq;
    XCTAssertEqual(actseq, 1);
    
    // 点击 show alert 按钮
    [tester et_asyncTapViewWithAccessibilityLabel:@"ShowAlert"];
    ET_Test_WaitForTimeAtVTreeGenerateWithCondition(3, logComing, ^BOOL(EventTracingTestLogComing * _Nonnull logComing) {
        return [logComing fetchJsonLogsForEvent:ET_EVENT_ID_E_CLCK spm:show_alert_btn_spm].count > 0;
    });
    
    VTree = logComing.lastVTree;
    EventTracingVTreeNode *show_alert_btn_node = [self _findNodeBySPM:show_alert_btn_spm inVTree:VTree];
    
    // 按钮点击，在根页面范围内(`page_alert`) actseq +1
    XCTAssertNotNil(show_alert_btn_node);
    XCTAssertEqual(show_alert_btn_node.actseq, actseq + 1);
    XCTAssertEqual(show_alert_btn_node.actseq, page_alert_node.actseq);     // 自增的其实是 rootpage.actseq
    actseq = show_alert_btn_node.actseq;
    
    // 延后了 .5s 展示 alert
    logComing = [EventTracingTestLogComing logComingWithRandomKey];
    NSString *alert_spm = @"page_float_alert|page_alert";
    NSString *alert_ok_btn_spm = @"btn:1|page_float_alert|page_alert";
    NSString *alert_cancel_btn_spm = @"btn:2|page_float_alert|page_alert";

    ET_Test_WaitForTimeAtVTreeGenerateWithCondition(3, logComing, ^BOOL(EventTracingTestLogComing * _Nonnull logComing) {
        return [logComing fetchJsonLogsForEvent:ET_EVENT_ID_P_VIEW spm:alert_spm].count > 0;
    });

    ET_Test_WaitForTime(0.5);
    
    VTree = logComing.lastVTree;
    NSArray<NSDictionary *> *alert_pv_logJsons = [logComing fetchJsonLogsForEvent:ET_EVENT_ID_P_VIEW spm:alert_spm];
    NSArray<NSDictionary *> *alert_btn_ok_ev_logJsons = [logComing fetchJsonLogsForEvent:ET_EVENT_ID_E_VIEW spm:alert_ok_btn_spm];
    NSArray<NSDictionary *> *alert_btn_cancel_ev_logJsons = [logComing fetchJsonLogsForEvent:ET_EVENT_ID_E_VIEW spm:alert_cancel_btn_spm];

    XCTAssertTrue(alert_pv_logJsons.count == 1);
    XCTAssertTrue(alert_btn_ok_ev_logJsons.count == 0);     // 不需要有该按钮的点击曝光，因为按钮曝光等同于 alert 的 pv
    XCTAssertTrue(alert_btn_cancel_ev_logJsons.count == 0); // 不需要有该按钮的点击曝光，因为按钮曝光等同于 alert 的 pv

    page_alert_node = [self _findNodeBySPM:@"page_alert" inVTree:VTree];
    EventTracingVTreeNode *alert_node = [self _findNodeBySPM:alert_spm inVTree:VTree];
    EventTracingVTreeNode *alert_btn_ok_node = [self _findNodeBySPM:alert_ok_btn_spm inVTree:VTree];
    EventTracingVTreeNode *alert_btn_cancel_node = [self _findNodeBySPM:alert_cancel_btn_spm inVTree:VTree];

    // 自动挂载，子页面挂载到当前根页面名下(`page_alert`)
    // 根页面范围内 actseq +1
    // 全局 pgstep +1
    XCTAssertNotNil(alert_node);
    XCTAssertEqual(alert_node.actseq, page_alert_node.actseq);     // 自增的其实是 rootpage.actseq
    XCTAssertEqual(alert_node.actseq, actseq + 1);
    actseq = alert_node.actseq;
    XCTAssertEqual(alert_node.pgstep, page_alert_node.pgstep + 1);

    XCTAssertNotNil(alert_btn_ok_node);
    XCTAssertTrue(alert_btn_ok_node.visible);
    XCTAssertTrue(!CGRectEqualToRect(alert_btn_ok_node.visibleRect, CGRectZero));
    XCTAssertTrue(alert_btn_ok_node.buildinEventLogDisableStrategy & ETNodeBuildinEventLogDisableStrategyImpress);  // 禁止了曝光埋点
    XCTAssertTrue([alert_btn_ok_node.nodeParams.allKeys containsObject:@"alert_btn_ok_p_key"]);     // 对象参数

    XCTAssertNotNil(alert_btn_cancel_node);
    XCTAssertTrue(alert_btn_cancel_node.visible);
    XCTAssertTrue(!CGRectEqualToRect(alert_btn_cancel_node.visibleRect, CGRectZero));
    XCTAssertTrue(alert_btn_cancel_node.buildinEventLogDisableStrategy & ETNodeBuildinEventLogDisableStrategyImpress);  // 禁止了曝光埋点
    XCTAssertTrue([alert_btn_cancel_node.nodeParams.allKeys containsObject:@"alert_btn_cancel_p_key"]);     // 对象参数
    
    // 点击 OK
    logComing = [EventTracingTestLogComing logComingWithRandomKey];
    [tester et_asyncTapViewWithAccessibilityLabel:@"OK"];
    ET_Test_WaitForTimeAtVTreeGenerateWithCondition(3, logComing, ^BOOL(EventTracingTestLogComing * _Nonnull logComing) {
        return [logComing fetchJsonLogsForEvent:ET_EVENT_ID_E_CLCK spm:alert_ok_btn_spm].count > 0;
    });
    
    VTree = logComing.lastVTree;
    NSArray<NSDictionary *> *alert_btn_ok_ec_logJsons = [logComing fetchJsonLogsForEvent:ET_EVENT_ID_E_CLCK spm:alert_ok_btn_spm];
    XCTAssertTrue(alert_btn_ok_ec_logJsons.count == 1);
    XCTAssertTrue([alert_btn_ok_ec_logJsons.firstObject[ET_REFER_KEY_ACTSEQ] integerValue] == actseq + 1);      // 点击事件，声明了 userForRefer ，则会做 actseq ++
    actseq ++;
    
    page_alert_node = [self _findNodeBySPM:@"page_alert" inVTree:VTree];
    XCTAssertNotNil(page_alert_node);
    XCTAssertEqual(page_alert_node.actseq, actseq);
    
    [tester tapViewWithAccessibilityLabel:@"Back"];
}

- (void)testSheet {
    EventTracingTestLogComing *logComing = [EventTracingTestLogComing logComingWithRandomKey];
    [tester et_asyncTapViewWithAccessibilityLabel:@"系统Alert"];
    
    NSString *show_sheet_btn_spm = @"btn_show_sheet|page_alert";
    ET_Test_WaitForTimeAtVTreeGenerateWithCondition(3, logComing, ^BOOL(EventTracingTestLogComing * _Nonnull logComing) {
        return [logComing fetchJsonLogsForEvent:ET_EVENT_ID_E_VIEW spm:show_sheet_btn_spm].count > 0;
    });
    ET_Test_WaitForTime(0.5);
    
    EventTracingVTree *VTree = logComing.lastVTree;
    
    // 点击 show sheet 按钮
    [tester et_asyncTapViewWithAccessibilityLabel:@"ShowSheet"];
    ET_Test_WaitForTimeAtVTreeGenerateWithCondition(3, logComing, ^BOOL(EventTracingTestLogComing * _Nonnull logComing) {
        return [logComing fetchJsonLogsForEvent:ET_EVENT_ID_E_CLCK spm:show_sheet_btn_spm].count > 0;
    });
    
    ET_Test_WaitForTime(0.5);
    
    NSString *sheet_spm = @"page_float_sheet|page_alert";
    NSString *handspme_btn_spm = @"btn_handsome_boy:1|page_float_sheet|page_alert";
    NSString *cancel_btn_spm = @"btn_cancel:2|page_float_sheet|page_alert";
 
    NSArray<NSDictionary *> *sheet_pv_logJsons = [logComing fetchJsonLogsForEvent:ET_EVENT_ID_P_VIEW spm:sheet_spm];
    NSArray<NSDictionary *> *sheet_btn_handsome_ev_logJsons = [logComing fetchJsonLogsForEvent:ET_EVENT_ID_E_VIEW spm:handspme_btn_spm];
    NSArray<NSDictionary *> *sheet_btn_cancel_ev_logJsons = [logComing fetchJsonLogsForEvent:ET_EVENT_ID_E_VIEW spm:cancel_btn_spm];

    XCTAssertTrue(sheet_pv_logJsons.count == 1);
    XCTAssertTrue(sheet_btn_handsome_ev_logJsons.count == 0);     // 不需要有该按钮的点击曝光，因为按钮曝光等同于 alert 的 pv
    XCTAssertTrue(sheet_btn_cancel_ev_logJsons.count == 0); // 不需要有该按钮的点击曝光，因为按钮曝光等同于 alert 的 pv
    
    VTree = logComing.lastVTree;
    EventTracingVTreeNode *sheet_node = [self _findNodeBySPM:sheet_spm inVTree:VTree];
    EventTracingVTreeNode *sheet_btn_handsome_node = [self _findNodeBySPM:handspme_btn_spm inVTree:VTree];
    EventTracingVTreeNode *sheet_btn_cancel_node = [self _findNodeBySPM:cancel_btn_spm inVTree:VTree];
    
    XCTAssertNotNil(sheet_node);

    XCTAssertNotNil(sheet_btn_handsome_node);
    XCTAssertTrue(sheet_btn_handsome_node.visible);
    XCTAssertTrue(!CGRectEqualToRect(sheet_btn_handsome_node.visibleRect, CGRectZero));
    XCTAssertTrue(sheet_btn_handsome_node.buildinEventLogDisableStrategy & ETNodeBuildinEventLogDisableStrategyImpress);  // 禁止了曝光埋点
    XCTAssertTrue([sheet_btn_handsome_node.nodeParams.allKeys containsObject:@"sheet_btn_handsome_boy_p_key"]);     // 对象参数

    XCTAssertNotNil(sheet_btn_cancel_node);
    XCTAssertTrue(sheet_btn_cancel_node.visible);
    XCTAssertTrue(!CGRectEqualToRect(sheet_btn_cancel_node.visibleRect, CGRectZero));
    XCTAssertTrue(sheet_btn_cancel_node.buildinEventLogDisableStrategy & ETNodeBuildinEventLogDisableStrategyImpress);  // 禁止了曝光埋点
    XCTAssertTrue([sheet_btn_cancel_node.nodeParams.allKeys containsObject:@"sheet_btn_cancel_p_key"]);     // 对象参数
    
    // 点击 OK
    logComing = [EventTracingTestLogComing logComingWithRandomKey];
    [tester et_asyncTapViewWithAccessibilityLabel:@"你很帅"];
    ET_Test_WaitForTimeAtVTreeGenerateWithCondition(3, logComing, ^BOOL(EventTracingTestLogComing * _Nonnull logComing) {
        return [logComing fetchJsonLogsForEvent:ET_EVENT_ID_E_CLCK spm:handspme_btn_spm].count > 0;
    });
    
    VTree = logComing.lastVTree;
    NSArray<NSDictionary *> *sheet_btn_handsome_ec_logJsons = [logComing fetchJsonLogsForEvent:ET_EVENT_ID_E_CLCK spm:handspme_btn_spm];
    XCTAssertTrue(sheet_btn_handsome_ec_logJsons.count == 1);
    XCTAssertTrue(![sheet_btn_handsome_ec_logJsons.firstObject.allKeys containsObject:ET_REFER_KEY_ACTSEQ]);      // 点击事件，主动声明了不自增 actseq
    
    /// MARK: 特殊之处 => Sheet 点击按钮的时候，立刻打了 _ec 埋点，但是 Alert 是先消失 Alert 视图，然后再再出发 handler 事件，所以这里需要延后，以留时间给重新构建VTree，从而产生新的 page_alert Node对象
    ET_Test_WaitForTime(0.5);
    VTree = logComing.lastVTree;
    
    EventTracingVTreeNode *page_alert_node = [self _findNodeBySPM:@"page_alert" inVTree:VTree];
    XCTAssertNotNil(page_alert_node);
    
    [tester tapViewWithAccessibilityLabel:@"Back"];
}

- (EventTracingVTreeNode *)_findNodeBySPM:(NSString *)spm inVTree:(EventTracingVTree *)VTree {
    __block EventTracingVTreeNode *ret;
    [VTree.rootNode.subNodes et_enumerateObjectsUsingBlock:^NSArray<EventTracingVTreeNode *> * _Nonnull(EventTracingVTreeNode * _Nonnull node, BOOL * _Nonnull stop) {
        if([node.spm isEqualToString:spm]) {
            ret = node;
            *stop = YES;
        }
        return node.subNodes;
    }];
    
    return ret;
}

@end
