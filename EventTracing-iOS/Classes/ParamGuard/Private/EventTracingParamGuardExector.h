//
//  EventTracingParamGuardExector.h
//  BlocksKit
//
//  Created by dl on 2021/5/20.
//

#import <Foundation/Foundation.h>
#import "EventTracingParamGuardConfiguration.h"
#import "EventTracingDefines.h"

NS_ASSUME_NONNULL_BEGIN

@interface EventTracingParamGuardExector : NSObject <EventTracingParamGuardConfiguration>

- (void)asyncDoDispatchCheckTask:(void(^)(void))block;

- (BOOL)checkEventKeyValid:(NSString *)eventKey error:(NSError ** _Nullable)error;
- (BOOL)checkPublicParamKeyValid:(NSString *)publicParamKey error:(NSError ** _Nullable)error;
- (BOOL)checkUserParamKeyValid:(NSString *)userParamKey error:(NSError ** _Nullable)error;

@end

NS_ASSUME_NONNULL_END
