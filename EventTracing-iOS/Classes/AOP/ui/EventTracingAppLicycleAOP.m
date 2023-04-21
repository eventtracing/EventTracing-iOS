//
//  EventTracingAppLicycleAOP.m
//  EventTracingEngine
//
//  Created by dl on 2021/2/25.
//

#import "EventTracingAppLicycleAOP.h"
#import "EventTracingEngine+Private.h"


@interface EventTracingAppLicycleAOP ()
@end

@implementation EventTracingAppLicycleAOP

EventTracingAOPInstanceImp

- (void)inject {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if ([EventTracingEngine sharedInstance].context.isUseCustomAppLifeCycle) {
            // 使用外部的生命周期事件
        } else {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(et_appDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(et_appWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(et_appDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
        }
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(et_appWillTerminate:) name:UIApplicationWillTerminateNotification object:nil];
    });
    
    [[EventTracingEngine sharedInstance] refreshAppInActiveState];
}

- (void)et_appDidBecomeActive:(NSNotification *)noti {
    [[EventTracingEngine sharedInstance] appDidBecomeActive];
}

- (void)et_appWillEnterForeground:(NSNotification *)noti {
    [[EventTracingEngine sharedInstance] appWillEnterForeground];
}

- (void)et_appDidEnterBackground:(NSNotification *)noti {
    [[EventTracingEngine sharedInstance] appDidEnterBackground];
}

- (void)et_appWillTerminate:(NSNotification *)noti {
    [[EventTracingEngine sharedInstance] appDidTerminate];
}

@end
