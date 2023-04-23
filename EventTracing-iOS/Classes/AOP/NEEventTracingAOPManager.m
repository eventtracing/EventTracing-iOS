//
//  EventTracingAOPManager.m
//  BlocksKit
//
//  Created by dl on 2021/2/24.
//

#import "EventTracingAOPManager.h"

@interface EventTracingAOPManager ()
@property (nonatomic, strong) NSMutableArray<Class<EventTracingAOPProtocol>> *AOPClses;
@end

@implementation EventTracingAOPManager

+ (instancetype)defaultManager {
    static EventTracingAOPManager *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[EventTracingAOPManager alloc] init];
        instance.AOPClses = [@[] mutableCopy];
    });
    return instance;
}

- (void)registeAOPCls:(Class<EventTracingAOPProtocol>)AOPCls {
    if (![AOPCls conformsToProtocol:@protocol(EventTracingAOPProtocol)]) {
        return;
    }
    [self.AOPClses addObject:AOPCls];
}

- (void)fire {
    [self.AOPClses enumerateObjectsUsingBlock:^(Class clz, NSUInteger idx, BOOL * _Nonnull stop) {
        id<EventTracingAOPProtocol> AOPInstance = [clz AOPInstance];
        if ([AOPInstance respondsToSelector:@selector(inject)]) {
            [AOPInstance inject];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([AOPInstance respondsToSelector:@selector(asyncInject)]) {
                [AOPInstance asyncInject];
            }
        });
    }];
}

@end
