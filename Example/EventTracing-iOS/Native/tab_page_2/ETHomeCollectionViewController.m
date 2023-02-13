//
//  ETHomeCollectionViewController.m
//  EventTracing-iOS_Example
//
//  Created by xxq on 2022/12/9.
//  Copyright © 2022 9446796. All rights reserved.
//

#import "ETHomeCollectionViewController.h"
#import "ETHomeCollectionViewCell.h"
#import "UIColor+ET.h"

@interface ETHomeCollectionViewController () <UICollectionViewDelegate, UICollectionViewDataSource>
@property(nonatomic, strong) NSMutableArray *dataSource;
@end

@implementation ETHomeCollectionViewController

- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        if (@available(iOS 13.0, *)) {
            UIImage *image = [UIImage systemImageNamed:@"square.and.arrow.down"];
            self.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"List" image:image tag:0];
        } else {
            // Fallback on earlier versions
        }
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.sectionInset = UIEdgeInsetsMake(0.f, 0.f, 20.f, 0.f);
    layout.minimumLineSpacing = 0.f;
    [self.collectionView setCollectionViewLayout:layout animated:YES];
    
    self.collectionView.backgroundColor = [UIColor clearColor];
    UIEdgeInsets safeArea = [UIApplication sharedApplication].delegate.window.safeAreaInsets;
    self.collectionView.contentInset = UIEdgeInsetsMake(0, 0, safeArea.bottom, 0);
    self.collectionView.scrollIndicatorInsets = _collectionView.contentInset;
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    [self.collectionView registerClass:ETHomeCollectionViewCell.class forCellWithReuseIdentifier:@"Item"];
    

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(et_appDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    
    [[EventTracingBuilder viewController:self pageId:@"page_tab_vc_2"] build:^(id<EventTracingLogNodeBuilder>  _Nonnull builder) {
        builder.visibleEdgeInsets(UIEdgeInsetsMake(0.f, 0.f, CGRectGetHeight(self.tabBarController.tabBar.bounds), 0.f))
        .params
        .set(@"drand48", @(drand48()).stringValue)
        .set(@"my_key1", @"my_valu1");
    }];

    [[EventTracingBuilder view:self.collectionView elementId:@"List"] build:^(id<EventTracingLogNodeBuilder>  _Nonnull builder) {
        builder.visibleEdgeInsetsTop(
                                     CGRectGetHeight(self.navigationController.navigationBar.bounds) +
                                     CGRectGetHeight([UIApplication sharedApplication].statusBarFrame))
        .params
        .pushContentWithBlock(^(id<EventTracingLogNodeParamContentIdBuilder>  _Nonnull content) {
            content.user(@"user1").ctrp(@"ctrp1");
        });
    }];
    
    [EventTracingBuilder batchBuildParams:^(id<EventTracingLogNodeBuilder>  _Nonnull builder) {
        builder
        .params
        .pushContentWithBlock(^(id<EventTracingLogNodeParamContentIdBuilder>  _Nonnull content) {
            content.cidtype(@"test_xxx", @"customtype").ctrp(@"testalg_xxx");
        })
        .set(@"param1", @"param1Value");
    } variableViews:self.view, self.collectionView, nil];
    
    [self.view addSubview:self.collectionView];
    self.collectionView.et_esEventEnable = YES;
//    [self.collectionView et_pipEventToAncestorNodeView:NE_ET_EVENT_ID_E_SLIDE];
    
    NSMutableArray *data = [@[] mutableCopy];
    for (int i=0; i<20; i++) {
        NSMutableArray *items = [@[] mutableCopy];
        for (int j=0; j<5; j++) {
            [items addObject:@{
                @"idx": [NSString stringWithFormat:@"%@-%@", @(i).stringValue, @(j).stringValue],
                @"color": [UIColor et_randomColorWithBrightness:0.8]
            }];
        }
        
        [data addObject:@{ @"sectionIdx": @(i), @"items": items.copy }];
    }
    self.dataSource = data;
    
    [[EventTracingEngine sharedInstance] logWithEvent:@"_homecustom_event" view:self.collectionView params:@{
        @"customEventParamsKey": @"CustomEventParamsValue"
    } eventAction:^(EventTracingEventActionConfig * _Nonnull config) {
        config.increaseActseq = YES;
    }];
}

#pragma mark - collection view
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return self.dataSource.count;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    NSDictionary *sectionData = [self.dataSource objectAtIndex:section];
    NSArray *items = [sectionData objectForKey:@"items"];
    return [items count];
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ETHomeCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Item" forIndexPath:indexPath];
    NSDictionary *sectionData = [self.dataSource objectAtIndex:indexPath.section];
    NSArray *items = [sectionData objectForKey:@"items"];
    [cell refreshWithData:[items objectAtIndex:indexPath.item]];
    [cell et_buildParams:^(id<EventTracingLogNodeParamsBuilder>  _Nonnull params) {
        params.position(indexPath.section * 100 + indexPath.item);
    }];
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(collectionView.bounds.size.width, 80.f);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    NSLog(@"[find ancestor]%@, %@", ET_FindAncestorNodeViewAt(cell), ET_FindAncestorNodeViewAt(cell, @"CollectionTab"));
    NSLog(@"Clicked at section: %@, item: %@, eventRefer: %@", @(indexPath.section).stringValue, @(indexPath.item).stringValue, ET_eventReferForView(cell));
}

- (void)et_appDidEnterBackground:(NSNotification *)noti {
    [[EventTracingEngine sharedInstance] logWithEvent:@"NE_ET_CollectionCustomEvent_APPInBackGround" view:self.collectionView params:@{
        @"appState": @(UIApplication.sharedApplication.applicationState).stringValue
    } eventAction:^(EventTracingEventActionConfig * _Nonnull config) {
        config.useForRefer = YES;
        config.increaseActseq = YES;
    }];
}

- (NSDictionary *)et_extraParams {
    return @{
        @"extra_drand48": @(drand48()).stringValue
    };
}

@end
