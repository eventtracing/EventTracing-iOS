//
//  EventTracingFormattedReferBuilder.h
//  EventTracing
//
//  Created by dl on 2022/2/23.
//

#import <Foundation/Foundation.h>
#import "EventTracingFormattedRefer.h"

NS_ASSUME_NONNULL_BEGIN

@protocol EventTracingFormattedReferComponentBuilder <NSObject>

/// MARK: component s
@property(nonatomic, readonly) id<EventTracingFormattedReferComponentBuilder> (^withSesid)(void);

@property(nonatomic, readonly) id<EventTracingFormattedReferComponentBuilder> (^type)(NSString *value);
@property(nonatomic, readonly) id<EventTracingFormattedReferComponentBuilder> (^typeE)(void);
@property(nonatomic, readonly) id<EventTracingFormattedReferComponentBuilder> (^typeP)(void);

@property(nonatomic, readonly) id<EventTracingFormattedReferComponentBuilder> (^actseq)(NSInteger value);
@property(nonatomic, readonly) id<EventTracingFormattedReferComponentBuilder> (^pgstep)(NSInteger value);
@property(nonatomic, readonly) id<EventTracingFormattedReferComponentBuilder> (^spm)(NSString *value);
@property(nonatomic, readonly) id<EventTracingFormattedReferComponentBuilder> (^scm)(NSString *value);

/// MARK: mark s
@property(nonatomic, readonly) id<EventTracingFormattedReferComponentBuilder> (^undefinedXpath)(void);
@property(nonatomic, readonly) id<EventTracingFormattedReferComponentBuilder> (^er)(void);
@property(nonatomic, readonly) id<EventTracingFormattedReferComponentBuilder> (^h5)(void);

@end

@interface EventTracingFormattedReferBuilder : NSObject

+ (EventTracingFormattedReferBuilder *)build:(void(^)(id<EventTracingFormattedReferComponentBuilder> builder))block;
- (id<EventTracingFormattedRefer>)generateRefer;

@end

NS_ASSUME_NONNULL_END
