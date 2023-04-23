//
//  EventTracingEventOutputChannel.h
//  BlocksKit
//
//  Created by dl on 2021/3/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// MARK: 日志输出的通道，可以配置多个
@class EventTracingEventOutput;
@protocol EventTracingEventOutputChannel <NSObject>

- (void)eventOutput:(EventTracingEventOutput *)eventOutput didOutputEvent:(NSString *)event json:(NSDictionary *)json;

@optional
- (void)eventOutput:(EventTracingEventOutput *)eventOutput
     didOutputEvent:(NSString *)event
               node:(EventTracingVTreeNode * _Nullable)node
               json:(NSDictionary *)json;

@end

NS_ASSUME_NONNULL_END
