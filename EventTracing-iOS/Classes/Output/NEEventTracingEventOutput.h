//
//  NEEventTracingEventOutput.h
//  BlocksKit
//
//  Created by dl on 2021/3/22.
//

#import <Foundation/Foundation.h>
#import "NEEventTracingOutputFormatter.h"
#import "NEEventTracingEventOutputChannel.h"

NS_ASSUME_NONNULL_BEGIN

@interface NEEventTracingEventOutput : NSObject

@property(nonatomic, strong, readonly) id<NEEventTracingOutputFormatter> formatter;
@property(nonatomic, weak, readonly) id<NEEventTracingOutputPublicDynamicParamsProvider> publicDynamicParamsProvider;
@property(nonatomic, strong, readonly) NSDictionary *staticPublicParmas;
@property(nonatomic, strong, readonly) NSDictionary *currentActivePublicParmas;

@property(nonatomic, strong, readonly) NSArray<id<NEEventTracingEventOutputChannel>> *allOutputChannels;
@property(nonatomic, strong, readonly) NSArray<id<NEEventTracingOutputParamsFilter>> *allParmasFilters;

- (void)configStaticPublicParams:(NSDictionary<NSString *,NSString *> *)params withParamGuard:(BOOL)withParamGuard;
- (void)configCurrentActivePublicParams:(NSDictionary<NSString *,NSString *> *)params withParamGuard:(BOOL)withParamGuard;
- (void)removeCurrentActivePublicParmas;

@end

NS_ASSUME_NONNULL_END
