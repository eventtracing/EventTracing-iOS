//
//  NEEventTracingDelegateChain.h
//  BlocksKit
//
//  Created by dl on 2021/2/24.
//

#import <Foundation/Foundation.h>

typedef BOOL(^NE_ET_DelegateChainBlocklistBlock)(id _Nonnull object);

#define NE_ET_DelegateChainHock(mPrefix, P, propName, AOPCls, preSelectorNames, hockProtocols) \
NE_ET_DelegateChainHockBlacklist(mPrefix, P, propName, AOPCls, preSelectorNames, hockProtocols, @[])

#define NE_ET_DelegateChainHockBlacklist(mPrefix, P, propName, AOPCls, preSelectorNames, hockProtocols, blacklist) \
- (void)ne_et_ ## mPrefix ## _setDelegate:(id)delegate {\
    BOOL shouldReject = [blacklist bk_any:^BOOL(id obj) { \
        Class cls = NSClassFromString(obj); \
        if (!cls) return NO; \
        return [self.class isSubclassOfClass:cls] || [self isKindOfClass:cls]; \
    }]; \
    if (!delegate || shouldReject) { \
        self.propName = nil; \
        [self ne_et_ ## mPrefix ## _setDelegate:delegate]; \
        return; \
    } \
    if (self.propName != nil && [self.propName checkIfChainedToSelfInDelegate:delegate]) { \
        [self ne_et_ ## mPrefix ## _setDelegate:delegate]; \
    } else { \
        id interceptorObject = [AOPCls AOPInstance];\
        NEEventTracingDelegateChain *delegateChain = [NEEventTracingDelegateChain delegateChainWithOriginalDelegate:delegate protocols:(hockProtocols ?: @[@protocol(P)]) interceptorObjects:interceptorObject, nil]; \
        [preSelectorNames enumerateObjectsUsingBlock:^(NSString *selectorName, NSUInteger idx, BOOL * _Nonnull stop) {\
            SEL selector = NSSelectorFromString(selectorName);\
            if (!selector) return;\
            NSString *selectorString = NSStringFromSelector(selector);\
            selectorString = [selectorString stringByReplacingCharactersInRange:NSMakeRange(0,1) withString:[[selectorString substringToIndex:1] capitalizedString]];\
            SEL preSelector = NSSelectorFromString([NSString stringWithFormat:@"preCall%@", selectorString]);\
            [delegateChain registePreCallSelector:preSelector forSelector:selector forInterceptor:interceptorObject];\
        }];\
        [self ne_et_ ## mPrefix ## _setDelegate:(id)delegateChain]; \
        self.propName = delegateChain; \
    } \
}

NS_ASSUME_NONNULL_BEGIN

@interface NEEventTracingDelegateChain : NSProxy

@property(nonatomic, weak, readonly) id originalDelegate;
@property(nonatomic, weak, readonly) NSArray *interceptorObjects;

+ (instancetype)delegateChainWithOriginalDelegate:(id)originalDelegate
                                        protocols:(NSArray<Protocol *> *)protocols
                               interceptorObjects:(id)firstInterceptor, ... NS_REQUIRES_NIL_TERMINATION;
- (BOOL)containsObject:(id)object;
- (BOOL)checkIfChainedToSelfInDelegate:(id)delegate;

- (void)registePreCallSelector:(SEL)preCallSelector forSelector:(SEL)selector forInterceptor:(id)interceptor;

@end

NS_ASSUME_NONNULL_END
