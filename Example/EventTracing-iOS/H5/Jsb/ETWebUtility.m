//
//  ETWebUtility.m
//  EventTracing-iOS_Example
//
//  Created by dl on 2022/12/27.
//  Copyright © 2022 9446796. All rights reserved.
//

#import "ETWebUtility.h"

@implementation ETWebUtility

+ (NSString *)scriptWithJSFunc:(NSString *)funcName withArgs:(NSArray *)args {
    
    NSMutableString *js = funcName.mutableCopy;
    [js appendString:@"("];
    NSMutableArray *values = @[].mutableCopy;
    [args enumerateObjectsUsingBlock:^(id _Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        NSString *value = @"";
        if ([obj isKindOfClass:[NSString class]]) {
            value = [self javaScriptStringEncodeValue:obj];
        } else if ([obj isKindOfClass:[NSNumber class]]) {
            value = [NSString stringWithFormat:@"%@", obj];
        } else if ([obj isKindOfClass:[NSArray class]] || [obj isKindOfClass:[NSDictionary class]]) {
            value = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:obj options:0 error:nil]
                                          encoding:NSUTF8StringEncoding];
        } else if ([obj isKindOfClass:[NSNull class]]) {
            value = @"null";
        }
        [values addObject:value];
    }];
    [js appendString:[values componentsJoinedByString:@","]];
    [js appendString:@")"];
    return js;
}

+ (NSString *)javaScriptStringEncodeValue:(NSString *)value {
    
    NSMutableString *result = value.mutableCopy;
    [result replaceOccurrencesOfString:@"\\" withString:@"\\\\" options:0 range:NSMakeRange(0, result.length)];
    [result replaceOccurrencesOfString:@"\"" withString:@"\\\"" options:0 range:NSMakeRange(0, result.length)];
    [result replaceOccurrencesOfString:@"\n" withString:@"\\n" options:0 range:NSMakeRange(0, result.length)];
    [result replaceOccurrencesOfString:@"\r" withString:@"\\r" options:0 range:NSMakeRange(0, result.length)];
    [result replaceOccurrencesOfString:@"\f" withString:@"\\f" options:0 range:NSMakeRange(0, result.length)];
    [result replaceOccurrencesOfString:@"\u2028" withString:@"\\u2028" options:0 range:NSMakeRange(0, result.length)];
    [result replaceOccurrencesOfString:@"\u2029" withString:@"\\u2029" options:0 range:NSMakeRange(0, result.length)];
    return [NSString stringWithFormat:@"\"%@\"", result];
}

#pragma mark -

+ (id)JSONObjectFromJSONString:(NSString *)string {
    
    NSData *jsonData = [string dataUsingEncoding:NSUTF8StringEncoding];
    if (! jsonData) {
        return nil;
    }
    NSDictionary *ret = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:nil];
    return ret;
}

+ (NSString *)JSONStringifyWithJSONObject:(id)object {
    
    if (! object) {
        return nil;
    }
    NSData *data = [NSJSONSerialization dataWithJSONObject:object options:kNilOptions error:nil];
    if (! data) {
        return nil;
    }
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

@end
