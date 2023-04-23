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

static NSDictionary<NSString *, NSString *> * _ET_GetNewSelectorMapFromExternalProtocol(Protocol * externalProtocol)
{
    Protocol * oriProtocol = @protocol(EventTracingVTreeNodeExtraConfigProtocol);
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

static NSDictionary<NSString *, NSString *> * s_VTreeNodeExtraConfigSelectorMap = nil;

NSDictionary<NSString *, NSString *> * ET_GetVTreeNodeExtraConfigNewSelectorMap(void)
{
    return s_VTreeNodeExtraConfigSelectorMap;
}

void ET_SetVTreeNodeExtraConfigNewSelectorMapByProtocol(Protocol * protocol)
{
    s_VTreeNodeExtraConfigSelectorMap = _ET_GetNewSelectorMapFromExternalProtocol(protocol);
}

@implementation UIViewController (EventTracingVTreeNodeExtraConfig)
#pragma mark - EventTracingVTreeNodeExtraConfigProtocol
- (NSArray<NSString *> *)et_validForContainingSubNodeOids { return [self.p_et_view et_validForContainingSubNodeOids]; }
@end



@implementation UIView (EventTracingVTreeNodeExtraConfig)
#pragma mark - EventTracingVTreeNodeExtraConfigProtocol
- (NSArray<NSString *> *)et_validForContainingSubNodeOids { return @[]; }
@end




@interface EventTracingVTreeNodeExtraConfigInfoForwarder ()
@property (nonatomic, weak) id target;
@end

@implementation EventTracingVTreeNodeExtraConfigInfoForwarder

+ (instancetype)forwarderForTarget:(id)target
{
    EventTracingVTreeNodeExtraConfigInfoForwarder *forwarder = [[EventTracingVTreeNodeExtraConfigInfoForwarder alloc] init];
    forwarder.target = target;
    return forwarder;
}

- (NSArray<NSString *> *)et_validForContainingSubNodeOids {
    NSString * selName = [ET_GetVTreeNodeExtraConfigNewSelectorMap() objectForKey:NSStringFromSelector(_cmd)];
    if (selName.length == 0) {
        return [self.target performSelector:_cmd];
    }
    return [self.target performSelector:NSSelectorFromString(selName)];
}
@end


