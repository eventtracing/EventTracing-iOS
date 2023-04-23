//
//  UIView+EventTracingVTreeNodeExtraConfig.m
//  EventTracing-iOS
//
//  Created by 熊勋泉 on 2023/4/23.
//

#import "UIView+EventTracingVTreeNodeExtraConfig.h"
#import "UIView+EventTracingPrivate.h"
#include <objc/runtime.h>

static NSDictionary<NSString *, NSString *> * _ET_GetSuffixToSelectorMapFromProtocol(Protocol * protocol)
{
    NSMutableDictionary<NSString *, NSString *> * suffixToSelName = [NSMutableDictionary dictionary];
    {
        /// required
        unsigned int count = 0;
        struct objc_method_description  * desc =
        protocol_copyMethodDescriptionList(protocol,
                                           YES,
                                           YES,
                                           &count);
        
        for (int i = 0; i < count; i++) {
            struct objc_method_description temp = desc[i];
            NSString * selName = NSStringFromSelector(temp.name);
            NSArray<NSString *> * selComponents = [selName componentsSeparatedByString:@"_"];
            NSString * selSuffix = [selComponents lastObject];
            if (selSuffix.length > 0) {
                suffixToSelName[selSuffix] = selName;
            }
        }
        free(desc);
    }
    {
        /// optional
        unsigned int count = 0;
        struct objc_method_description  * desc =
        protocol_copyMethodDescriptionList(protocol,
                                           NO,
                                           YES,
                                           &count);
        
        for (int i = 0; i < count; i++) {
            struct objc_method_description temp = desc[i];
            NSString * selName = NSStringFromSelector(temp.name);
            NSArray<NSString *> * selComponents = [selName componentsSeparatedByString:@"_"];
            NSString * selSuffix = [selComponents lastObject];
            if (selSuffix.length > 0) {
                suffixToSelName[selSuffix] = selName;
            }
        }
        free(desc);
    }
    return [suffixToSelName copy];
}

static NSDictionary<NSString *, NSString *> * _ET_GetNewSelectorMapFromExternalProtocol(Protocol * oriProtocol, Protocol * externalProtocol)
{
    if (!externalProtocol || externalProtocol == oriProtocol) {
        return nil; //内置的协议，直接用原始方法
    }
    NSDictionary<NSString *, NSString *> * suffixToSelName = _ET_GetSuffixToSelectorMapFromProtocol(oriProtocol);
    NSDictionary<NSString *, NSString *> * externalSuffixToSelName = _ET_GetSuffixToSelectorMapFromProtocol(externalProtocol);
    NSMutableDictionary<NSString *, NSString *> * selNameToSelNameResult = [NSMutableDictionary dictionary];
    
    [suffixToSelName enumerateKeysAndObjectsUsingBlock:^(NSString * suffix, NSString * selName, BOOL * stop) {
        NSString * externalSelName = [externalSuffixToSelName objectForKey:suffix];
        if (externalSelName.length > 0) {
            [selNameToSelNameResult setObject:externalSelName forKey:selName];
        }
    }];
    return selNameToSelNameResult;
}

static NSMutableDictionary <NSString *, NSDictionary<NSString *, NSString *> *> * _ET_GetProtocolToCallSelectorMap(void)
{
    static NSMutableDictionary <NSString *, NSDictionary<NSString *, NSString *> *> * s_protocolToCallSelectorMap;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_protocolToCallSelectorMap = [NSMutableDictionary dictionary];
    });
    return s_protocolToCallSelectorMap;
}

static NSDictionary<NSString *, NSString *> * ET_GetForwardMapByOriProtocol(Protocol *oriProtocol)
{
    return [_ET_GetProtocolToCallSelectorMap() objectForKey:NSStringFromProtocol(oriProtocol)];
}

void ET_ReplaceProtocolByExternalProtocol(Protocol * oriProtocol, Protocol * newProtocol)
{
    [_ET_GetProtocolToCallSelectorMap() setObject:_ET_GetNewSelectorMapFromExternalProtocol(oriProtocol, newProtocol) forKey:NSStringFromProtocol(oriProtocol)];
}


@interface EventTracingConfigExternalProtocolForwarder ()
@property (nonatomic, weak) id target;
@property (nonatomic, strong) Protocol * oriProtocol;
@end


@implementation EventTracingConfigExternalProtocolForwarder

+ (instancetype)forwarderForTarget:(id)target protocol:(Protocol *)oriProtocol
{
    EventTracingConfigExternalProtocolForwarder *forwarder = [[EventTracingConfigExternalProtocolForwarder alloc] init];
    forwarder.target = target;
    return forwarder;
}

/**
 支持外部传入协议清单：
 @code
 EventTracingLogNodeDynamicParamsBuilder
    => `- (void)et_makeDynamicParams:(id <EventTracingLogNodeParamsBuilder>)builder;`
 EventTracingVTreeNodeExtraConfigProtocol
    => `- (NSArray<NSString *> *)et_validForContainingSubNodeOids;`
 EventTracingVTreeNodeDynamicParamsProtocol
    => `- (NSDictionary *)et_dynamicParams;`
 @endcode
 */
- (NSDictionary *)et_dynamicParams {
    NSString * selName = [ET_GetForwardMapByOriProtocol(self.oriProtocol) objectForKey:NSStringFromSelector(_cmd)];
    if (selName.length == 0) {
        return [self.target et_validForContainingSubNodeOids];
    }
    return [self.target performSelector:NSSelectorFromString(selName)];
}

- (void)et_makeDynamicParams:(id <EventTracingLogNodeParamsBuilder>)builder {
    NSString * selName = [ET_GetForwardMapByOriProtocol(self.oriProtocol) objectForKey:NSStringFromSelector(_cmd)];
    if (selName.length == 0) {
        return [self.target et_makeDynamicParams:builder];
    }
    return [self.target performSelector:NSSelectorFromString(selName) withObject:builder];
}

- (NSArray<NSString *> *)et_validForContainingSubNodeOids {
    NSString * selName = [ET_GetForwardMapByOriProtocol(self.oriProtocol) objectForKey:NSStringFromSelector(_cmd)];
    if (selName.length == 0) {
        return [self.target et_validForContainingSubNodeOids];
    }
    return [self.target performSelector:NSSelectorFromString(selName)];
}

@end


