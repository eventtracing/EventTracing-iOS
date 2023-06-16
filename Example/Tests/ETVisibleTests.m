//
//  ETObjectVisibleTests.m
//  EventTracing-iOS_Tests
//
//  Created by dl on 2022/12/14.
//  Copyright © 2022 9446796. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "EventTracingDefines.h"

@interface ETVisibleTests : KIFTestCase
@end

@implementation ETVisibleTests

- (void)beforeAll {
    [tester tapViewWithAccessibilityLabel:@"Home"];
}

- (void)setUp {
    self.continueAfterFailure = NO;
}

- (void)afterAll {
    [tester tapViewWithAccessibilityLabel:@"Home"];
}

- (void)afterEach {
    [tester tapViewWithAccessibilityLabel:@"Home"];
}

- (void)testVisible {
    EventTracingTestLogComing *logComing = [EventTracingTestLogComing logComingWithRandomKey];
    [tester ne_et_asyncTapViewWithAccessibilityLabel:@"可见区域"];
    
    NSString *label_3_spm = @"label_3|page_visible";
    NE_ET_Test_WaitForTimeAtVTreeGenerateWithCondition(3, logComing, ^BOOL(EventTracingTestLogComing * _Nonnull logComing) {
        return [logComing fetchJsonLogsForEvent:NE_ET_EVENT_ID_E_VIEW spm:label_3_spm].count > 0;
    });
    NE_ET_Test_WaitForTime(0.5);
    
    NSArray<NSDictionary *> *l1_ev_logJsons = [logComing fetchJsonLogsForEvent:NE_ET_EVENT_ID_E_VIEW spm:@"label_1|page_visible"];
    NSArray<NSDictionary *> *l2_ev_logJsons = [logComing fetchJsonLogsForEvent:NE_ET_EVENT_ID_E_VIEW spm:@"label_2|page_visible"];
    NSArray<NSDictionary *> *l3_ev_logJsons = [logComing fetchJsonLogsForEvent:NE_ET_EVENT_ID_E_VIEW spm:@"label_3|page_visible"];
    NSArray<NSDictionary *> *l4_ev_logJsons = [logComing fetchJsonLogsForEvent:NE_ET_EVENT_ID_E_VIEW spm:@"label_4|page_visible"];
    
    NEEventTracingVTree *VTree = logComing.lastVTree;
    
    // 不可见: 被父节点缩小后的可见区域裁剪掉了
    XCTAssertTrue(l1_ev_logJsons.count == 0);
    NEEventTracingVTreeNode *l1_node = [self _findNodeByOid:@"label_1" inVTree:VTree];
    XCTAssertNotNil(l1_node);
    XCTAssertTrue(!l1_node.visible);
    XCTAssertTrue([l1_node.spm isEqualToString:@"label_1|page_visible"]);
    XCTAssertTrue(CGRectEqualToRect(l1_node.visibleRect, CGRectZero));
    // 最大曝光比例
    XCTAssertTrue(fabs(l1_node.impressMaxRatio) < 0.001);
    
    // 可见: 虽然被父节点裁剪了，但是可见区域仍然可见
    XCTAssertTrue(l2_ev_logJsons.count == 1);
    NEEventTracingVTreeNode *l2_node = [self _findNodeByOid:@"label_2" inVTree:VTree];
    XCTAssertNotNil(l2_node);
    XCTAssertTrue(l2_node.visible);
    XCTAssertTrue([l2_node.spm isEqualToString:@"label_2|page_visible"]);
    CGRect originalRectOnScreen = [l2_node.view convertRect:l2_node.view.bounds toView:nil];
    XCTAssertTrue(CGRectContainsRect(originalRectOnScreen, l2_node.visibleRect));
    CGFloat originalRectOnScreenArea = originalRectOnScreen.size.width * originalRectOnScreen.size.height;
    CGFloat visibleRectArea = l2_node.visibleRect.size.width * l2_node.visibleRect.size.height;
    XCTAssertTrue(originalRectOnScreenArea > visibleRectArea);
    // 最大曝光比例
    XCTAssertTrue(fabs(l2_node.impressMaxRatio - 0.4) < 0.001);
    
    // 完整可见
    XCTAssertTrue(l3_ev_logJsons.count == 1);
    NEEventTracingVTreeNode *l3_node = [self _findNodeByOid:@"label_3" inVTree:VTree];
    XCTAssertNotNil(l3_node);
    XCTAssertTrue(l3_node.visible);
    XCTAssertTrue([l3_node.spm isEqualToString:@"label_3|page_visible"]);
    originalRectOnScreen = [l3_node.view convertRect:l3_node.view.bounds toView:nil];
    XCTAssertTrue(CGRectEqualToRect(originalRectOnScreen, l3_node.visibleRect));
    
    // 完整可见
    XCTAssertTrue(l4_ev_logJsons.count == 1);
    NEEventTracingVTreeNode *l4_node = [self _findNodeByOid:@"label_4" inVTree:VTree];
    XCTAssertNotNil(l4_node);
    XCTAssertTrue(l4_node.visible);
    XCTAssertTrue([l4_node.spm isEqualToString:@"label_4|page_visible"]);
    
    
    // MARK: 曝光时长
    // 1秒后返回
    [tester waitForTimeInterval:1];
    //返回
    [tester tapViewWithAccessibilityLabel:@"曙光埋点"];
    {
        [tester waitForTimeInterval:0.1];
        NSArray<NSDictionary *> *l2_ev_logJsons = [logComing fetchJsonLogsForEvent:NE_ET_EVENT_ID_E_VIEW_END spm:@"label_2|page_visible"];
        XCTAssertTrue([l2_ev_logJsons.firstObject[NE_ET_REFER_KEY_DURATION] integerValue] > 1000);
    }
    [tester tapViewWithAccessibilityLabel:@"可见区域"];
}

- (void)testCustomControlVisibleOnLabel_3 {
    EventTracingTestLogComing *logComing = [EventTracingTestLogComing logComingWithRandomKey];
    [tester ne_et_asyncTapViewWithAccessibilityLabel:@"可见区域"];
    
    NSString *label_3_spm = @"label_3|page_visible";
    NE_ET_Test_WaitForTimeAtVTreeGenerateWithCondition(3, logComing, ^BOOL(EventTracingTestLogComing * _Nonnull logComing) {
        return [logComing fetchJsonLogsForEvent:NE_ET_EVENT_ID_E_VIEW spm:label_3_spm].count > 0;
    });
    NE_ET_Test_WaitForTime(0.5);
    
    // 逻辑不可见 => _ed
    logComing = [EventTracingTestLogComing logComingWithRandomKey];
    [tester ne_et_asyncTapViewWithAccessibilityLabel:@"LogicalVisible"];
    NE_ET_Test_WaitForTimeAtVTreeGenerateWithCondition(1, logComing, ^BOOL(EventTracingTestLogComing * _Nonnull logComing) {
        return [logComing fetchJsonLogsForEvent:NE_ET_EVENT_ID_E_VIEW_END spm:label_3_spm].count > 0;
    });
    
    // 逻辑可见 => _ev
    logComing = [EventTracingTestLogComing logComingWithRandomKey];
    [tester ne_et_asyncTapViewWithAccessibilityLabel:@"LogicalVisible"];
    NE_ET_Test_WaitForTimeAtVTreeGenerateWithCondition(1, logComing, ^BOOL(EventTracingTestLogComing * _Nonnull logComing) {
        return [logComing fetchJsonLogsForEvent:NE_ET_EVENT_ID_E_VIEW spm:label_3_spm].count > 0;
    });
    
    // 重新曝光 => _ev
    logComing = [EventTracingTestLogComing logComingWithRandomKey];
    [tester ne_et_asyncTapViewWithAccessibilityLabel:@"SetNeedImpress"];
    NE_ET_Test_WaitForTimeAtVTreeGenerateWithCondition(1, logComing, ^BOOL(EventTracingTestLogComing * _Nonnull logComing) {
        return [logComing fetchJsonLogsForEvent:NE_ET_EVENT_ID_E_VIEW spm:label_3_spm].count > 0;
    });
    
    // hidden => _ed
    logComing = [EventTracingTestLogComing logComingWithRandomKey];
    [tester ne_et_asyncTapViewWithAccessibilityLabel:@"Hidden"];
    NE_ET_Test_WaitForTimeAtVTreeGenerateWithCondition(1, logComing, ^BOOL(EventTracingTestLogComing * _Nonnull logComing) {
        return [logComing fetchJsonLogsForEvent:NE_ET_EVENT_ID_E_VIEW_END spm:label_3_spm].count > 0;
    });
    
    // !hidden => _ev
    logComing = [EventTracingTestLogComing logComingWithRandomKey];
    [tester ne_et_asyncTapViewWithAccessibilityLabel:@"Hidden"];
    NE_ET_Test_WaitForTimeAtVTreeGenerateWithCondition(1, logComing, ^BOOL(EventTracingTestLogComing * _Nonnull logComing) {
        return [logComing fetchJsonLogsForEvent:NE_ET_EVENT_ID_E_VIEW spm:label_3_spm].count > 0;
    });
    
    // alpha == 0 => _ed
    logComing = [EventTracingTestLogComing logComingWithRandomKey];
    [tester ne_et_asyncTapViewWithAccessibilityLabel:@"Alpha"];
    NE_ET_Test_WaitForTimeAtVTreeGenerateWithCondition(1, logComing, ^BOOL(EventTracingTestLogComing * _Nonnull logComing) {
        return [logComing fetchJsonLogsForEvent:NE_ET_EVENT_ID_E_VIEW_END spm:label_3_spm].count > 0;
    });
    
    // alpha != 0 => _ev
    logComing = [EventTracingTestLogComing logComingWithRandomKey];
    [tester ne_et_asyncTapViewWithAccessibilityLabel:@"Alpha"];
    NE_ET_Test_WaitForTimeAtVTreeGenerateWithCondition(1, logComing, ^BOOL(EventTracingTestLogComing * _Nonnull logComing) {
        return [logComing fetchJsonLogsForEvent:NE_ET_EVENT_ID_E_VIEW spm:label_3_spm].count > 0;
    });
}

- (void)testShowFloatView {
    EventTracingTestLogComing *logComing = [EventTracingTestLogComing logComingWithRandomKey];
    [tester ne_et_asyncTapViewWithAccessibilityLabel:@"可见区域"];
    
    NSString *label_3_spm = @"label_3|page_visible";
    NE_ET_Test_WaitForTimeAtVTreeGenerateWithCondition(3, logComing, ^BOOL(EventTracingTestLogComing * _Nonnull logComing) {
        return [logComing fetchJsonLogsForEvent:NE_ET_EVENT_ID_E_VIEW spm:label_3_spm].count > 0;
    });
    NE_ET_Test_WaitForTime(0.5);
    
    logComing = [EventTracingTestLogComing logComingWithRandomKey];
    [tester ne_et_asyncTapViewWithAccessibilityLabel:@"Show"];
    NSString *floatViewSPM = @"page_float_example_0|page_visible";
    NE_ET_Test_WaitForTimeAtVTreeGenerateWithCondition(3, logComing, ^BOOL(EventTracingTestLogComing * _Nonnull logComing) {
        return [logComing fetchJsonLogsForEvent:NE_ET_EVENT_ID_P_VIEW spm:floatViewSPM].count > 0;
    });
    
    NEEventTracingVTree *VTree = logComing.lastVTree;
    NSString *floatViewCloseBtnSPM = @"btn_close|page_float_example_0|page_visible";
    NSString *l4_spm = @"label_4|page_visible";
    NSArray<NSDictionary *> *float_pv_logJsons = [logComing fetchJsonLogsForEvent:NE_ET_EVENT_ID_P_VIEW spm:floatViewSPM];
    NSArray<NSDictionary *> *float_close_btn_ev_logJsons = [logComing fetchJsonLogsForEvent:NE_ET_EVENT_ID_E_VIEW spm:floatViewCloseBtnSPM];
    
    XCTAssertTrue(float_pv_logJsons.count == 1);                // 浮层 page 曝光开始
    XCTAssertTrue(float_close_btn_ev_logJsons.count == 1);      // 浮层中的 关闭按钮 曝光开始
    
    // l4 被遮挡，曝光结束 => 此阶段时间内，没有曝光开始，有曝光结束
    NSArray<NSDictionary *> *l4_ev_logJsons = [logComing fetchJsonLogsForEvent:NE_ET_EVENT_ID_E_VIEW spm:l4_spm];
    NSArray<NSDictionary *> *l4_ed_logJsons = [logComing fetchJsonLogsForEvent:NE_ET_EVENT_ID_E_VIEW_END spm:l4_spm];
    XCTAssertTrue(l4_ev_logJsons.count == 0);
    XCTAssertTrue(l4_ed_logJsons.count == 1);
    
    NEEventTracingVTreeNode *root_page_node = [self _findNodeByOid:@"page_visible" inVTree:VTree];
    NEEventTracingVTreeNode *float_page_node = [self _findNodeByOid:@"page_float_example_0" inVTree:VTree];
    NEEventTracingVTreeNode *l4_node = [self _findNodeByOid:@"label_4" inVTree:VTree];
    NEEventTracingVTreeNode *l3_node = [self _findNodeByOid:@"label_3" inVTree:VTree];
    
    XCTAssertEqual(float_page_node.parentNode, root_page_node);
    XCTAssertTrue(float_page_node.visible);
    
    XCTAssertNotNil(l3_node);
    XCTAssertTrue(l3_node.visible);
    CGRect l3_node_boundsOnScreen = [l3_node.view convertRect:l3_node.view.bounds toView:nil];
    XCTAssertTrue(CGRectIntersectsRect(l3_node_boundsOnScreen, l3_node.visibleRect));       // 浮层跟 l3 有重合部分，但是 l3 仍然可见
    
    CGRect l4_node_boundsOnScreen = [l4_node.view convertRect:l4_node.view.bounds toView:nil];
    XCTAssertTrue(CGRectContainsRect(float_page_node.visibleRect, l4_node_boundsOnScreen));
    XCTAssertNotNil(l4_node);
    XCTAssertTrue(l4_node.blockedBySubPage);  // 被page节点(浮层)遮挡了
    XCTAssertTrue(!l4_node.visible);            // 浮层完全遮挡了 l4
    
    NE_ET_Test_WaitForTime(0.5);
    
    logComing = [EventTracingTestLogComing logComingWithRandomKey];
    [tester ne_et_asyncTapViewWithAccessibilityLabel:@"Close"];
    NSString *label_4_spm = @"label_4|page_visible";
    NE_ET_Test_WaitForTimeAtVTreeGenerateWithCondition(3, logComing, ^BOOL(EventTracingTestLogComing * _Nonnull logComing) {
        return [logComing fetchJsonLogsForEvent:NE_ET_EVENT_ID_E_VIEW spm:label_4_spm].count > 0;
    });
    VTree = logComing.lastVTree;
    l4_ev_logJsons = [logComing fetchJsonLogsForEvent:NE_ET_EVENT_ID_E_VIEW spm:l4_spm];
    XCTAssertTrue(l4_ev_logJsons.count == 1);
    l4_node = [self _findNodeByOid:@"label_4" inVTree:VTree];
    XCTAssertNotNil(l4_node);
    XCTAssertTrue(!l4_node.blockedBySubPage);
    XCTAssertTrue(l4_node.visible);
}

- (NEEventTracingVTreeNode *)_findNodeByOid:(NSString *)oid inVTree:(NEEventTracingVTree *)VTree {
    __block NEEventTracingVTreeNode *ret;
    [VTree.rootNode.subNodes ne_et_enumerateObjectsUsingBlock:^NSArray<NEEventTracingVTreeNode *> * _Nonnull(NEEventTracingVTreeNode * _Nonnull node, BOOL * _Nonnull stop) {
        if([node.oid isEqualToString:oid]) {
            ret = node;
            *stop = YES;
        }
        return node.subNodes;
    }];
    
    return ret;
}

@end
