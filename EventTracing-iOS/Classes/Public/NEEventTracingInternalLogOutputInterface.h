//
//  NEEventTracingInternalLogOutputInterface.h
//  NEEventTracing
//
//  Created by dl on 2021/5/19.
//

#import <Foundation/Foundation.h>
#import "NEEventTracingDefines.h"

NS_ASSUME_NONNULL_BEGIN

@protocol NEEventTracingInternalLogOutputInterface <NSObject>

- (void)logLevel:(ETLogLevel)level content:(NSString *)content;

@end

NS_ASSUME_NONNULL_END
