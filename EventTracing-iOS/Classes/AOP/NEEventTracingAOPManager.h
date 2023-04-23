//
//  EventTracingAOPManager.h
//  BlocksKit
//
//  Created by dl on 2021/2/24.
//

#import <Foundation/Foundation.h>
#import "EventTracingAOPProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface EventTracingAOPManager : NSObject

+ (instancetype) defaultManager;

- (void) registeAOPCls:(Class<EventTracingAOPProtocol>)AOPCls;
- (void) fire;

@end

NS_ASSUME_NONNULL_END
