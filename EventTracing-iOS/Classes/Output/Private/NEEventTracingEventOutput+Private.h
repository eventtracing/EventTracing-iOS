//
//  NEEventTracingEventOutput+Private.h
//  BlocksKit
//
//  Created by dl on 2021/3/24.
//

#import "NEEventTracingEventOutput.h"
#import "NEEventTracingContext.h"
#import "UIView+EventTracingPrivate.h"

NS_ASSUME_NONNULL_BEGIN

@interface NEEventTracingEventOutput () <NEEventTracingContextOutputFormatterBuilder, NEEventTracingContextOutputParamsFilterBuilder>

@property(nonatomic, strong) NSHashTable<id<NEEventTracingEventOutputChannel>> *outputChannels;
@property(nonatomic, strong) NSHashTable<id<NEEventTracingOutputParamsFilter>> *outputParamsFilters;
@property(nonatomic, strong) NSMutableDictionary *innerStaticPublicParams;
@property(nonatomic, strong, nullable) NSMutableDictionary *innerCurrentActivePublicParams;

- (void)outputEvent:(NSString *)event
      contextParams:(NSDictionary * _Nullable)contextParams
    logActionParams:(NSDictionary * _Nullable)logActionParams
               node:(NEEventTracingVTreeNode *)node
            inVTree:(NEEventTracingVTree *)VTree;

- (void)outputEventWithoutNode:(NSString *)event contextParams:(NSDictionary * _Nullable)contextParams;

- (NSDictionary *)publicParamsForEvent:(NSString * _Nullable)event
                                  node:(NEEventTracingVTreeNode * _Nullable)node
                               inVTree:(NEEventTracingVTree * _Nullable)VTree;

- (NSDictionary *)fulllyParamsForEvent:(NSString * _Nullable)event
                         contextParams:(NSDictionary * _Nullable)contextParams
                       logActionParams:(NSDictionary * _Nullable)logActionParams
                                  node:(NEEventTracingVTreeNode * _Nullable)node
                               inVTree:(NEEventTracingVTree * _Nullable)VTree;
@end

@interface NEEventTracingEventOutput (MergeLogForH5)

- (void)outputEvent:(NSString *)event
           baseNode:(NEEventTracingVTreeNode *)baseNode
        useForRefer:(BOOL)useForRefer
             fromH5:(BOOL)fromH5
              elist:(NSArray<NSDictionary<NSString *,NSString *> *> *)elist
              plist:(NSArray<NSDictionary<NSString *,NSString *> *> *)plist
        positionKey:(NSString *)positionKey
             params:(NSDictionary<NSString *,NSString *> *)params;

@end

NS_ASSUME_NONNULL_END
