//
//  ETDiffTests.m
//  EventTracing-iOS_Tests
//
//  Created by dl on 2022/12/26.
//  Copyright © 2022 9446796. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "EventTracingDefines.h"

@interface ETDiffTestObj : NSObject<EventTracingDiffable>
@property(nonatomic, copy) NSString *name;
+ (instancetype)objWithName:(NSString *)name;
@end

@implementation ETDiffTestObj
+ (instancetype)objWithName:(NSString *)name {
    ETDiffTestObj *obj = [[ETDiffTestObj alloc] init];
    obj.name = name;
    return obj;
}
- (id<NSObject>)ne_et_diffIdentifier {
    return self.name;
}
- (BOOL)et_isEqualToDiffableObject:(id<EventTracingDiffable>)object {
    if (self == object) {
        return YES;
    }
    
    NSString *objectIdentifier = (NSString *)[(ETDiffTestObj *)object ne_et_diffIdentifier];
    if ([object isKindOfClass:self.class] && [objectIdentifier isEqualToString:(NSString *)[self ne_et_diffIdentifier]]) {
        return YES;
    }
    return NO;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@", self.name];
}
@end

@interface ETDiffTests : KIFTestCase
@property(nonatomic, strong) NSMutableArray<ETDiffTestObj *> *arr1;
@property(nonatomic, strong) NSMutableArray<ETDiffTestObj *> *arr2;
@end

NS_REQUIRES_NIL_TERMINATION
void _arr_add(NSMutableArray *arr, ...) {
    va_list args;
    va_start(args, arr);
    
    char *value;
    while((value = va_arg(args, char *))) {
        NSString *stringValue = [NSString stringWithCString:value encoding:NSUTF8StringEncoding];
        if (stringValue) {
            ETDiffTestObj *obj = [ETDiffTestObj objWithName:stringValue];
            [arr addObject:obj];
        }
    }
    
    va_end(args);
}

#define Arr_Random_sort(arr)    [arr sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) { return arc4random() % 2 == 0; }];
#define Arr_add(arr, ...)   _arr_add(arr, __VA_ARGS__);

@implementation ETDiffTests

- (void)setUp {
    self.arr1 = [NSMutableArray array];
    self.arr2 = [NSMutableArray array];
}

- (void)tearDown {}

- (void)afterEach {
    [self.arr1 removeAllObjects];
    [self.arr2 removeAllObjects];
}

- (void)testEqualAndRandomSort {
    Arr_add(self.arr1, "1", "2", "3", "4", "5", nil)
    Arr_add(self.arr2, "1", "2", "3", "4", "5", nil)
    
    EventTracingDiffResults *
    result = NE_ET_DiffBetweenArray(self.arr1, self.arr2);
    XCTAssertTrue(!result.hasDiffs);
    XCTAssertTrue(result.inserts.count == 0);
    XCTAssertTrue(result.deletes.count == 0);
    
    // arr2 随机排序
    Arr_Random_sort(self.arr2)
    result = NE_ET_DiffBetweenArray(self.arr1, self.arr2);
    XCTAssertTrue(!result.hasDiffs);
    XCTAssertTrue(result.inserts.count == 0);
    XCTAssertTrue(result.deletes.count == 0);
}

- (void)testOnlyDeletes {
    Arr_add(self.arr1, "1", "2", "3", "4", nil)
    Arr_add(self.arr2, "1", "2", nil)
    
    EventTracingDiffResults *
    result = NE_ET_DiffBetweenArray(self.arr2, self.arr1);
    XCTAssertTrue(result.hasDiffs);
    XCTAssertTrue(result.inserts.count == 0);
    XCTAssertTrue(result.deletes.count == 2);
    
    // arr2 随机排序
    Arr_Random_sort(self.arr2)
    result = NE_ET_DiffBetweenArray(self.arr2, self.arr1);
    XCTAssertTrue(result.hasDiffs);
    XCTAssertTrue(result.inserts.count == 0);
    XCTAssertTrue(result.deletes.count == 2);
}

- (void)testOnlyinserts {
    Arr_add(self.arr1, "1", "2", "4", nil)
    Arr_add(self.arr2, "1", "#1", "2", "#3", "4", nil)
    
    EventTracingDiffResults *
    result = NE_ET_DiffBetweenArray(self.arr2, self.arr1);
    XCTAssertTrue(result.hasDiffs);
    XCTAssertTrue(result.inserts.count == 2);
    XCTAssertTrue(result.deletes.count == 0);
    
    // arr2 随机排序
    Arr_Random_sort(self.arr2)
    result = NE_ET_DiffBetweenArray(self.arr2, self.arr1);
    XCTAssertTrue(result.hasDiffs);
    XCTAssertTrue(result.inserts.count == 2);
    XCTAssertTrue(result.deletes.count == 0);
}

- (void)testDeletesAndInserts {
    Arr_add(self.arr1, "1", "2", "3", "4", "5", nil)
    Arr_add(self.arr2, "1", "2", "#3", "4", "#4", "#5", nil)
    
    EventTracingDiffResults *
    result = NE_ET_DiffBetweenArray(self.arr2, self.arr1);
    XCTAssertTrue(result.hasDiffs);
    XCTAssertTrue(result.inserts.count == 3);
    XCTAssertTrue(result.deletes.count == 2);
    
    // arr2 随机排序
    Arr_Random_sort(self.arr2)
    result = NE_ET_DiffBetweenArray(self.arr2, self.arr1);
    XCTAssertTrue(result.hasDiffs);
    XCTAssertTrue(result.inserts.count == 3);
    XCTAssertTrue(result.deletes.count == 2);
}

@end
