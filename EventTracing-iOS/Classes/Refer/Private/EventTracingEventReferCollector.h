//
//  EventTracingEventReferCollector.h
//  EventTracing
//
//  Created by dl on 2021/4/8.
//

#import <Foundation/Foundation.h>
#import "EventTracingVTree.h"
#import "EventTracingVTreeNode.h"
#import "EventTracingEventAction.h"

NS_ASSUME_NONNULL_BEGIN

@interface EventTracingEventReferCollector : NSObject

- (void)appWillEnterForeground;

- (void)willImpressNode:(EventTracingVTreeNode *)node inVTree:(EventTracingVTree *)VTree;

@end

NS_ASSUME_NONNULL_END
