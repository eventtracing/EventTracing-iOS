//
//  EventTracingTraversalRunner.h
//  BlocksKit
//
//  Created by dl on 2021/2/4.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class EventTracingTraversalRunner;
@protocol EventTracingTraversalRunnerDelegate <NSObject>
- (void) traversalRunner:(EventTracingTraversalRunner *)runner runWithRunModeMatched:(BOOL)runModeMatched;
@end

__attribute__((objc_direct_members))
@interface EventTracingTraversalRunner : NSObject

@property(nonatomic, assign, readonly) BOOL running;
@property(nonatomic, assign, readonly) BOOL paused;

@property(nonatomic, weak, nullable) id<EventTracingTraversalRunnerDelegate> delegate;
@property(nonatomic, copy, readonly) NSRunLoopMode currentRunMode;

- (void) run;
- (void) runWithRunloopMode:(NSRunLoopMode)runloopMode;
- (void) stop;

- (void) pause;
- (void) resume;

@end

NS_ASSUME_NONNULL_END
