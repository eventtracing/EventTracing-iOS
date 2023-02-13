//
//  NSMutableArray+ET_Extra.m
//  EventTracing-iOS_Example
//
//  Created by 熊勋泉 on 2022/12/16.
//  Copyright © 2022 9446796. All rights reserved.
//

#import "NSMutableArray+ET_Extra.h"
#import <KIF/KIF.h>

@implementation NSMutableArray (ET_Extra)

- (void)et_pushObject:(id)anObject {
    if (!anObject)
    {
        NSLog(@"error");
    }
    XCTAssertTrue(anObject != nil);
    [self insertObject:anObject atIndex:0];
}

- (void)et_popObject {
    [self removeObjectAtIndex:0];
}

@end
