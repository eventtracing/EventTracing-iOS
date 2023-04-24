//
//  NEEventTracingParamGuardConfiguration.h
//  BlocksKit
//
//  Created by dl on 2021/5/20.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString * const ETParamKeyGuardErrorRegxKey;

FOUNDATION_EXPORT BOOL NE_ET_CheckEventKeyValid(NSString *eventKey);
FOUNDATION_EXPORT BOOL NE_ET_CheckPublicParamKeyValid(NSString *publicParamKey);
FOUNDATION_EXPORT BOOL NE_ET_CheckUserParamKeyValid(NSString *userParamKey);

@protocol NEEventTracingParamGuardConfiguration <NSObject>

// default: `^(_)[a-z]+(?:[-_][a-z]+)*$`
// 参见: `NEEventTracingExceptionEventKeyInvalid`
@property(nonatomic, copy) NSString *eventKeyRegx;
// default: `^(g_)[a-z][^\\W_]+[^\\W_]*(?:[-_][^\\W_]+)*$`
// 参见: `NEEventTracingExceptionPublicParamInvalid`
@property(nonatomic, copy) NSString *publicParamRegx;

// default: s_
@property(nonatomic, copy) NSString *userParamRegxOptionalPrefix;       // 比如 s_
// default: `^[a-z][^\\W_]+[^\\W_]*(?:[-_][^\\W_]+)*$`
@property(nonatomic, copy) NSString *userParamRegx;

// default: `^[s_]{0,}[a-z][^\\W_]+[^\\W_]*(?:[-_][^\\W_]+)*$`
// 参见: `NEEventTracingExceptionUserParamInvalid`
@property(nonatomic, readonly) NSString *userParamRegxFixed;

@end

NS_ASSUME_NONNULL_END
