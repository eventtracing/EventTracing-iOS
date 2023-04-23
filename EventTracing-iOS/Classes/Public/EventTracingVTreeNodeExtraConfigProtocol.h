//
//  EventTracingVTreeNodeExtraConfigProtocol.h
//  EventTracing
//
//  Created by dl on 2021/4/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// MARK: 针对 page 节点，一些额外的配置
/// MARK: 注意⚠️目前仅支持添加无参数的 getter 方法⚠️
@protocol EventTracingVTreeNodeExtraConfigProtocol <NSObject>

// 如果设置了oids列表，遍历结果中如果该节点未包含oids列表中的任何节点，则该节点置为invalid, 并且不可见
// 该节点名下必须要包含oids中的一个才是valid，而且该节点名下也只能挂载oids列表的节点（自动逻辑挂载除外）
// 实际场景: app处于主屏幕(main)的时候，如果当前有一个tab正在展示，则该main节点有效
//         当处于别的二级页面的时候，main无效
//         当从正在打开二级页面的时候，main有效，但是只有tab vc才能作为其子节点，二级页面此时就处于main的同级别节点
- (NSArray<NSString *> *)et_validForContainingSubNodeOids;

@end

NS_ASSUME_NONNULL_END
