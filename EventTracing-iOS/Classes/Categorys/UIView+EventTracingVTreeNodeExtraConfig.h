//
//  UIView+EventTracingVTreeNodeExtraConfig.h
//  EventTracing-iOS
//
//  Created by 熊勋泉 on 2023/4/23.
//

#import <UIKit/UIKit.h>
#import "EventTracingVTreeNodeExtraConfigProtocol.h"

NS_ASSUME_NONNULL_BEGIN


FOUNDATION_EXPORT
NSDictionary<NSString *, NSString *> * ET_GetVTreeNodeExtraConfigNewSelectorMap(void);

FOUNDATION_EXPORT
void ET_SetVTreeNodeExtraConfigNewSelectorMapByProtocol(Protocol * protocol);


@interface UIViewController (EventTracingVTreeNodeExtraConfig) <EventTracingVTreeNodeExtraConfigProtocol>
@end


@interface UIView (EventTracingVTreeNodeExtraConfig) <EventTracingVTreeNodeExtraConfigProtocol>
@end


@interface EventTracingVTreeNodeExtraConfigInfoForwarder : NSObject <EventTracingVTreeNodeExtraConfigProtocol>
+ (instancetype)forwarderForTarget:(id)target;
@end

#define ET_GetVTreeNodeExtraConfigInfo(_Target, _Sel) [[EventTracingVTreeNodeExtraConfigInfoForwarder forwarderForTarget:_Target] _Sel]

NS_ASSUME_NONNULL_END
