//
//  NEEventTracingAOPProtocol.h
//  BlocksKit
//
//  Created by dl on 2021/2/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#define NEEventTracingAOPInstanceImp \
+ (instancetype)AOPInstance {\
    static id sharedInstance = nil;\
    static dispatch_once_t onceToken;\
    dispatch_once(&onceToken, ^{\
        sharedInstance = [self new];\
    });\
    return sharedInstance;\
}

@protocol NEEventTracingAOPProtocol <NSObject>

+ (instancetype) AOPInstance;

@optional
- (void)inject;
- (void)asyncInject;

@end

NS_ASSUME_NONNULL_END
