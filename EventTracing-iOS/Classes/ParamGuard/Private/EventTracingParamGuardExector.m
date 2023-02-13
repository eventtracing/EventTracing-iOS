//
//  EventTracingParamGuardExector.m
//  BlocksKit
//
//  Created by dl on 2021/5/20.
//

#import "EventTracingParamGuardExector.h"
#import "EventTracingDefines.h"
#import "EventTracingEngine+Private.h"
#import "EventTracingContext+Private.h"
#import "EventTracingInternalLog.h"
#import "EventTracingConstData.h"

NSString *ETParamKeyGuardEvent = @"Event";
NSString *ETParamKeyGuardPublicParam = @"PublicParam";
NSString *ETParamKeyGuardUserParam = @"UserParam";

NSString *ETParamKeyGuardErrorRegxKey = @"regx";

BOOL ET_CheckEventKeyValid(NSString *eventKey) {
    NSError *error;
    return [[EventTracingEngine sharedInstance].ctx.paramGuardExector checkEventKeyValid:eventKey error:&error];
}

BOOL ET_CheckPublicParamKeyValid(NSString *publicParamKey) {
    NSError *error;
    return [[EventTracingEngine sharedInstance].ctx.paramGuardExector checkPublicParamKeyValid:publicParamKey error:&error];
}

BOOL ET_CheckUserParamKeyValid(NSString *userParamKey) {
    NSError *error;
    return [[EventTracingEngine sharedInstance].ctx.paramGuardExector checkUserParamKeyValid:userParamKey error:&error];
}

#define LOCK        dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
#define UNLOCK      dispatch_semaphore_signal(_lock);

NSString *ET_ExceptionKeyForCode(NSUInteger code) {
    NSDictionary *map = @{
        @(EventTracingExceptionEventKeyInvalid): @"EventKeyInvalid",
        @(EventTracingExceptionEventKeyConflictWithEmbedded): @"EventKeyConflictWithEmbedded",
        @(EventTracingExceptionPublicParamInvalid): @"PublicParamInvalid",
        @(EventTracingExceptionUserParamInvalid): @"UserParamInvalid",
        @(EventTracingExceptionParamConflictWithEmbedded): @"ParamConflictWithEmbedded"
    };
    return [map objectForKey:@(code)];
}

@interface EventTracingParamGuardExector ()
@property(nonatomic, strong) NSRegularExpression *eventKeyRegxExp;
@property(nonatomic, strong) NSRegularExpression *publicParamRegxExp;
@property(nonatomic, strong) NSRegularExpression *userParamRegxExp;

@property(nonatomic, strong) NSMutableDictionary<NSString *, NSRegularExpression *> *regxExps;
@property(nonatomic, strong) dispatch_semaphore_t lock;
@property(nonatomic, strong) dispatch_queue_t queue;
@end

@implementation EventTracingParamGuardExector
@synthesize eventKeyRegx = _eventKeyRegx;
@synthesize publicParamRegx = _publicParamRegx;
@synthesize userParamRegxOptionalPrefix = _userParamRegxOptionalPrefix;
@synthesize userParamRegx = _userParamRegx;

- (instancetype)init {
    self = [super init];
    if (self) {
        self.eventKeyRegx = @"^(_)[a-z]+(?:[-_][a-z]+)*$";
        self.publicParamRegx = @"^(g_)[a-z][^\\W_]+[^\\W_]*(?:[-_][^\\W_]+)*$";
        self.userParamRegxOptionalPrefix = @"s_";
        // (s_){0,}
        self.userParamRegx = @"^[a-z][^\\W_]+[^\\W_]*(?:[-_][^\\W_]+)*$";
        
        _regxExps = @{}.mutableCopy;
        _lock = dispatch_semaphore_create(1);
        _queue = dispatch_queue_create("EventTracing_ParamsGuard_Q", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (NSString *)userParamRegxFixed {
    NSMutableString *regx = self.userParamRegx.mutableCopy;
    if (self.userParamRegxOptionalPrefix.length) {
        NSRange firstCharRange = NSMakeRange(0, 1);
        if ([[regx substringWithRange:firstCharRange] isEqualToString:@"^"]) {
            [regx deleteCharactersInRange:NSMakeRange(0, 1)];
        }
        NSString *prefixRegx = [NSString stringWithFormat:@"^(%@){0,}", self.userParamRegxOptionalPrefix];
        [regx insertString:prefixRegx atIndex:0];
    }
    return regx.copy;
}

- (void)asyncDoDispatchCheckTask:(void (^)(void))block {
    // 如果不开启，则直接当做验证没问题
    if (![EventTracingEngine sharedInstance].ctx.isParamGuardEnable) {
        return ;
    }
    
    dispatch_async(self.queue, ^{
        !block ?: block();
    });
}

- (BOOL)checkEventKeyValid:(NSString *)eventKey error:(NSError ** _Nullable)error {
    return [self _checkKeyIfValid:eventKey
                       paramGuard:ETParamKeyGuardEvent
                 constKeyListType:@kETConstKeyTypeEvent
                  conflictErrCode:EventTracingExceptionEventKeyConflictWithEmbedded
                             regx:self.eventKeyRegx
                      regxErrCode:EventTracingExceptionEventKeyInvalid
                            error:error];
}

- (BOOL)checkPublicParamKeyValid:(NSString *)publicParamKey error:(NSError ** _Nullable)error {
    return [self _checkKeyIfValid:publicParamKey
                       paramGuard:ETParamKeyGuardPublicParam
                 constKeyListType:nil
                  conflictErrCode:EventTracingExceptionParamConflictWithEmbedded
                             regx:self.publicParamRegx
                      regxErrCode:EventTracingExceptionPublicParamInvalid
                            error:error];
}

- (BOOL)checkUserParamKeyValid:(NSString *)userParamKey error:(NSError ** _Nullable)error {
    return [self _checkKeyIfValid:userParamKey
                       paramGuard:ETParamKeyGuardUserParam
                 constKeyListType:nil
                  conflictErrCode:EventTracingExceptionParamConflictWithEmbedded
                             regx:self.userParamRegxFixed
                      regxErrCode:EventTracingExceptionUserParamInvalid
                            error:error];
}

- (BOOL)_checkKeyIfValid:(NSString *)paramKey
              paramGuard:(NSString *)paramGuard
        constKeyListType:(NSString *)constKeyListType
         conflictErrCode:(NSInteger)conflictErrCode
                    regx:(NSString *)regx
             regxErrCode:(NSInteger)regxErrCode
                   error:(NSError ** _Nullable)error {
    __block NSError *localError = *error;
    void(^reportException)(NSInteger) = ^(NSInteger code) {
        id<EventTracingExceptionDelegate> exceptionDelegate = [[EventTracingEngine sharedInstance].context exceptionInterface];
        if ([exceptionDelegate respondsToSelector:@selector(paramGuardExceptionKey:code:paramKey:regex:error:)]) {
            [exceptionDelegate paramGuardExceptionKey:ET_ExceptionKeyForCode(code) code:code paramKey:paramKey regex:regx error:localError];
        }

        ETLogE(@"ParamGuard", @"%@", localError);
    };
    
    BOOL valid =  [self _doCheckKeyIfConflict:paramKey paramGuard:paramGuard constKeyListType:constKeyListType errCode:conflictErrCode error:&localError];
    if (!valid) {
        ETDispatchMainAsyncSafe(^{
            reportException(conflictErrCode);
        });
        return NO;
    }
    
    valid = [self _doCheckKey:paramKey paramGuard:paramGuard regx:regx errCode:regxErrCode error:&localError];
    if (!valid) {
        ETDispatchMainAsyncSafe(^{
            reportException(regxErrCode);
        });
        return NO;
    }
    
    return YES;
}

- (BOOL)_doCheckKeyIfConflict:(NSString *)key
                   paramGuard:(NSString *)paramGuard
             constKeyListType:(NSString *)constKeyListType
                      errCode:(NSInteger)errcode
                        error:(NSError ** _Nullable)error {
    NSMutableArray<NSString *> *constKeyList = [EventTracingConstData sharedInstance].allConstKeys.mutableCopy;
    if (constKeyListType) {
        NSArray<NSString *> *list = [[EventTracingConstData sharedInstance] constKeysForType:constKeyListType];
        [constKeyList removeObjectsInArray:list];
    }
    
    if (error != NULL && [constKeyList containsObject:key]) {
        *error = [NSError errorWithDomain:@"com.eventtracing.param.guard" code:errcode userInfo:@{
            EventTracingExeptionErrmsgKey: [NSString stringWithFormat:@"%@ key: %@, conflict with enbedded", paramGuard, key]
        }];
        return NO;
    }
    
    return YES;
}

- (BOOL)_doCheckKey:(NSString *)key
         paramGuard:(NSString *)paramGuard
               regx:(NSString *)regx
           errCode:(NSInteger)errcode
              error:(NSError ** _Nullable)error {
    NSRegularExpression *exp = [self _createExpForParamGuardIfNeeded:paramGuard regx:regx error:error];
    NSUInteger matchCount = [exp numberOfMatchesInString:key options:NSMatchingReportProgress range:NSMakeRange(0, key.length)];
    if (!*error && matchCount > 0) {
        return YES;
    }
    
    if (*error) {
        return NO;
    }
    
    if (error != NULL) {
        *error = [NSError errorWithDomain:@"com.eventtracing.param.guard" code:errcode userInfo:@{
            EventTracingExeptionErrmsgKey: [NSString stringWithFormat:@"%@ key: %@, dot match regx", paramGuard, key],
            ETParamKeyGuardErrorRegxKey: (exp.pattern ?: @"")
        }];
    }
    
    return NO;
}

- (NSRegularExpression *)_createExpForParamGuardIfNeeded:(NSString *)paramGuard regx:(NSString *)regx error:(NSError **)error {
    NSRegularExpression *exp = nil;
    LOCK {
        exp = [self.regxExps objectForKey:paramGuard];
        if (!exp || [exp.pattern isEqualToString:regx]) {
            exp = [NSRegularExpression regularExpressionWithPattern:regx options:0 error:error];
            [self.regxExps setObject:exp forKey:paramGuard];
        }
    } UNLOCK
    
    return exp;
}

@end
