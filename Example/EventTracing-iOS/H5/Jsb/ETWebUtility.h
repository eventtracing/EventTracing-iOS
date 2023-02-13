//
//  ETWebUtility.h
//  EventTracing-iOS_Example
//
//  Created by dl on 2022/12/27.
//  Copyright © 2022 9446796. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ETWebUtility : NSObject

+ (NSString *)scriptWithJSFunc:(NSString *)funcName withArgs:(NSArray *)args;

#pragma mark - json
+ (NSString *)JSONStringifyWithJSONObject:(id)object;
+ (id)JSONObjectFromJSONString:(NSString *)string;

@end

NS_ASSUME_NONNULL_END
