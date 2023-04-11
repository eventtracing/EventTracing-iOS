//
//  EventTracingAssociatedPros.h
//  BlocksKit
//
//  Created by dl on 2021/7/27.
//

#import <Foundation/Foundation.h>
#import "EventTracingDefines.h"
#import "EventTracingSentinel.h"
#import "EventTracingWeakObjectContainer.h"
#import "EventTracingVTree.h"
#import "EventTracingVTreeNode.h"

#import "UIView+EventTracing.h"

NS_ASSUME_NONNULL_BEGIN

@interface EventTracingAssociatedProsParamsCallback : NSObject
@property (nonatomic, copy, readonly) ET_AddParamsCallback callback;
@property (nonatomic, copy, readonly) ET_AddParamsCarryEventCallback carryEventCallback;
@property (nonatomic, copy, readonly) NSArray<NSString *> *events;
@end

__attribute__((objc_direct_members))
@interface EventTracingAssociatedPros : NSObject

+ (instancetype)associatedProsWithView:(UIView *)view __attribute__((objc_direct));

@property(nonatomic, weak, readonly) UIView *view;

// oid
@property(nonatomic, copy, readonly) NSString *pageId;
@property(nonatomic, copy, readonly) NSString *elementId;
@property(nonatomic, assign, readonly) BOOL isPage;
@property(nonatomic, assign, readonly) BOOL isElement;
@property(nonatomic, assign, getter=isRootPage) BOOL rootPage;
@property(nonatomic, assign, getter=isPageOcclusionEnable) BOOL pageOcclusionEnable;

// psrefer 不参与链路追踪
@property(nonatomic, assign, getter=isPsreferMuted) BOOL psreferMute;

/// 子页面，pv曝光埋点，可以生成refer (refer_type == 'subpage_pv')
@property(nonatomic, assign, getter=isSubpagePvToReferEnable) BOOL subpagePvToReferEnable;

/// 针对 rootpage，该值默认为 "ec|custom"
/// 针对 subpage，该值默认为 "none"
/// 所有可选值: all,  subpage_pv, ec, custom
/// 其中 custom 目前是除了 明确类型的 其他类型
/// all 是全部类型
/// subpage_pv 专指子页面曝光产生的refer
@property(nonatomic, assign) EventTracingPageReferConsumeOption pageReferConsumeOption;


// methods
- (void)setupOid:(NSString *)oid
          isPage:(BOOL)isPage
          params:(NSDictionary<NSString *, NSString *> * _Nullable)params __attribute__((objc_direct));

// params
@property(nonatomic, strong, readonly) NSMutableDictionary<NSString *, NSString *> *params;
@property(nonatomic, strong, readonly) NSMutableSet<NSString *> *checkedGuardParamKeys;

/// MARK: 对 block 的持有操作
@property(nonatomic, strong, readonly) NSArray<EventTracingAssociatedProsParamsCallback *> *paramCallbacks;
- (void)addParamsCallback:(ET_AddParamsCallback)callback forEvent:(NSString * _Nullable)event __attribute__((objc_direct));
- (void)addParamsCarryEventCallback:(ET_AddParamsCarryEventCallback)callback forEvents:(NSArray<NSString *> *)events __attribute__((objc_direct));

// others
@property(nonatomic, assign) ETNodeBuildinEventLogDisableStrategy buildinEventLogDisableStrategy;
@property(nonatomic, assign) NSUInteger position;

// virtual parent node

// visible & logical parent & auto mount
@property(nonatomic, assign) BOOL logicalVisible;
@property(nonatomic, assign) UIEdgeInsets visibleEdgeInsets;
@property(nonatomic, assign) ETNodeVisibleRectCalculateStrategy visibleRectCalculateStrategy;
@property(nonatomic, assign, getter=isAutoMountRootPage) BOOL autoMountRootPage;

@property(nonatomic, copy) NSString *logicalParentSPM;

// reuse
@property(nonatomic, copy, readonly) NSString *reuseIdentifier;
@property(nonatomic, copy, readonly) NSString *bizLeafIdentifier;
@property(nonatomic, assign, readonly) BOOL reuseIdentifierNeedsUpdate;
@property(nonatomic, strong, readonly) EventTracingSentinel *reuseSEQ;
@property(nonatomic, readonly) NSString *(^autoClassifyIdAppend)(NSString *identifier);
- (void)bindDataForReuse:(id)data __attribute__((objc_direct));
- (void)setResueIdentifierNeedsUpdate __attribute__((objc_direct));

// toids
@property(nonatomic, copy, nullable) NSArray<NSString *> *toids;

@end

/// MARK: Virtual Parent Node
__attribute__((objc_direct_members))
@interface EventTracingVirtualParentAssociatedPros : NSObject

+ (instancetype)associatedProsWithView:(UIView *)view __attribute__((objc_direct));

@property(nonatomic, weak, readonly) UIView *view;

@property(nonatomic, copy, nullable) NSString *virtualParentNodeElementId;
@property(nonatomic, copy, nullable) NSString *virtualParentNodePageId;
@property(nonatomic, copy) NSString *virtualParentNodeIdentifier;
@property(nonatomic, copy) NSDictionary *virtualParentNodeParams;
@property(nonatomic, assign, readonly) BOOL hasVirtualParentNode;

// 针对虚拟父节点，需要支持掉这俩配置
@property(nonatomic, assign) ETNodeBuildinEventLogDisableStrategy buildinEventLogDisableStrategy;
@property(nonatomic, assign) NSUInteger position;

- (void)setupVirtualParentElementId:(NSString *)elementId
                     nodeIdentifier:(id)nodeIdentifier
                             params:(NSDictionary<NSString *, NSString *> *)params __attribute__((objc_direct));

- (void)setupVirtualParentPageId:(NSString *)pageId
                  nodeIdentifier:(id)nodeIdentifier
                          params:(NSDictionary<NSString *, NSString *> *)params;

@end

NS_ASSUME_NONNULL_END
