//
//  EventTracingConstData.h
//  EventTracing
//
//  Created by dl on 2021/5/20.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#ifndef EventTracingConstData_H
#define EventTracingConstData_H

#define kETConstKeyTypeEvent "EVENT"
#define kETConstKeyTypeRefer "REFER"
#define kETConstKeyTypeSpecParamKey "SPEC_PARAM_KEY"
#define kETConstKeyTypeNodeValidation "NODE_VALIDATION"

#define ETConstDataSecName "ETConstData"
#define ETConstKeyValueSecDATA(sectname) __attribute((used, section("__DATA," sectname)))

#define ETConstKeyValue(TYPE, key, value) \
static char * _ETConst_ ## key ## _Private_ ETConstKeyValueSecDATA(ETConstDataSecName) = TYPE "/"#key"/" value;

#endif

@interface EventTracingConstData : NSObject

@property(nonatomic, copy, readonly) NSArray<NSString *> *allConstKeys;

+ (instancetype)sharedInstance;
- (NSArray<NSString *> *)constKeysForType:(NSString *)type;

@end

NS_ASSUME_NONNULL_END
