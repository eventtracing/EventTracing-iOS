//
//  EventTracingTestUsefullFuncs.h
//  EventTracing-iOS_Example
//
//  Created by dl on 2022/12/13.
//  Copyright © 2022 9446796. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EventTracingTestLogComing.h"

NS_ASSUME_NONNULL_BEGIN
@class XCTestExpectation;
typedef void(^NE_ET_Test_Wait_ExecBlock)(XCTestExpectation *expectation);
typedef BOOL(^NE_ET_Test_Wait_AtVTreeGenerateConditionBlock)(EventTracingTestLogComing *logComing);

FOUNDATION_EXTERN void NE_ET_Test_WaitForTimeExecBlock(NSTimeInterval timeout, NE_ET_Test_Wait_ExecBlock execBlock);
FOUNDATION_EXTERN void NE_ET_Test_WaitForTime(NSTimeInterval timeout);

/// MARK: 以下都是基于上述俩进行的扩展
__attribute__((overloadable))
FOUNDATION_EXTERN void NE_ET_Test_WaitForTimeAtVTreeGenerateWithCondition(NSTimeInterval timeout,
                                                                       NE_ET_Test_Wait_AtVTreeGenerateConditionBlock condition);

FOUNDATION_EXTERN void NE_ET_Test_WaitForTimeAtVTreeGenerateWithCondition(NSTimeInterval timeout,
                                                                       EventTracingTestLogComing *logComing,
                                                                       NE_ET_Test_Wait_AtVTreeGenerateConditionBlock condition);

NS_ASSUME_NONNULL_END
