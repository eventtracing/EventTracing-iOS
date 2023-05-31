//
//  NEEventTracingVTreeNode+Private.h
//  NEEventTracing
//
//  Created by dl on 2021/3/11.
//

#import "NEEventTracingVTreeNode.h"
#import "NEEventTracingSentinel.h"
#import "NEEventTracingFormattedRefer.h"

NS_ASSUME_NONNULL_BEGIN

#define LOCK        dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
#define UNLOCK      dispatch_semaphore_signal(_lock);

extern NSString * const kNEETAddParamCallbackObjectkey;

/// MARK: 节点校验-辅助功能
typedef NS_ENUM(NSInteger, NEEventTracingNodeValidMountType) {
    NEEventTracingNodeValidMountTypeNone = 0,
    NEEventTracingNodeValidMountTypeManual,
    NEEventTracingNodeValidMountTypeAuto
};

@interface NEEventTracingVTreeNode () {
    __weak UIView *_view;
    __weak NEEventTracingVTreeNode *_parentNode;
    __weak NEEventTracingVTree *_VTree;
}

@property(nonatomic, assign, readwrite) NSUInteger position;

@property(nonnull, strong) dispatch_semaphore_t lock;
@property(nonatomic, assign, readwrite) BOOL visible;
@property(nonatomic, assign, readwrite) CGRect visibleRect;
@property(nonatomic, assign, readwrite) CGRect viewVisibleRectOnScreen;
@property(nonatomic, assign, readwrite) CGFloat impressMaxRatio;
@property(nonatomic, assign, readwrite) NSTimeInterval beginTime;
@property(nonatomic, assign) BOOL hasBindData;

/// MARK: 用于 diff 使用
@property(nonatomic, copy) NSString *diffIdentifier;
@property(nonatomic, assign) BOOL diffIdentifiershouldUpdate;

@property(nonatomic, assign, readwrite, getter=isBlockedBySubPage) BOOL blockedBySubPage;         // 被子page遮挡
@property(nonatomic, assign) BOOL coundAutoMountOtherNodes; // 是否可以自动挂载其他节点
@property(nonatomic, strong, nullable) NSArray<NSString *> *validForContainingSubNodeOids;

@property(nonatomic, assign) BOOL hasSubPageNodeMarkAsRootPage;     // 是否存在子节点 pageNodeMarkAsRootPage == YES
@property(nonatomic, assign) BOOL pageNodeMarkAsRootPage;           // 当前节点是否被标识为要作为root page

/// MARK: valid => manual/auto mount
@property(nonatomic, assign) NEEventTracingNodeValidMountType validMountType;

/// MARK: for rootpageNode/rootNode
// 1. 当前root page范围内的互动深度(找不到rootpageNode，会降级到rootNode)
// 2. 互动的时候，会+1
// 3. 当当前节点重新曝光的时候，actseq清零
// 4. 仅仅当节点是rootpageNode/rootNode的时候，才有值
@property(nonatomic, strong, nullable) NEEventTracingSentinel *actseqSentinel;

// 如果该节点是根节点，曝光的时候，所对应的 pv refer
@property(nonatomic, strong, nullable) id<NEEventTracingFormattedRefer> rootPagePVFormattedRefer;

@property(nonatomic, strong) NSMutableArray<NEEventTracingVTreeNode *> *innerSubNodes;

@property(nonatomic, copy, readonly) NSDictionary<NSString *, NSString *> *innerStaticParams;
@property(nonatomic, copy, readonly) NSDictionary<NSString *, NSString *> *dynamicParams;
@property(nonatomic, copy, readonly) NSDictionary<NSString *, NSDictionary<NSString *, NSString *> *> *callbackParams;
@property(nonatomic, copy, readonly) NSDictionary<NSString *, NSString *> *innerValidationParams;

+ (instancetype)buildWithView:(UIView *)view;

+ (instancetype)buildVirtualNodeWithOid:(NSString *)oid
                                 isPage:(BOOL)isPage
                             identifier:(NSString *)identifier
                               position:(NSUInteger)position
         buildinEventLogDisableStrategy:(NEETNodeBuildinEventLogDisableStrategy)buildinEventLogDisableStrategy
                                 params:(NSDictionary * _Nullable)params;

/// MARK: 下面方法只在主线程
- (void)associateToVTree:(NEEventTracingVTree *)VTree;
- (void)markAsRoot;

- (void)markIgnoreRefer;

- (void)updateStaticParams:(NSDictionary<NSString *, NSString *> * _Nullable)staticParams;
- (void)updatePosition:(NSUInteger)position;    // position 不参与identifier计算，所以position修改的时候，也需要立刻同步到node上，参与spm的生成
- (void)refreshDynsmicParamsIfNeeded;
- (void)refreshDynsmicParamsIfNeededForEvent:(NSString *)event;
- (void)doUpdateDynamicParams;

- (void)setupParentNode:(NEEventTracingVTreeNode * _Nullable)parentNode;
- (void)pushSubNode:(NEEventTracingVTreeNode *)subNode;
- (void)removeSubNode:(NEEventTracingVTreeNode *)subNode;
- (void)updateParentNodesHasSubpageNodeMarkAsRootPageIfNeeded;

/// MARK: refer相关
- (void)nodeWillImpress;
- (NSUInteger)doIncreaseActseq;

- (void)syncToNode:(NEEventTracingVTreeNode *)node;
- (void)pageNodeMarkFromRefer:(NSString *)pgrefer psrefer:(NSString *)psrefer;

- (NEEventTracingVTreeNode * _Nullable)findToppestNode:(BOOL)onlyPageNode;

@end

NS_ASSUME_NONNULL_END
