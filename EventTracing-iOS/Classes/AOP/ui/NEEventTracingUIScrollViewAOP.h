//
//  NEEventTracingUIScrollViewAOP.h
//  BlocksKit
//
//  Created by dl on 2021/2/24.
//

#import <Foundation/Foundation.h>
#import "NEEventTracingAOPProtocol.h"
#import "UIView+EventTracingNodeImpressObserver.h"

NS_ASSUME_NONNULL_BEGIN

@interface NEEventTracingUIScrollViewAOP : NSObject<NEEventTracingAOPProtocol, NEEventTracingVTreeNodeImpressObserver>

@end

NS_ASSUME_NONNULL_END
