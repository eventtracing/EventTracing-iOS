//
//  EventTracingEventOutput+Private.h
//  BlocksKit
//
//  Created by dl on 2021/3/24.
//

#import "EventTracingEventOutput.h"
#import "EventTracingContext.h"
#import "UIView+EventTracingPrivate.h"

NS_ASSUME_NONNULL_BEGIN

@interface EventTracingEventOutput () <EventTracingContextOutputFormatterBuilder, EventTracingContextOutputParamsFilterBuilder>

@property(nonatomic, strong) NSHashTable<id<EventTracingEventOutputChannel>> *outputChannels;
@property(nonatomic, strong) NSHashTable<id<EventTracingOutputParamsFilter>> *outputParamsFilters;
@property(nonatomic, strong) NSMutableDictionary *innerStaticPublicParams;
@property(nonatomic, strong, nullable) NSMutableDictionary *innerCurrentActivePublicParams;

- (void)outputEvent:(NSString *)event
      contextParams:(NSDictionary * _Nullable)contextParams
    logActionParams:(NSDictionary * _Nullable)logActionParams
               node:(EventTracingVTreeNode *)node
            inVTree:(EventTracingVTree *)VTree;

- (void)outputEventWithoutNode:(NSString *)event contextParams:(NSDictionary * _Nullable)contextParams;

- (NSDictionary *)publicParamsForEvent:(NSString * _Nullable)event
                                  node:(EventTracingVTreeNode * _Nullable)node
                               inVTree:(EventTracingVTree * _Nullable)VTree;

- (NSDictionary *)fulllyParamsForEvent:(NSString * _Nullable)event
                         contextParams:(NSDictionary * _Nullable)contextParams
                       logActionParams:(NSDictionary * _Nullable)logActionParams
                                  node:(EventTracingVTreeNode * _Nullable)node
                               inVTree:(EventTracingVTree * _Nullable)VTree;
@end

@interface EventTracingEventOutput (MergeLogForH5)

- (void)outputEvent:(NSString *)event
           baseNode:(EventTracingVTreeNode *)baseNode
        useForRefer:(BOOL)useForRefer
             fromH5:(BOOL)fromH5
              elist:(NSArray<NSDictionary<NSString *,NSString *> *> *)elist
              plist:(NSArray<NSDictionary<NSString *,NSString *> *> *)plist
        positionKey:(NSString *)positionKey
             params:(NSDictionary<NSString *,NSString *> *)params;

@end

NS_ASSUME_NONNULL_END
