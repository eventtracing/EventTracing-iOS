//
//  EventTracingEventRefer.h
//  EventTracing
//
//  Created by dl on 2022/2/23.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, EventTracingEventReferType) {
    EventTracingEventReferTypeFormatted,              // 标准`格式化` 的refer
    EventTracingEventReferTypeUndefinedXpath          // undefined-xpath 形式的 refer
};

@protocol EventTracingEventRefer <NSObject>

@property(nonatomic, copy, readonly) NSString *event;
@property(nonatomic, assign, readonly) NSTimeInterval eventTime;
@property(nonatomic, copy, readonly) NSString *refer;

@property(nonatomic, assign, readonly) EventTracingEventReferType referType;

@end

NS_ASSUME_NONNULL_END
