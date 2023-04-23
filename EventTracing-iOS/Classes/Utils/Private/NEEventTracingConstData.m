//
//  EventTracingConstData.m
//  EventTracing
//
//  Created by dl on 2021/5/20.
//

#import "EventTracingConstData.h"
#include <mach-o/dyld.h>
#include <mach-o/getsect.h>

#ifdef __LP64__
typedef struct mach_header_64 * mach_header_ptr_t;
#else
typedef struct mach_header * mach_header_ptr_t;
#endif

@interface EventTracingConstData()
@property(nonatomic, strong) NSDictionary<NSString *, NSArray<NSString *> *> *constData;
@end

@implementation EventTracingConstData

+ (instancetype)sharedInstance {
    static EventTracingConstData *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[EventTracingConstData alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self _doLoadStaticallyRegisteredItems];
    }
    return self;
}

- (NSArray<NSString *> *)constKeysForType:(NSString *)type {
    return [self.constData objectForKey:type];
}

#pragma mark - private methods
-(void)_doLoadStaticallyRegisteredItems {
    for (uint32_t i = 0, n = _dyld_image_count(); i < n; ++i) {
        [self _doLoadStaticallyRegisteredItemsFromMachO:(mach_header_ptr_t)_dyld_get_image_header(i)];
    }
}

- (void)_doLoadStaticallyRegisteredItemsFromMachO:(mach_header_ptr_t)header {
    NSMutableDictionary<NSString *, NSMutableArray<NSString *> *> *data = @{}.mutableCopy;
    unsigned long size = 0;
    uintptr_t *memory = (uintptr_t*)getsectiondata(header, SEG_DATA, ETConstDataSecName, &size);
    
    unsigned long counter = size/sizeof(void*);
    for(int idx = 0; idx < counter; ++idx){
        char *string = (char*)memory[idx];
        NSString *str = [NSString stringWithUTF8String:string];
        if(!str)continue;
        
        NSArray<NSString *> *comps = [str componentsSeparatedByString:@"/"];
        if (comps.count != 3) {
            return;
        }
        
        NSString *type = comps.firstObject;
        NSString *key = comps.lastObject;
        
        NSMutableArray<NSString *> *keys = [data objectForKey:type].mutableCopy;
        if (!keys) {
            keys = @[].mutableCopy;
        }
        [keys addObject:key];
        [data setObject:keys.copy forKey:type];
    }
    
    if (data.count) {
        self.constData = data.copy;
    }
}

#pragma mark - getters
- (NSArray<NSString *> *)allConstKeys {
    NSMutableArray<NSString *> *keys = @[].mutableCopy;
    [self.constData enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSArray<NSString *> * _Nonnull obj, BOOL * _Nonnull stop) {
        [keys addObjectsFromArray:obj];
    }];
    return keys.copy;
}

@end
