//
//  NEEventTracingMultiReferPatch.h
//  NEEventTracing
//
//  Created by dl on 2022/12/6.
//

#import <Foundation/Foundation.h>
#import "NEEventTracingContext.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXTERN NSUInteger NEEventTracingMultiRefersMaxCount;   // => 5
FOUNDATION_EXTERN NSString * NEEventTracingMultiRefersEvents;      // => "_pv,_ec"

/// 多级归因: 在一些实时分析的场景中，分析师需要知道实时某一个埋点向前N步的路径，但是离线数据上报是存量上报，没有那么实时
/// 所以可以配置一些埋点会带上 N 级的归因 refer
///  ==> `_multirefers`
@interface NEEventTracingMultiReferPatch : NSObject

/// MARK: 是数组
@property(nonatomic, copy, readonly) NSArray<NSString *> *multiRefers;
/// MARK: Array => JsonString
@property(nonatomic, copy, readonly) NSString *multiRefersJsonString;

+ (instancetype)sharedPatch;
- (void)patchOnContextBuilder:(id<NEEventTracingContextBuilder>)builder;

@end

NS_ASSUME_NONNULL_END
