//
//  NEEventTracingReferObserver.h
//  NEEventTracing
//
//  Created by dl on 2021/11/8.
//

#import <Foundation/Foundation.h>
#import "NEEventTracingVTree.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, NEETReferUpdateOption) {
    NEETReferUpdateOptionNone = 0,
    NEETReferUpdateOptionPsreferMute = 1 << 0L,
};

@protocol NEEventTracingReferObserver <NSObject>

@optional

/// hsrefer 更新时，会调用该方法
/// - Parameter hsrefer: hsrefer 字符串
- (void)hsreferNeedsUpdatedTo:(NSString *)hsrefer;

/// page 的pgrefer & psrefer 更新的时候，会调用该方法
/// - Parameters:
///   - pgrefer: pgrefer
///   - psrefer: psrefer
///   - node: 节点
///   - VTree: 节点对应的 VTree
- (void)pgreferNeedsUpdatedTo:(NSString *)pgrefer
                      psrefer:(NSString *)psrefer
                         node:(NEEventTracingVTreeNode *)node
                      inVTree:(NEEventTracingVTree *)VTree;

/// page 的pgrefer & psrefer 更新的时候，会调用该方法
/// - Parameters:
///   - pgrefer: pgrefer
///   - psrefer: psrefer
///   - node: 节点
///   - VTree: 节点对应的 VTree
///   - option: option，如果是 ETReferUpdateOptionPsreferMute 的话，监听者应该忽略
- (void)pgreferNeedsUpdatedTo:(NSString *)pgrefer
                      psrefer:(NSString *)psrefer
                         node:(NEEventTracingVTreeNode *)node
                      inVTree:(NEEventTracingVTree *)VTree
                       option:(NEETReferUpdateOption)option;

@end

NS_ASSUME_NONNULL_END
