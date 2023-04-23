//
//  UIView+EventTracingVTreeNodeExtraConfig.h
//  EventTracing-iOS
//
//  Created by 熊勋泉 on 2023/4/23.
//

#import <UIKit/UIKit.h>
#import "EventTracingVTreeNodeExtraConfigProtocol.h"
#import "EventTracingBuilder.h"
#import "UIView+EventTracing.h"

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

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT
void ET_ReplaceProtocolByExternalProtocol(Protocol * oriProtocol, Protocol * newProtocol);



@interface EventTracingConfigExternalProtocolForwarder : NSObject <
EventTracingVTreeNodeExtraConfigProtocol,
EventTracingVTreeNodeDynamicParamsProtocol,
EventTracingLogNodeDynamicParamsBuilder>

+ (instancetype)forwarderForTarget:(id)target protocol:(Protocol *)oriProtocol;
@end

#define ET_CallMethodByProtocol(_Target, _Protocol, _Sel) [[EventTracingConfigExternalProtocolForwarder forwarderForTarget:_Target protocol:@protocol(_Protocol)] _Sel]

#define ET_CallVTreeNodeExtraConfig(_Target, _Sel) ET_CallMethodByProtocol(_Target, EventTracingVTreeNodeExtraConfigProtocol, _Sel)
#define ET_CallLogNodeDynamicParamsBuilder(_Target, _Sel) ET_CallMethodByProtocol(_Target, EventTracingLogNodeDynamicParamsBuilder, _Sel)
#define ET_CallVTreeNodeDynamicParams(_Target, _Sel) ET_CallMethodByProtocol(_Target, EventTracingVTreeNodeDynamicParamsProtocol, _Sel)

NS_ASSUME_NONNULL_END
