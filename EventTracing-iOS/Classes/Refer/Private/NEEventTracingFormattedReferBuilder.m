//
//  NEEventTracingFormattedReferBuilder.m
//  NEEventTracing
//
//  Created by dl on 2022/2/23.
//

#import "NEEventTracingFormattedReferBuilder.h"
#import "NEEventTracingEngine.h"
#import "NSString+EventTracingUtil.h"
#import <BlocksKit/BlocksKit.h>

@interface NEEventTracingFormattedReferInstance : NSObject <NEEventTracingFormattedRefer>
@property(nonatomic, assign, readwrite) NEEventTracingFormattedReferComponentOptions options;

/// MARK: 第 [0-10) 位，是用来保留的，作为存在真实 component 的位
@property(nonatomic, copy, readwrite) NSString *sessid;
@property(nonatomic, copy, readwrite) NSString *type;
@property(nonatomic, assign, readwrite) NSInteger actseq;
@property(nonatomic, assign, readwrite) NSInteger pgstep;
@property(nonatomic, copy, readwrite, nullable) NSString *spm;
@property(nonatomic, copy, readwrite, nullable) NSString *scm;

/// MARK: 第 [11-~) 位，用来做 `标记位` 使用
@property(nonatomic, assign, readwrite, getter=isER) BOOL er;
@property(nonatomic, assign, readwrite, getter=isUndefinedXpath) BOOL undefinedXpath;
@property(nonatomic, assign, readwrite, getter=isH5) BOOL h5;
@end

@implementation NEEventTracingFormattedReferInstance
@synthesize options = _options;
@synthesize sessid = _sessid;
@synthesize type = _type;
@synthesize actseq = _actseq;
@synthesize pgstep = _pgstep;
@synthesize spm = _spm;
@synthesize scm = _scm;

@synthesize er = _er;
@synthesize undefinedXpath = _undefinedXpath;
@synthesize h5 = _h5;

- (NSString *)value {
    return [self _valueForceWithSessid:NO undefinedXpath:NO];
}

- (NSString *)dkey {
    return [self.class _dkeyFromOptions:self.options];
}

- (NSString *)valueWithSessid:(BOOL)withSessid undefinedXpath:(BOOL)undefinedXpath {
    return [self _valueForceWithSessid:withSessid undefinedXpath:undefinedXpath];
}

+ (id<NEEventTracingFormattedRefer>)_doParse:(NSString *)value error:(NSError ** _Nullable)error {
    BOOL firstAndEndCharValid = [value hasPrefix:@"["] && [value hasSuffix:@"]"];
    if (!firstAndEndCharValid) {
        if (error) {
            *error = [NSError errorWithDomain:@"com.netease.eventtracing.refer"
                                         code:-1001
                                     userInfo:@{NSLocalizedDescriptionKey: @"refer格式错误，应该以 `[` 开始，并且以 `]` 结束"}];
        }
        return nil;
    }
    
    NSString *trimValue = [value substringWithRange:NSMakeRange(1, value.length - 2)];
    NSMutableArray<NSString *> *comps = [trimValue componentsSeparatedByString:@"]["].mutableCopy;
    
#define RemoveFirstObjectIfNeeded       if (comps.count > 0) { [comps removeObjectAtIndex:0]; }
    
    // 1. _key
    NSString *dkey = nil;
    NSString *dkeyPrefix = @"_dkey:";
    if ([comps.firstObject hasPrefix:dkeyPrefix]) {
        dkey = [comps.firstObject substringWithRange:NSMakeRange(dkeyPrefix.length, comps.firstObject.length - dkeyPrefix.length)];
        
        RemoveFirstObjectIfNeeded
    }
    
    // 2. _F
    NEEventTracingFormattedReferComponentOptions options = 0;
    NSString *optionsPrefix = @"F:";
    if ([comps.firstObject hasPrefix:optionsPrefix]) {
        NSRange range = NSMakeRange(optionsPrefix.length, comps.firstObject.length - optionsPrefix.length);
        NSString *optionsString = [comps.firstObject substringWithRange:range];
        options = [optionsString integerValue];
        
        RemoveFirstObjectIfNeeded
    }
    
    /// MARK: 如果存在 _dkey，则应该跟 options 是等价的，否则不合法
    NSString *dkeyFromOptions = [self _dkeyFromOptions:options];
    NSSet *dkeyFromOptionsSet = [NSSet setWithArray:[dkeyFromOptions componentsSeparatedByString:@"|"]];
    if (dkey.length) {
        NSSet *dkeySet = [NSSet setWithArray:[dkey componentsSeparatedByString:@"|"]];
        if (![dkeySet isEqualToSet:dkeyFromOptionsSet]) {
            if (error) {
                *error = [NSError errorWithDomain:@"com.netease.eventtracing.refer"
                                             code:-1002
                                         userInfo:@{NSLocalizedDescriptionKey: @"refer格式错误，`F` 跟 `_dkey` 不等价"}];
            }
            return nil;
        }
    }
    
    /// MARK: 这里需要过滤 flag 形式的 _dkey
    NSSet<NSString *> *dkeyFromOptionsSetFlagsDelete = [dkeyFromOptionsSet bk_reject:^BOOL(NSString *obj) {
        return [@[@"er", @"undefined-xpath", @"h5"] containsObject:obj];
    }];
    if (dkeyFromOptionsSetFlagsDelete.count != comps.count) {
        if (error) {
            *error = [NSError errorWithDomain:@"com.netease.eventtracing.refer"
                                         code:-1003
                                     userInfo:@{NSLocalizedDescriptionKey: @"refer格式错误，`F` 或者 `_dkey` 跟components个数不一致"}];
        }
        return nil;
    }
    
    /// MARK: components
    // 3. sessid
    NSString *sessid;
    if (options & NEEventTracingFormattedReferComponentSessid) {
        sessid = comps.firstObject;
        RemoveFirstObjectIfNeeded
    }
    
    // 4. type
    NSString *type;
    if (options & NEEventTracingFormattedReferComponentType) {
        type = comps.firstObject;
        if (type.length == 0) {
            if (error) {
                NSString *message = [NSString stringWithFormat:@"refer格式错误，type必须存在，且长度大于0，但是解析出的结果是 `%@`", type];
                *error = [NSError errorWithDomain:@"com.netease.eventtracing.refer"
                                             code:-1004
                                         userInfo:@{NSLocalizedDescriptionKey: message}];
            }
            return nil;
        }
        RemoveFirstObjectIfNeeded
    }
    
    // 5. actseq
    NSInteger actseq = 0;
    if (options & NEEventTracingFormattedReferComponentActseq) {
        actseq = [comps.firstObject integerValue];
        RemoveFirstObjectIfNeeded
    }
    
    // 6. pgstep
    NSInteger pgstep = 0;
    if (options & NEEventTracingFormattedReferComponentPgstep) {
        pgstep = [comps.firstObject integerValue];
        RemoveFirstObjectIfNeeded
    }
    
    // 7. spm
    NSString *spm;
    if (options & NEEventTracingFormattedReferComponentSPM) {
        spm = comps.firstObject;
        RemoveFirstObjectIfNeeded
    }
    
    // 8. scm
    NSString *scm;
    if (options & NEEventTracingFormattedReferComponentSCM) {
        scm = comps.firstObject;
        RemoveFirstObjectIfNeeded
    }
    
    NEEventTracingFormattedReferInstance *refer = [[NEEventTracingFormattedReferInstance alloc] init];
    refer.options = options;
    refer.sessid = sessid;
    refer.type = type;
    refer.actseq = actseq;
    refer.pgstep = pgstep;
    refer.spm = spm;
    refer.scm = scm;
    
    refer.er = options & NEEventTracingFormattedReferComponentFlagER;
    refer.undefinedXpath = options & NEEventTracingFormattedReferComponentFlagUndefinedXpath;
    refer.h5 = options & NEEventTracingFormattedReferComponentFlagH5;
    
    return refer;
}

- (NSString *)_valueForceWithSessid:(BOOL)forceWithSessid undefinedXpath:(BOOL)undefinedXpath {
    NSMutableString *value = [@"" mutableCopy];
    
    /// MARK: _dkey, F
    NEEventTracingFormattedReferComponentOptions options = self.options;
    if (forceWithSessid) {
        options |= NEEventTracingFormattedReferComponentSessid;
    }
    if (undefinedXpath) {
        options |= NEEventTracingFormattedReferComponentFlagUndefinedXpath;
    }
    
    if ([NEEventTracingEngine sharedInstance].context.referFormatHasDKeyComponent) {
        [value appendFormat:@"[_dkey:%@]", [self.class _dkeyFromOptions:options]];
    }
    
    [value appendFormat:@"[F:%@]", @(options).stringValue];
    
    /// MARK: component s
    // 1. sessid
    if (options & NEEventTracingFormattedReferComponentSessid) {
        [value appendFormat:@"[%@]", self.sessid];
    }
    // 2. type
    if (options & NEEventTracingFormattedReferComponentType) {
        [value appendFormat:@"[%@]", self.type];
    }
    
    // 3. actseq
    if (options & NEEventTracingFormattedReferComponentActseq) {
        [value appendFormat:@"[%@]", @(self.actseq).stringValue];
    }
    
    // 4. pgstep
    if (options & NEEventTracingFormattedReferComponentPgstep) {
        [value appendFormat:@"[%@]", @(self.pgstep).stringValue];
    }
    
    // 5. spm
    if (options & NEEventTracingFormattedReferComponentSPM) {
        [value appendFormat:@"[%@]", self.spm];
    }
    
    // 6. scm
    if (options & NEEventTracingFormattedReferComponentSCM) {
        [value appendFormat:@"[%@]", self.scm];
    }
    
    return value.copy;
}

#pragma mark - private methods
+ (NSString *)_dkeyFromOptions:(NEEventTracingFormattedReferComponentOptions)options {
    NSMutableArray<NSString *> *dkeys = [NSMutableArray array];
    
    NSArray<NSDictionary *> *mapValues = @[
        @{@(NEEventTracingFormattedReferComponentFlagER): @"er"},
        @{@(NEEventTracingFormattedReferComponentFlagUndefinedXpath): @"undefined-xpath"},
        @{@(NEEventTracingFormattedReferComponentFlagH5): @"h5"},
        
        @{@(NEEventTracingFormattedReferComponentSessid): @"sessid"},
        @{@(NEEventTracingFormattedReferComponentType): @"type"},
        @{@(NEEventTracingFormattedReferComponentActseq): @"actseq"},
        @{@(NEEventTracingFormattedReferComponentPgstep): @"pgstep"},
        @{@(NEEventTracingFormattedReferComponentSPM): @"spm"},
        @{@(NEEventTracingFormattedReferComponentSCM): @"scm"}
    ];

    [mapValues enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NEEventTracingFormattedReferComponentOptions option = [obj.allKeys.firstObject integerValue];
        if (options & option) {
            [dkeys addObject:obj.allValues.firstObject];
        }
    }];
    
    return [dkeys componentsJoinedByString:@"|"];
}

- (NSString *)description {
    return self.value;
}

@end

@interface NEEventTracingFormattedReferBuilder () <NEEventTracingFormattedReferComponentBuilder>
@property(nonatomic, strong) NEEventTracingFormattedReferInstance *referInstance;
@end

@implementation NEEventTracingFormattedReferBuilder

+ (NEEventTracingFormattedReferBuilder *)build:(void (^)(id<NEEventTracingFormattedReferComponentBuilder> _Nonnull))block {
    NEEventTracingFormattedReferBuilder *builder = [[NEEventTracingFormattedReferBuilder alloc] init];
    builder.referInstance = [[NEEventTracingFormattedReferInstance alloc] init];
    builder.referInstance.sessid = [NEEventTracingEngine sharedInstance].context.sessid;
    block(builder);
    return builder;
}

- (id<NEEventTracingFormattedRefer>)generateRefer {
    return self.referInstance;
}

#pragma mark - NEEventTracingFormattedReferComponentBuilder

#define NEEventTracingFormattedReferComponentBuilderMethod(TYPE, name, option)              \
- (id<NEEventTracingFormattedReferComponentBuilder> _Nonnull (^)(TYPE))name {               \
    return ^id<NEEventTracingFormattedReferComponentBuilder>(TYPE value) {                  \
        self.referInstance.name = value;                                                    \
        self.referInstance.options |= option;                                               \
        return self;                                                                        \
    };                                                                                      \
}

- (id<NEEventTracingFormattedReferComponentBuilder> _Nonnull (^)(void))withSesid {
    return ^id<NEEventTracingFormattedReferComponentBuilder>(void) {
        self.referInstance.options |= NEEventTracingFormattedReferComponentSessid;
        return self;
    };
}

NEEventTracingFormattedReferComponentBuilderMethod(NSString * _Nonnull, type, NEEventTracingFormattedReferComponentType)

- (id<NEEventTracingFormattedReferComponentBuilder>  _Nonnull (^)(void))typeE {
    return ^id<NEEventTracingFormattedReferComponentBuilder>(void) {
        self.type(NE_ET_REFER_KEY_E);
        return self;
    };
}
- (id<NEEventTracingFormattedReferComponentBuilder>  _Nonnull (^)(void))typeP {
    return ^id<NEEventTracingFormattedReferComponentBuilder>(void) {
        self.type(NE_ET_REFER_KEY_P);
        return self;
    };
}

NEEventTracingFormattedReferComponentBuilderMethod(NSInteger, actseq, NEEventTracingFormattedReferComponentActseq)
NEEventTracingFormattedReferComponentBuilderMethod(NSInteger, pgstep, NEEventTracingFormattedReferComponentPgstep)
NEEventTracingFormattedReferComponentBuilderMethod(NSString * _Nonnull, spm, NEEventTracingFormattedReferComponentSPM)
NEEventTracingFormattedReferComponentBuilderMethod(NSString * _Nonnull, scm, NEEventTracingFormattedReferComponentSCM)

#define NEEventTracingFormattedReferComponentBuilderMethodVoidBollean(name, option)         \
- (id<NEEventTracingFormattedReferComponentBuilder> _Nonnull (^)(void))name {               \
    return ^id<NEEventTracingFormattedReferComponentBuilder>(void) {                        \
        self.referInstance.name = YES;                                                      \
        self.referInstance.options |= option;                                               \
        return self;                                                                        \
    };                                                                                      \
}

NEEventTracingFormattedReferComponentBuilderMethodVoidBollean(undefinedXpath, NEEventTracingFormattedReferComponentFlagUndefinedXpath)
NEEventTracingFormattedReferComponentBuilderMethodVoidBollean(er, NEEventTracingFormattedReferComponentFlagER)
NEEventTracingFormattedReferComponentBuilderMethodVoidBollean(h5, NEEventTracingFormattedReferComponentFlagH5)

@end

id<NEEventTracingFormattedRefer> _Nullable NE_ET_FormattedReferParseFromReferString(NSString *referString) {
    return NE_ET_FormattedReferParseFromReferStringWithError(referString, nil);
}

id<NEEventTracingFormattedRefer> _Nullable NE_ET_FormattedReferParseFromReferStringWithError(NSString *referString, NSError ** _Nullable error) {
    return [NEEventTracingFormattedReferInstance _doParse:referString error:error];
}
