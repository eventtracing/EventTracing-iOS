//
//  NEEventTracingEventRefer.h
//  NEEventTracing
//
//  Created by dl on 2022/2/23.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, NEEventTracingEventReferType) {
    NEEventTracingEventReferTypeFormatted,              // 标准`格式化` 的refer
    NEEventTracingEventReferTypeUndefinedXpath          // undefined-xpath 形式的 refer
};

@protocol NEEventTracingEventRefer <NSObject>

@property(nonatomic, copy, readonly) NSString *event;
@property(nonatomic, assign, readonly) NSTimeInterval eventTime;
@property(nonatomic, copy, readonly) NSString *refer;

@property(nonatomic, assign, readonly) NEEventTracingEventReferType referType;

@end

NS_ASSUME_NONNULL_END
