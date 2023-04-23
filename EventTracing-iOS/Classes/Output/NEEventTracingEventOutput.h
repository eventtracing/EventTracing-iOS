//
//  EventTracingEventOutput.h
//  BlocksKit
//
//  Created by dl on 2021/3/22.
//

#import <Foundation/Foundation.h>
#import "EventTracingOutputFormatter.h"
#import "EventTracingEventOutputChannel.h"

NS_ASSUME_NONNULL_BEGIN

@interface EventTracingEventOutput : NSObject

@property(nonatomic, strong, readonly) id<EventTracingOutputFormatter> formatter;
@property(nonatomic, weak, readonly) id<EventTracingOutputPublicDynamicParamsProvider> publicDynamicParamsProvider;
@property(nonatomic, strong, readonly) NSDictionary *staticPublicParmas;
@property(nonatomic, strong, readonly) NSDictionary *currentActivePublicParmas;

@property(nonatomic, strong, readonly) NSArray<id<EventTracingEventOutputChannel>> *allOutputChannels;
@property(nonatomic, strong, readonly) NSArray<id<EventTracingOutputParamsFilter>> *allParmasFilters;

- (void)configStaticPublicParams:(NSDictionary<NSString *,NSString *> *)params withParamGuard:(BOOL)withParamGuard;
- (void)configCurrentActivePublicParams:(NSDictionary<NSString *,NSString *> *)params withParamGuard:(BOOL)withParamGuard;
- (void)removeCurrentActivePublicParmas;

@end

NS_ASSUME_NONNULL_END
