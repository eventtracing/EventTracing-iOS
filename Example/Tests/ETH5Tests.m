//
//  ETH5Tests.m
//  EventTracing-iOS_Tests
//
//  Created by dl on 2022/12/28.
//  Copyright © 2022 9446796. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "EventTracingDefines.h"

@interface ETH5Tests : KIFTestCase
@end

@implementation ETH5Tests

- (void)setUp {
    self.continueAfterFailure = NO;
}

- (void)afterAll {
    [tester tapViewWithAccessibilityLabel:@"Home"];
}

- (void)afterEach {
    [tester tapViewWithAccessibilityLabel:@"Home"];
}

- (void)testExample {
    EventTracingTestLogComing *logComing = [EventTracingTestLogComing logComingWithRandomKey];
    [tester tapViewWithAccessibilityLabel:@"H5 页"];
    
    NE_ET_Test_WaitForTime(0.5);
//    NSString *script = [NSString stringWithFormat:@"document.querySelector('#btn_check_avaiable').dispatchEvent(new MouseEvent('mousedown', {}))"];
    NSString *script = [NSString stringWithFormat:@"simulate_click('btn_check_avaiable')"];
    [[logComing currentShowingWebView] evaluateJavaScript:script];
    
    NE_ET_Test_WaitForTime(0.5);
    script = [NSString stringWithFormat:@"simulate_click('btn_et_test')"];
    [[logComing currentShowingWebView] evaluateJavaScript:script];
    
    NE_ET_Test_WaitForTime(0.5);
}

@end
