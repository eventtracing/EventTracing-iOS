//
//  NSString+EventTracingUtil.h
//  NEEventTracing
//
//  Created by dl on 2022/2/23.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (EventTracingUtil)

/// MARK: cid在组装scm的时候，如果存在特殊字符，会影响scm的格式，此时需要url encode的方式来解决
- (BOOL)ne_et_simplyNeedsEncoded;

- (BOOL)ne_et_hasBeenUrlEncoded;
- (NSString * _Nullable)ne_et_urlEncode;
- (NSString * _Nullable)ne_et_urlDecode;

@end

NS_ASSUME_NONNULL_END
