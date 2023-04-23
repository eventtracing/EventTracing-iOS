//
//  EventTracingExceptionDelegate.h
//  BlocksKit
//
//  Created by dl on 2021/5/20.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol EventTracingExceptionDelegate <NSObject>

@optional
// param guard invalid exceptions
- (void)paramGuardExceptionKey:(NSString *)key
                          code:(NSInteger)code
                      paramKey:(NSString *)paramKey
                         regex:(NSString *)regex
                         error:(NSError *)error;

- (void)internalExceptionKey:(NSString *)key
                        code:(NSInteger)code
                     message:(NSString *)message
                        node:(EventTracingVTreeNode *)node
       shouldNotEqualToOther:(EventTracingVTreeNode *)otherNode;

- (void)internalExceptionKey:(NSString *)key
                        code:(NSInteger)code
                     message:(NSString *)message
                        node:(EventTracingVTreeNode *)node
    spmShouldNotEqualToOther:(EventTracingVTreeNode *)otherNode;

- (void)logicalMountEndlessLoopExceptionKey:(NSString *)key
                                       code:(NSInteger)code
                                    message:(NSString *)message
                                       view:(UIView *)view
                                viewToMount:(UIView *)viewToMount;

- (void)viewControllerDidNotLoadView:(UIViewController *)viewController message:(NSString *)message;

@end

NS_ASSUME_NONNULL_END
