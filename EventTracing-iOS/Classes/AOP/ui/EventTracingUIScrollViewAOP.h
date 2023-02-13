//
//  EventTracingUIScrollViewAOP.h
//  BlocksKit
//
//  Created by dl on 2021/2/24.
//

#import <Foundation/Foundation.h>
#import "EventTracingAOPProtocol.h"
#import "UIView+EventTracingNodeImpressObserver.h"

NS_ASSUME_NONNULL_BEGIN

@interface EventTracingUIScrollViewAOP : NSObject<EventTracingAOPProtocol, EventTracingVTreeNodeImpressObserver>

@end

NS_ASSUME_NONNULL_END
