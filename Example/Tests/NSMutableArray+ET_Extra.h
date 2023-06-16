//
//  NSMutableArray+NE_ET_Extra.h
//  EventTracing-iOS_Example
//
//  Created by 熊勋泉 on 2022/12/16.
//  Copyright © 2022 9446796. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSMutableArray (NE_ET_Extra)

- (void)et_pushObject:(id)anObject;
- (void)et_popObject;
@end

NS_ASSUME_NONNULL_END
