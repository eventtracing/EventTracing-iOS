//
//  NSString+EventTracingUtil.m
//  EventTracing
//
//  Created by dl on 2022/2/23.
//

#import "NSString+EventTracingUtil.h"

@implementation NSString (EventTracingUtil)

- (BOOL)et_simplyNeedsEncoded {
    static NSRegularExpression *reg = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        reg = [NSRegularExpression regularExpressionWithPattern:@"[:|\\[\\],.\\/\\\\{}`<>@?&\\s'\"]" options:0 error:nil];
    });
    NSInteger matchCount = [reg numberOfMatchesInString:self
                                                options:NSMatchingReportProgress
                                                  range:NSMakeRange(0, self.length)];
    return matchCount > 0;
}

- (BOOL)et_hasBeenUrlEncoded {
    return ![self.et_urlDecode isEqualToString:self];
}

- (NSString * _Nullable)et_urlEncode {
    static dispatch_once_t onceToken;
    static NSCharacterSet *charSet = nil;
    dispatch_once(&onceToken, ^{
        NSMutableCharacterSet *set = [NSCharacterSet URLQueryAllowedCharacterSet].invertedSet.mutableCopy;
        [set formUnionWithCharacterSet:[NSCharacterSet characterSetWithCharactersInString:@"!*'\"();:@&=+$,/?%#[]%,.\\|{}`<>\x20\t\n\r"]];
        charSet = [set invertedSet];
    });
    return [self stringByAddingPercentEncodingWithAllowedCharacters:charSet];
}

- (NSString * _Nullable)et_urlDecode {
    return self.stringByRemovingPercentEncoding;
}

@end
