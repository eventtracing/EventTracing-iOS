//
//  EventTracingDelegateChain.m
//  BlocksKit
//
//  Created by dl on 2021/2/24.
//

#import "EventTracingDelegateChain.h"
#import <BlocksKit/BlocksKit.h>
#import <objc/runtime.h>

@interface EventTracingDelegateChain ()
@property(nonatomic, weak, readwrite) id originalDelegate;
@property(nonatomic, strong) NSArray<Protocol *> *originalDelegateProtocols;
@property(nonatomic, strong) NSMapTable<id, NSMutableDictionary<NSString *, NSString *> *> *weakInterceptorObjects;
@end

@implementation EventTracingDelegateChain

+ (instancetype)delegateChainWithOriginalDelegate:(id)originalDelegate
                                        protocols:(NSArray<Protocol *> *)protocols
                               interceptorObjects:(id)firstInterceptor, ... NS_REQUIRES_NIL_TERMINATION {
    EventTracingDelegateChain *delegateChain = [EventTracingDelegateChain alloc];
    delegateChain.originalDelegate = originalDelegate;
    delegateChain.originalDelegateProtocols = protocols;
    delegateChain.weakInterceptorObjects = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsWeakMemory valueOptions:NSPointerFunctionsStrongMemory];
    
    va_list args;
    va_start(args, firstInterceptor);
    for (id object = firstInterceptor; object != nil; object = va_arg(args, id)) {
        [delegateChain.weakInterceptorObjects setObject:@{}.mutableCopy forKey:object];
    }
    va_end(args);
    
    return delegateChain;
}

- (BOOL)checkIfChainedToSelfInDelegate:(id)delegate {
    return [delegate respondsToSelector:@selector(__checkIfDelegateChainContainsEventTracingChain__)] && [delegate __checkIfDelegateChainContainsEventTracingChain__];
}

- (void)registePreCallSelector:(SEL)preCallSelector forSelector:(SEL)selector forInterceptor:(id)interceptor {
    if ([interceptor isProxy]) {
        return;
    }
    
    NSMethodSignature *preSig = [[(NSObject *)interceptor class] instanceMethodSignatureForSelector:preCallSelector];
    NSMethodSignature *sig = [[(NSObject *)interceptor class] instanceMethodSignatureForSelector:selector];
    if (preSig.numberOfArguments != sig.numberOfArguments) {
        return;
    }
    
    BOOL equal = [preSig methodReturnLength] == [sig methodReturnLength] && strcmp([preSig methodReturnType], [sig methodReturnType]) == 0;
    if (!equal) {
        return;
    }
    
    for (int i=0; i<preSig.numberOfArguments; i++) {
        if (strcmp([preSig getArgumentTypeAtIndex:i], [sig getArgumentTypeAtIndex:i]) != 0) {
            equal = NO;
            break;
        }
    }
    
    if (!equal) {
        return;
    }
    
    [[self.weakInterceptorObjects objectForKey:interceptor] setObject:NSStringFromSelector(preCallSelector) forKey:NSStringFromSelector(selector)];
}

- (id)forwardingTargetForSelector:(SEL)selector {
    BOOL originalDelegateOK = [_originalDelegate respondsToSelector:selector];
    
    id interceptorObject = [self _firstInterceptorObjectRespondingToSelector:selector];
    BOOL interceptorsOK = interceptorObject != nil;
    
    if (originalDelegateOK && interceptorsOK) {
        return nil;
    } else if (originalDelegateOK) {
        return _originalDelegate;
    } else if (interceptorsOK) {
        BOOL shouldCallPreSelector = [self.weakInterceptorObjects.objectEnumerator.allObjects bk_any:^BOOL(NSMutableDictionary<NSString *,NSString *> *obj) {
            return [obj.allKeys containsObject:NSStringFromSelector(selector)];
        }];
        if (!shouldCallPreSelector) {
            return interceptorObject;
        }
    }

    return nil;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)selector {
    id interceptorObject = [self _firstInterceptorObjectRespondingToSelector:selector];
    if (interceptorObject != nil) {
        return [interceptorObject methodSignatureForSelector:selector];
    }
    
    BOOL originalDelegateOK = [_originalDelegate respondsToSelector:selector];
    if (originalDelegateOK) {
        return [_originalDelegate methodSignatureForSelector:selector];
    }
    
    return [NSMethodSignature signatureWithObjCTypes:"@@:"];
}

- (void)forwardInvocation:(NSInvocation *)invocation {
    // pre
    [self et_preForwardInvocation:invocation];
    
    // original
    if ([_originalDelegate respondsToSelector:invocation.selector]) {
        [invocation setTarget:_originalDelegate];
        [invocation invoke];
    }
    
    // after
    [self et_afterForwardInvocation:invocation];
}

- (void)et_preForwardInvocation:(NSInvocation *)invocation {
    [[self _allInterceptorObjectsRespondingToSelector:invocation.selector] enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSDictionary *selectorMap = [self.weakInterceptorObjects objectForKey:obj];
        SEL preCallSelector = NSSelectorFromString([selectorMap objectForKey:NSStringFromSelector(invocation.selector)]);
        if (!preCallSelector) {
            return;
        }
        
        [self et_doCallSelector:preCallSelector fromInvocation:invocation target:obj];
    }];
}

- (void)et_afterForwardInvocation:(NSInvocation *)invocation {
    [[self _allInterceptorObjectsRespondingToSelector:invocation.selector] enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self et_doCallSelector:invocation.selector fromInvocation:invocation target:obj];
    }];
}

- (void)et_doCallSelector:(SEL)selector fromInvocation:(NSInvocation *)invocation target:(id)target {
    NSMethodSignature *sig = [invocation methodSignature];
    NSInvocation *interceptInvocation = [NSInvocation invocationWithMethodSignature:sig];

    void *argBuf = NULL;
    for (NSUInteger i = 1; i < [sig numberOfArguments]; i++) {
        const char *type = [sig getArgumentTypeAtIndex:i];
        NSUInteger argSize;
        NSGetSizeAndAlignment(type, &argSize, NULL);

        if (!(argBuf = reallocf(argBuf, argSize))) {
            return;
        }
        
        [invocation getArgument:argBuf atIndex:i];
        [interceptInvocation setArgument:argBuf atIndex:i];
    }
    
    [interceptInvocation setTarget:target];
    [interceptInvocation setSelector:selector];
    [interceptInvocation invoke];
    
    free(argBuf);
}

- (BOOL)respondsToSelector:(SEL)selector {
    if (selector == @selector(__checkIfDelegateChainContainsEventTracingChain__)) {
        return YES;
    }
    
    if ([_originalDelegate respondsToSelector:selector]) {
        return YES;
    }
    
    return [self _allInterceptorObjectsRespondingToSelector:selector].count != 0;
}

- (BOOL)conformsToProtocol:(Protocol *)aProtocol {
    if ([_originalDelegate conformsToProtocol:aProtocol]) {
        return YES;
    }
    
    return [[self interceptorObjects] bk_any:^BOOL(id obj) {
        return [obj conformsToProtocol:aProtocol];
    }];
}

- (BOOL)containsObject:(id)object {
    if (_originalDelegate == object) {
        return YES;
    }
    
    return [_weakInterceptorObjects.keyEnumerator.allObjects bk_any:^BOOL(id obj) {
        return obj == object;
    }];
}

#pragma mark - empty methods
/// MARK: for check if delegate contains self
// 有的三方库，在proxy中仅仅使用 forwardingTargetForSelector 的方式来将不同的方法调用转发给不同的 target，没有做到 chain 的效果
// 如果多个三方库都 hock 了 setDelegate: 方法，则需要保证多次 setDelegate: 的调用之后，当前的proxy总是在chain中，如果不在了，需要再次创建
- (BOOL)__checkIfDelegateChainContainsEventTracingChain__ {
    return YES;
}

#pragma mark - private methods
- (id)_firstInterceptorObjectRespondingToSelector:(SEL)sel {
    return [[self interceptorObjects] bk_match:^BOOL(id obj) {
        return [self _methodSignatureForSelector:sel] != nil && [obj respondsToSelector:sel];
    }];
}

- (NSArray *)_allInterceptorObjectsRespondingToSelector:(SEL)sel {
    return [[self interceptorObjects] bk_select:^BOOL(id obj) {
        return [self _methodSignatureForSelector:sel] != nil && [obj respondsToSelector:sel];
    }];
}

- (NSMethodSignature *)_methodSignatureForSelector:(SEL)selector {
    __block char * signatureTypes = NULL;
    [self.originalDelegateProtocols enumerateObjectsUsingBlock:^(Protocol * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        struct objc_method_description methodDescription = protocol_getMethodDescription(obj, selector, YES, YES);
        if (!methodDescription.name) methodDescription = protocol_getMethodDescription(obj, selector, NO, YES);
        if (!methodDescription.name) methodDescription = protocol_getMethodDescription(obj, selector, YES, NO);
        if (!methodDescription.name) methodDescription = protocol_getMethodDescription(obj, selector, NO, NO);
        if (methodDescription.name) {
            signatureTypes = methodDescription.types;
            *stop = YES;
        }
    }];
    
    if (signatureTypes) {
        return [NSMethodSignature signatureWithObjCTypes:signatureTypes];
    }
    
    return nil;
}

#pragma mark - getters
- (NSArray *)interceptorObjects {
    return _weakInterceptorObjects.keyEnumerator.allObjects;
}

@end
