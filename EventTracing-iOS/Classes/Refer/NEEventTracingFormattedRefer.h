//
//  NEEventTracingFormattedRefer.h
//  NEEventTracing
//
//  Created by dl on 2022/2/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_OPTIONS(NSUInteger, NEEventTracingFormattedReferComponentOptions) {
    NEEventTracingFormattedReferComponentUnknown                 = 0,
    
    /// MARK: 第 [0-10) 位，是用来保留的，作为存在真实 component 的位
    NEEventTracingFormattedReferComponentSessid                  = 1 << 0,   // => _dkey: sessid
    NEEventTracingFormattedReferComponentType                    = 1 << 1,   // => _dkey: type
    NEEventTracingFormattedReferComponentActseq                  = 1 << 2,   // => _dkey: actseq
    NEEventTracingFormattedReferComponentPgstep                  = 1 << 3,   // => _dkey: pgstep
    NEEventTracingFormattedReferComponentSPM                     = 1 << 4,   // => _dkey: spm
    NEEventTracingFormattedReferComponentSCM                     = 1 << 5,   // => _dkey: scm
    
    /// MARK: 第 [11-~) 位，用来做 `标记位` 使用
    NEEventTracingFormattedReferComponentFlagER                  = 1 << 10,  // => _dkey: er
    NEEventTracingFormattedReferComponentFlagUndefinedXpath      = 1 << 11,  // => _dkey: undefined-xpath
    NEEventTracingFormattedReferComponentFlagH5                  = 1 << 12   // => _dkey: h5
};

/// MARK: 格式如下
// [_dkey:er|undefined-path|sessid|type|actseq|pgstep|spm|scm][F:${option}][sessid][e/p][_actseq][_pgstep][spm][scm]
// 其中 _dkey 应该配置成金测试包下存在
/// MARK: 从右向左，1-10位，属于 component, 会以 `[$param]` 的形式存在
/// MARK: 超过10位，仅仅属于标记位，会在 _dkey & F:${option} 中体现出来
// sessid, type, actseq, pgstep, spm, scm => 分别是 1-6位
// er, undefinex-xpath, h5 => 分别是 11-13 位
@protocol NEEventTracingFormattedRefer <NSObject>

/// MARK: refer的value值，字符串
@property(nonatomic, copy, readonly) NSString *value;
@property(nonatomic, copy, readonly, nullable) NSString *dkey;
@property(nonatomic, assign, readonly) NEEventTracingFormattedReferComponentOptions options;

/// MARK: 第 [0-10) 位，是用来保留的，作为存在真实 component 的位
@property(nonatomic, copy, readonly) NSString *sessid;
@property(nonatomic, copy, readonly) NSString *type;
@property(nonatomic, assign, readonly) NSInteger actseq;
@property(nonatomic, assign, readonly) NSInteger pgstep;
@property(nonatomic, copy, readonly, nullable) NSString *spm;
@property(nonatomic, copy, readonly, nullable) NSString *scm;

/// MARK: 第 [11-~) 位，用来做 `标记位` 使用
// scm是否涉及加密
@property(nonatomic, assign, readonly, getter=isER) BOOL er;
// 是否被标记位 undefined-xpath
@property(nonatomic, assign, readonly, getter=isUndefinedXpath) BOOL undefinedXpath;
// 是否来自于 h5
@property(nonatomic, assign, readonly, getter=isH5) BOOL h5;

/// MARK: 单独 开启/关闭 sessid
- (NSString *)valueWithSessid:(BOOL)withSessid undefinedXpath:(BOOL)undefinedXpath;

@end

/// MARK: 从一个字符串，可以反向生成 refer 对象
/// MARK: 对字符串refer做解析
FOUNDATION_EXPORT id<NEEventTracingFormattedRefer> _Nullable NE_ET_FormattedReferParseFromReferString(NSString *referString);
FOUNDATION_EXPORT id<NEEventTracingFormattedRefer> _Nullable NE_ET_FormattedReferParseFromReferStringWithError(NSString *referString, NSError ** _Nullable error);

NS_ASSUME_NONNULL_END
