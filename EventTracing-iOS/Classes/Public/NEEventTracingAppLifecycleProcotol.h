//
//  EventTracingAppLifecycleProcotol.h
//  EventTracing
//
//  Created by dl on 2021/3/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol EventTracingAppLifecycleProcotol <NSObject>

@required
- (void)appViewController:(UIViewController *)controller changedToAppear:(BOOL)appear;
- (void)appDidBecomeActive;
- (void)appWillEnterForeground;
- (void)appDidEnterBackground;
- (void)appDidTerminate;

@end

NS_ASSUME_NONNULL_END
