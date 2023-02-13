//
//  EventTracingEventActionConfig.h
//  EventTracing
//
//  Created by dl on 2021/4/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface EventTracingEventActionConfig : NSObject
- (instancetype)init NS_UNAVAILABLE;
+(instancetype)new NS_UNAVAILABLE;

// 标识该自定义事件，可以作为下一个页面的 _pgrefer&_psrefer 来对接
// useForRefer == YES是, 忽略increaseActseq的值（当做YES对待），_actseq也会加1
@property(nonatomic, assign) BOOL useForRefer;
// 优先取这里的值，否则取 needIncreaseActseqForCustomLogEvent: 的设置
@property(nonatomic, assign) BOOL increaseActseq;

/// MARK: 针对H5场景，过来的埋点，在参与链路追踪的时候，
@property(nonatomic, assign) BOOL fromH5;

@end

NS_ASSUME_NONNULL_END
