//
//  NEEventTracingAOPManager.m
//  BlocksKit
//
//  Created by dl on 2021/2/24.
//

#import "NEEventTracingAOPManager.h"

@interface NEEventTracingAOPManager ()
@property (nonatomic, strong) NSMutableArray<Class<NEEventTracingAOPProtocol>> *AOPClses;
@end

@implementation NEEventTracingAOPManager

+ (instancetype)defaultManager {
    static NEEventTracingAOPManager *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[NEEventTracingAOPManager alloc] init];
        instance.AOPClses = [@[] mutableCopy];
    });
    return instance;
}

- (void)registeAOPCls:(Class<NEEventTracingAOPProtocol>)AOPCls {
    if (![AOPCls conformsToProtocol:@protocol(NEEventTracingAOPProtocol)]) {
        return;
    }
    [self.AOPClses addObject:AOPCls];
}

- (void)fire {
    [self.AOPClses enumerateObjectsUsingBlock:^(Class clz, NSUInteger idx, BOOL * _Nonnull stop) {
        id<NEEventTracingAOPProtocol> AOPInstance = [clz AOPInstance];
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
