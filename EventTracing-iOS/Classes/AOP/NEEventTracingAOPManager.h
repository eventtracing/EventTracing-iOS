//
//  NEEventTracingAOPManager.h
//  BlocksKit
//
//  Created by dl on 2021/2/24.
//

#import <Foundation/Foundation.h>
#import "NEEventTracingAOPProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface NEEventTracingAOPManager : NSObject

+ (instancetype) defaultManager;

- (void) registeAOPCls:(Class<NEEventTracingAOPProtocol>)AOPCls;
- (void) fire;

@end

NS_ASSUME_NONNULL_END
