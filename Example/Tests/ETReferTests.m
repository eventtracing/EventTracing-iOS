//
//  ETReferTests.m
//  EventTracing-iOS_Tests
//
//  Created by 熊勋泉 on 2022/12/15.
//  Copyright © 2022 9446796. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "EventTracingDefines.h"

@interface ETReferTests : KIFTestCase

@end

@implementation ETReferTests

- (void)beforeAll {
    [tester tapViewWithAccessibilityLabel:@"Home"];
}

- (void)setUp {
    self.continueAfterFailure = NO;
}

- (void)beforeEach {
    // 每个测试用例执行前
}

- (void)afterAll {
    // 所有测试用例执行后
    // [tester tapViewWithAccessibilityLabel:@"List"];
}

- (void)afterEach {
    // 每个测试用例执行后
}

#define PUSH_PID(_PID) \
[pgrefer_list et_pushObject:[logComing fetchPageInfoValueForEvent:ET_EVENT_ID_P_VIEW spm:_PID oid:_PID key:ET_REFER_KEY_PGREFER]]; \
[psrefer_list et_pushObject:[logComing fetchPageInfoValueForEvent:ET_EVENT_ID_P_VIEW spm:_PID oid:_PID key:ET_REFER_KEY_PSREFER]]; \
[pgstep_list et_pushObject:[logComing fetchPageInfoValueForEvent:ET_EVENT_ID_P_VIEW spm:_PID oid:_PID key:ET_REFER_KEY_PGSTEP]];

#define POP_PID(_PID) \
[pgrefer_list et_popObject]; \
[pgrefer_list et_pushObject:[logComing fetchPageInfoValueForEvent:ET_EVENT_ID_P_VIEW spm:_PID oid:_PID key:ET_REFER_KEY_PGREFER]]; \
[psrefer_list et_popObject]; \
[pgstep_list et_pushObject:[logComing fetchPageInfoValueForEvent:ET_EVENT_ID_P_VIEW spm:_PID oid:_PID key:ET_REFER_KEY_PGSTEP]];

- (void)testRefer {
    /// MARK: 开始之前，先行记录下初始的 pgstep
    NSInteger pgstep_value = [[EventTracingEngine sharedInstance] context].pgstep;
    
    NSDictionary * logInfo;
    NSString * pid0 = @"refer_page_0";
    NSString * pid1 = @"refer_page_1";
    NSString * pid2 = @"refer_page_2";
    NSString * exitBtn = @"exit_btn";
    NSString * pushBtn = @"push_btn";
    NSString * pushBridgeBtn = @"push_bridge_btn";
    
    NSMutableArray<NSString *> * pgrefer_list = [NSMutableArray array];
    NSMutableArray<NSString *> * psrefer_list = [NSMutableArray array];
    NSMutableArray<NSNumber *> * pgstep_list = [NSMutableArray array];
    
    EventTracingTestLogComing *logComing = [EventTracingTestLogComing logComingWithRandomKey];
    NSString * const kCellEntrySpm = @"TableCell:4|mod_list_table|mod_virtual_parent_of_table|mod_list_page";
    // 打开页面 page_0, pgstep ++
    {
        [tester et_asyncTapViewWithAccessibilityLabel:@"链路追踪"];
        ET_Test_WaitForTimeAtVTreeGenerateWithCondition(3, logComing, ^BOOL(EventTracingTestLogComing * _Nonnull logComing) {
            return [logComing fetchJsonLogsForEvent:ET_EVENT_ID_E_CLCK spm:kCellEntrySpm].count > 0;
        });
        PUSH_PID(pid0);
        pgstep_value ++;
    }
    
    // MARK: 链路追踪, refer 验证
    {
        NSArray<NSString *> * multiRefers = [logComing fetchMultirefersForEvent:ET_EVENT_ID_P_VIEW spm:pid0];
        XCTAssertTrue(multiRefers.count > 0);
        XCTAssertTrue([self checkList1:multiRefers prefixEqualList2:psrefer_list]);
        [self checkList1:multiRefers prefixEqualList2:pgrefer_list];
        XCTAssertTrue(pgstep_list[0].integerValue == pgstep_value);
    }
    
    // 打开页面 page_1, pgstep ++
    {
        [tester tapViewWithAccessibilityLabel:@"PresentVC"];
        PUSH_PID(pid1);
        pgstep_value ++;
    }
    
    logInfo = [logComing fetchLastJsonLogForEvent:ET_EVENT_ID_P_VIEW spm:pid1];
    
    // 当前启动的sid
    NSString *sessionID = logInfo[ET_REFER_KEY_SESSID];
    // 上次启动的sid
    NSString *sidRefer = logInfo[ET_REFER_KEY_SIDREFER];
    // 上次存储的sid
    NSString *lastSaveSid = [[NSUserDefaults standardUserDefaults] objectForKey:@"session_id"];
    [[NSUserDefaults standardUserDefaults] setObject:sessionID forKey:@"session_id"];
    XCTAssertTrue(!sidRefer || ![sessionID isEqualToString:sidRefer]);
    NSArray<NSString *> * components = [sessionID componentsSeparatedByString:@"#"];
    
    NSString * version = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
    NSString * shortVer = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    XCTAssertTrue(components.count == 4
                  && components[0].integerValue > 1670000000000 //时间戳
                  && components[1].integerValue > 99 //3位随机数
                  && components[1].integerValue < 1000
                  && [components[2] isEqualToString:shortVer] //short_ver
                  && [components[3] isEqualToString:version]); //version
    
    {
        NSArray * multiRefers = [logComing fetchMultirefersForEvent:ET_EVENT_ID_P_VIEW spm:pid1];
        XCTAssertTrue([self checkList1:multiRefers prefixEqualList2:psrefer_list]);
        [self checkList1:multiRefers prefixEqualList2:pgrefer_list];
        XCTAssertTrue(pgstep_list[0].integerValue == pgstep_value);
    }
    
    // 打开页面 page_2, pgstep ++
    {
        [tester tapViewWithAccessibilityLabel:@"PushVC"];
        PUSH_PID(pid2);
        pgstep_value ++;
    }
    
    {
        NSArray * multiRefers = [logComing fetchMultirefersForEvent:ET_EVENT_ID_P_VIEW spm:pid2];
        XCTAssertTrue([self checkList1:multiRefers prefixEqualList2:psrefer_list]);
        [self checkList1:multiRefers prefixEqualList2:pgrefer_list];
        XCTAssertTrue(pgstep_list[0].integerValue == pgstep_value);
    }
    
    // MARK: Exit => p1
    // 退回到页面 page_1, pgstep ++
    {
        [tester tapViewWithAccessibilityLabel:@"ExitVC"];
        POP_PID(pid1);
        pgstep_value ++;
    }
    
    // MARK: 校验 ec 和 pgrefer 是否一致
    {
        NSDictionary * ec_info = [logComing fetchLastJsonLogForEvent:ET_EVENT_ID_E_CLCK oid:exitBtn];
        XCTAssertTrue(ec_info.count > 0);
        NSString * ec_spm = ec_info[ET_REFER_KEY_SPM]; // 获取最近1次退出按钮的spm
        XCTAssertTrue(ec_spm.length > 0);
        // 获取 pgrefer
        NSString * pgrefer = [logComing fetchPageInfoValueForEvent:ET_EVENT_ID_P_VIEW spm:pid1 oid:pid1 key:ET_REFER_KEY_PGREFER];
        id<EventTracingFormattedRefer> referFormat = ET_FormattedReferParseFromReferString(pgrefer);
        XCTAssertTrue([referFormat.spm isEqualToString:ec_spm]);
        XCTAssertTrue(referFormat.pgstep == pgstep_value -1);
    }
    logInfo = [logComing fetchLastJsonLogForEvent:ET_EVENT_ID_P_VIEW spm:pid1];
    
    // MARK: 再次曝光 p1
    {
        NSArray * multiRefers = [logComing fetchMultirefersForEvent:ET_EVENT_ID_P_VIEW spm:pid1];
        XCTAssertTrue([self checkList1:multiRefers prefixEqualList2:psrefer_list]);
        XCTAssertTrue(pgstep_list[0].integerValue == pgstep_value);
    }
    
    // MARK: Push => p2
    // 再打开页面 page_2, pgstep ++
    {
        [tester tapViewWithAccessibilityLabel:@"PushVC"];
        pgstep_value ++;
        PUSH_PID(pid2);
    }
    
    // MARK: 校验 ec 和 pgrefer 是否一致
    {
        NSDictionary * ec_info = [logComing fetchLastJsonLogForEvent:ET_EVENT_ID_E_CLCK oid:pushBtn];
        XCTAssertTrue(ec_info.count > 0);
        NSString * ec_spm = ec_info[ET_REFER_KEY_SPM]; // 获取最近1次退出按钮的spm
        XCTAssertTrue(ec_spm.length > 0);
        // 获取 pgrefer
        NSString * pgrefer = [logComing fetchPageInfoValueForEvent:ET_EVENT_ID_P_VIEW spm:pid2 oid:pid2 key:ET_REFER_KEY_PGREFER];
        id<EventTracingFormattedRefer> referFormat = ET_FormattedReferParseFromReferString(pgrefer);
        XCTAssertTrue([referFormat.spm isEqualToString:ec_spm]);
        XCTAssertTrue(referFormat.pgstep == pgstep_value - 1);
    }
    
    {
        NSArray * multiRefers = [logComing fetchMultirefersForEvent:ET_EVENT_ID_P_VIEW spm:pid2];
        XCTAssertTrue([self checkList1:multiRefers prefixEqualList2:psrefer_list]);
        XCTAssertTrue(pgstep_list[0].integerValue == pgstep_value);
    }
    
    // MARK: Exit => p1
    // 退回到页面 page_1, pgstep ++
    {
        [tester tapViewWithAccessibilityLabel:@"ExitVC"];
        POP_PID(pid1);
        pgstep_value ++;
    }
    
    // MARK: 校验 ec 和 pgrefer 是否一致
    {
        NSDictionary * ec_info = [logComing fetchLastJsonLogForEvent:ET_EVENT_ID_E_CLCK oid:exitBtn];
        XCTAssertTrue(ec_info.count > 0);
        NSString * ec_spm = ec_info[ET_REFER_KEY_SPM]; // 获取最近1次退出按钮的spm
        XCTAssertTrue(ec_spm.length > 0);
        // 获取 pgrefer
        NSString * pgrefer = [logComing fetchPageInfoValueForEvent:ET_EVENT_ID_P_VIEW spm:pid1 oid:pid1 key:ET_REFER_KEY_PGREFER];
        id<EventTracingFormattedRefer> referFormat = ET_FormattedReferParseFromReferString(pgrefer);
        XCTAssertTrue([referFormat.spm isEqualToString:ec_spm]);
        XCTAssertTrue(referFormat.pgstep == pgstep_value - 1);
    }
    // MARK: 再次曝光 p1
    {
        NSArray * multiRefers = [logComing fetchMultirefersForEvent:ET_EVENT_ID_P_VIEW spm:pid1];
        XCTAssertTrue([self checkList1:multiRefers prefixEqualList2:psrefer_list]);
        XCTAssertTrue(pgstep_list[0].integerValue == pgstep_value);
    }
    
    // MARK: Push => refer 静默
    NSString * b_pid2 = @"bridge_page_2";
    NSString * pid3 = @"refer_page_3";
    NSString * pid4 = @"refer_page_4";
    // 打开页面 bridge_page_2, pgstep ++
    {
        [tester tapViewWithAccessibilityLabel:@"PushBridgeVC"];
        PUSH_PID(b_pid2);
        pgstep_value ++;
    }
    
    // MARK: 校验 ec 和 pgrefer 是否一致
    {
        NSDictionary * ec_info = [logComing fetchLastJsonLogForEvent:ET_EVENT_ID_E_CLCK oid:pushBridgeBtn];
        XCTAssertTrue(ec_info.count > 0);
        NSString * ec_spm = ec_info[ET_REFER_KEY_SPM]; // 获取最近1次退出按钮的spm
        XCTAssertTrue(ec_spm.length > 0);
        // 获取 pgrefer
        NSString * pgrefer = [logComing fetchPageInfoValueForEvent:ET_EVENT_ID_P_VIEW spm:b_pid2 oid:b_pid2 key:ET_REFER_KEY_PGREFER];
        id<EventTracingFormattedRefer> referFormat = ET_FormattedReferParseFromReferString(pgrefer);
        XCTAssertTrue([referFormat.spm isEqualToString:ec_spm]);
        XCTAssertTrue(referFormat.pgstep == pgstep_value - 1);
        //multi refers
        NSArray * multiRefers = [logComing fetchMultirefersForEvent:ET_EVENT_ID_P_VIEW spm:b_pid2];
        XCTAssertTrue([self checkList1:multiRefers prefixEqualList2:psrefer_list]);
        XCTAssertTrue(pgstep_list[0].integerValue == pgstep_value);
    }
    
    // MARK: Push => p3
    // 打开页面 refer_page_3, pgstep ++
    {
        [tester tapViewWithAccessibilityLabel:@"PushVC"];
        PUSH_PID(pid3);
        pgstep_value ++;
    }
    
    // MARK: 校验 ec 和 pgrefer 是否一致
    {
        NSDictionary * ec_info = [logComing fetchLastJsonLogForEvent:ET_EVENT_ID_E_CLCK oid:@"bridge_push_btn"];
        XCTAssertTrue(ec_info.count > 0);
        NSString * ec_spm = ec_info[ET_REFER_KEY_SPM]; // 获取最近1次退出按钮的spm
        XCTAssertTrue(ec_spm.length > 0);
        // 获取 pgrefer
        NSString * pgrefer = [logComing fetchPageInfoValueForEvent:ET_EVENT_ID_P_VIEW spm:pid3 oid:pid3 key:ET_REFER_KEY_PGREFER];
        NSString * psrefer = [logComing fetchPageInfoValueForEvent:ET_EVENT_ID_P_VIEW spm:pid3 oid:pid3 key:ET_REFER_KEY_PSREFER];
        id<EventTracingFormattedRefer> referFormat = ET_FormattedReferParseFromReferString(pgrefer);
        XCTAssertTrue([psrefer isEqualToString:pgrefer]);
        // MARK: refer 降级到根节点
        XCTAssertTrue(ec_spm.length > 0
                      && ![referFormat.spm isEqualToString:ec_spm]
                      && [referFormat.spm isEqualToString:b_pid2]);
        XCTAssertTrue(referFormat.pgstep == pgstep_value - 1);
        //multi refers
        NSArray * multiRefers = [logComing fetchMultirefersForEvent:ET_EVENT_ID_P_VIEW spm:pid3];
        // 由于 b_pid2 设置了「静默」不参与 multirefers，因此这里 [bridge_push_btn|bridge_page_2] 并不会加入到 multiRefers
        XCTAssertTrue([self checkList1:multiRefers prefixEqualList2:psrefer_list]);
        XCTAssertTrue(pgstep_list[0].integerValue == pgstep_value);
    }
    // MARK: 校验 psrefer 忽略能力
    // MARK: Push => p4
    // 打开页面 refer_page_4, pgstep ++
    {
        [tester tapViewWithAccessibilityLabel:@"PushVC"];
        PUSH_PID(pid4);
        pgstep_value ++;
    }
    
    {
        NSDictionary * ec_info = [logComing fetchLastJsonLogForEvent:ET_EVENT_ID_E_CLCK oid:pushBtn];
        XCTAssertTrue(ec_info.count > 0);
        NSString * ec_spm = ec_info[ET_REFER_KEY_SPM]; // 获取最近1次退出按钮的spm
        XCTAssertTrue(ec_spm.length > 0);
        // 获取 pgrefer
        NSString * pgrefer = [logComing fetchPageInfoValueForEvent:ET_EVENT_ID_P_VIEW spm:pid4 oid:pid4 key:ET_REFER_KEY_PGREFER];
        id<EventTracingFormattedRefer> referFormat = ET_FormattedReferParseFromReferString(pgrefer);
        XCTAssertTrue([referFormat.spm isEqualToString:ec_spm]);
        XCTAssertTrue(referFormat.pgstep == pgstep_value - 1);
        //multi refers
        NSArray * multiRefers = [logComing fetchMultirefersForEvent:ET_EVENT_ID_P_VIEW spm:pid4];
        // 由于 b_pid2 设置了「静默」不参与 multirefers，因此这里 [bridge_push_btn|bridge_page_2] 并不会加入到 multiRefers
        XCTAssertTrue([self checkList1:multiRefers prefixEqualList2:psrefer_list]);
        XCTAssertTrue(pgstep_list[0].integerValue == pgstep_value);
    }
    
    [tester tapViewWithAccessibilityLabel:@"ExitVC"];
    [tester tapViewWithAccessibilityLabel:@"ExitVC"];
    [tester tapViewWithAccessibilityLabel:@"ExitVC"];
    [tester tapViewWithAccessibilityLabel:@"ExitVC"];
    [tester tapViewWithAccessibilityLabel:@"曙光埋点"];
}

- (BOOL)checkList1:(NSArray<NSString *> *)list1 prefixEqualList2:(NSArray<NSString *> *)list2 {
    if (list1.count < list2.count) {
        return NO;
    }
    __block BOOL result = YES;
    [list2 enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isEqualToString:list1[idx]] == NO) {
            result = NO;
            *stop = YES;
        }
    }];
    return result;
}
- (void)checkList1:(NSArray<NSString *> *)list1 containList2:(NSArray<NSString *> *)list2 {
    if (list1.count < list2.count) {
        XCTAssertTrue(false);
        return;
    }
    [list2 enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        XCTAssertTrue([list1 containsObject:obj]);
    }];
}

@end
