//
//  NEEventTracingFormattedReferBuilder.h
//  NEEventTracing
//
//  Created by dl on 2022/2/23.
//

#import <Foundation/Foundation.h>
#import "NEEventTracingFormattedRefer.h"

NS_ASSUME_NONNULL_BEGIN

@protocol NEEventTracingFormattedReferComponentBuilder <NSObject>

/// MARK: component s
@property(nonatomic, readonly) id<NEEventTracingFormattedReferComponentBuilder> (^withSesid)(void);

@property(nonatomic, readonly) id<NEEventTracingFormattedReferComponentBuilder> (^type)(NSString *value);
@property(nonatomic, readonly) id<NEEventTracingFormattedReferComponentBuilder> (^typeE)(void);
@property(nonatomic, readonly) id<NEEventTracingFormattedReferComponentBuilder> (^typeP)(void);

@property(nonatomic, readonly) id<NEEventTracingFormattedReferComponentBuilder> (^actseq)(NSInteger value);
@property(nonatomic, readonly) id<NEEventTracingFormattedReferComponentBuilder> (^pgstep)(NSInteger value);
@property(nonatomic, readonly) id<NEEventTracingFormattedReferComponentBuilder> (^spm)(NSString *value);
@property(nonatomic, readonly) id<NEEventTracingFormattedReferComponentBuilder> (^scm)(NSString *value);

/// MARK: mark s
@property(nonatomic, readonly) id<NEEventTracingFormattedReferComponentBuilder> (^undefinedXpath)(void);
@property(nonatomic, readonly) id<NEEventTracingFormattedReferComponentBuilder> (^er)(void);
@property(nonatomic, readonly) id<NEEventTracingFormattedReferComponentBuilder> (^h5)(void);

@end

@interface NEEventTracingFormattedReferBuilder : NSObject

+ (NEEventTracingFormattedReferBuilder *)build:(void(^)(id<NEEventTracingFormattedReferComponentBuilder> builder))block;
- (id<NEEventTracingFormattedRefer>)generateRefer;

@end

NS_ASSUME_NONNULL_END
