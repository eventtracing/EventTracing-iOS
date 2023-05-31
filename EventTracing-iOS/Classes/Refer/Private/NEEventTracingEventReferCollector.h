//
//  NEEventTracingEventReferCollector.h
//  NEEventTracing
//
//  Created by dl on 2021/4/8.
//

#import <Foundation/Foundation.h>
#import "NEEventTracingVTree.h"
#import "NEEventTracingVTreeNode.h"
#import "NEEventTracingEventAction.h"

NS_ASSUME_NONNULL_BEGIN

@interface NEEventTracingEventReferCollector : NSObject

- (void)appWillEnterForeground;

- (void)willImpressNode:(NEEventTracingVTreeNode *)node inVTree:(NEEventTracingVTree *)VTree;

@end

NS_ASSUME_NONNULL_END
