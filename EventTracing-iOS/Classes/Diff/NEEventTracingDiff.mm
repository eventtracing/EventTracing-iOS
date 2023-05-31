//
//  NEEventTracingDiff.m
//  BlocksKit
//
//  Created by dl on 2021/3/16.
//

#import "NEEventTracingDiff.h"

#import <stack>
#import <unordered_map>
#import <vector>

@interface NEEventTracingDiffResults ()
@property(nonatomic, strong, readwrite) NSArray<id<NEEventTracingDiffable>> *inserts;
@property(nonatomic, strong, readwrite) NSArray<id<NEEventTracingDiffable>> *deletes;

- (instancetype)initWithInserts:(NSArray<id<NEEventTracingDiffable>> *)inserts
                        deletes:(NSArray<id<NEEventTracingDiffable>> *)deletes;
@end

@implementation NEEventTracingDiffResults

- (instancetype)initWithInserts:(NSArray<id<NEEventTracingDiffable>> *)inserts
                        deletes:(NSArray<id<NEEventTracingDiffable>> *)deletes {
    self = [super init];
    if (self) {
        _inserts = inserts;
        _deletes = deletes;
    }
    return self;
}

- (BOOL)hasDiffs {
    return self.inserts.count != 0 || self.deletes.count != 0;
}

@end


using namespace std;
/// 记录遍历过程中new old的个数
struct ETDiffEntry {
    NSInteger newCounter = 0;
    NSInteger oldCounter = 0;
};

static id<NSObject> ETDiffTableKey(__unsafe_unretained id<NEEventTracingDiffable> object) {
    id<NSObject> key = [object ne_et_diffIdentifier];
    NSCAssert(key != nil, @"Cannot use a nil key for the diffIdentifier of object %@", object);
    return key;
}

struct ETDiffHashID {
    size_t operator()(const id o) const {
        return (size_t)[o hash];
    }
};

struct ETDiffEqualID {
    bool operator()(const id a, const id b) const {
        return (a == b) || [a isEqual: b];
    }
};

NEEventTracingDiffResults *NE_ET_DiffBetweenArray(NSArray<id<NEEventTracingDiffable>> *_Nullable newArray,
                                             NSArray<id<NEEventTracingDiffable>> *_Nullable oldArray) {
    
    const NSInteger newCount = newArray.count;
    const NSInteger oldCount = oldArray.count;
    
    // 如果 newArray 个数为空，则 oldArray 的所有元素都当做delete
    if (newCount == 0) {
        return [[NEEventTracingDiffResults alloc] initWithInserts:@[] deletes:[NSArray arrayWithArray:oldArray]];
    }
    
    // 如果 oldArray 个数为空，则 newArray 的所有元素都当做insert
    if (oldCount == 0) {
        return [[NEEventTracingDiffResults alloc] initWithInserts:[NSArray arrayWithArray:newArray] deletes:@[]];
    }
    
    unordered_map<id<NSObject>, ETDiffEntry, ETDiffHashID, ETDiffEqualID> table;
    
    // step 1
    vector<ETDiffEntry *> newResultsArray(newCount);
    for (NSInteger i=0; i<newCount; i++) {
        id<NSObject> key = ETDiffTableKey(newArray[i]);
        ETDiffEntry &entry = table[key];
        entry.newCounter++;
        
        newResultsArray[i] = &entry;
    }
    
    // step 2
    // 可直接找出 deletes 数组
    NSMutableArray<id<NEEventTracingDiffable>> *deletes = [@[] mutableCopy];
    vector<ETDiffEntry *> oldResultsArray(oldCount);
    for (NSInteger i=0; i<oldCount; i++) {
        id<NSObject> key = ETDiffTableKey(oldArray[i]);
        ETDiffEntry &entry = table[key];
        entry.oldCounter++;
        
        if (entry.newCounter == 0) {
            [deletes addObject:oldArray[i]];
        }
        
        oldResultsArray[i] = &entry;
    }
    
    // step 3
    // 遍历 new 数组，找出 inserts 的集合
    NSMutableArray<id<NEEventTracingDiffable>> *inserts = [@[] mutableCopy];
    for (NSInteger i=0; i<newCount; i++) {
        ETDiffEntry *entry = newResultsArray[i];
        
        // 在 oldArray 中不存在，newArray 中存在，则表示是 insert 类型
        if (entry->oldCounter == 0 && entry->newCounter > 0) {
            [inserts addObject:newArray[i]];
            
            entry->newCounter--;
        }
    }
    
    return [[NEEventTracingDiffResults alloc] initWithInserts:inserts.copy deletes:deletes.copy];
}
