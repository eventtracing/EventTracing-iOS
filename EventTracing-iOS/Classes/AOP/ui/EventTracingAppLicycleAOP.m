//
//  EventTracingAppLicycleAOP.m
//  NEEventTracingEngine
//
//  Created by dl on 2021/2/25.
//

#import "EventTracingAppLicycleAOP.h"
#import "NEEventTracingEngine+Private.h"
#import <UIKit/UIKit.h>

@interface EventTracingAppLicycleAOP ()
@end


@implementation EventTracingAppLicycleAOP

NEEventTracingAOPInstanceImp

- (void)inject {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if ([NEEventTracingEngine sharedInstance].context.isUseCustomAppLifeCycle) {
            // 使用外部的生命周期事件
        } else {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ne_et_appDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ne_et_appWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ne_et_appDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
        }
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ne_et_appWillTerminate:) name:UIApplicationWillTerminateNotification object:nil];
    });
    [[NEEventTracingEngine sharedInstance] refreshAppInActiveState];
}

- (void)ne_et_appDidBecomeActive:(NSNotification *)noti {
    [[NEEventTracingEngine sharedInstance] appDidBecomeActive];
}

- (void)ne_et_appWillEnterForeground:(NSNotification *)noti {
    [[NEEventTracingEngine sharedInstance] appWillEnterForeground];
}

- (void)ne_et_appDidEnterBackground:(NSNotification *)noti {
    [[NEEventTracingEngine sharedInstance] appDidEnterBackground];
}

- (void)ne_et_appWillTerminate:(NSNotification *)noti {
    [[NEEventTracingEngine sharedInstance] appDidTerminate];
}

@end
