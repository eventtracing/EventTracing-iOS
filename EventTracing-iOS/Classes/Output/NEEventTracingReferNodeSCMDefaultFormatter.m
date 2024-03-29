//
//  NEEventTracingReferNodeSCMDefaultFormatter.m
//  NEEventTracing
//
//  Created by dl on 2021/9/2.
//

#import "NEEventTracingReferNodeSCMDefaultFormatter.h"
#import "NSString+EventTracingUtil.h"

@implementation NEEventTracingReferNodeSCMDefaultFormatter

- (nonnull NSString *)nodeSCMWithView:(nonnull UIView *)view
                                 node:(nonnull NEEventTracingVTreeNode *)node
                              inVTree:(nonnull NEEventTracingVTree *)VTree {
    NSDictionary<NSString *, NSString *> *nodeParams = [node nodeParams];
    
    return [self nodeSCMWithNodeParams:nodeParams];
}

- (BOOL)needsEncodeSCMForNode:(NEEventTracingVTreeNode *)node {
    NSDictionary<NSString *, NSString *> *nodeParams = [node nodeParams];
    
    return [self needsEncodeSCMForNodeParams:nodeParams];
}

- (NSString *)nodeSCMWithNodeParams:(NSDictionary<NSString *, NSString *> *)params {
#define stringify(s)  !s ? @"" : ([s isKindOfClass:NSString.class] ? s : [NSString stringWithFormat:@"%@", s])
    NSString *cid = stringify([params objectForKey:@"s_cid"]);
    NSString *ctype = stringify([params objectForKey:@"s_ctype"]);
    NSString *ctraceid = stringify([params objectForKey:@"s_ctraceid"]);
    NSString *ctrp = stringify([params objectForKey:@"s_ctrp"]);
#undef stringify
    
    BOOL needsEncode = [cid isKindOfClass:NSString.class] && [cid ne_et_simplyNeedsEncoded];
    NSString *cidValue = needsEncode ? [cid ne_et_urlEncode] : cid;
    
    NSMutableString *result = [NSMutableString string];
    [result appendString:(cidValue ?: @"")];
    [result appendString:@":"];
    [result appendString:(ctype ?: @"")];
    [result appendString:@":"];
    [result appendString:(ctraceid ?: @"")];
    [result appendString:@":"];
    [result appendString:(ctrp ?: @"")];
    
    return result.copy;
}

- (BOOL)needsEncodeSCMForNodeParams:(NSDictionary<NSString *, NSString *> *)params {
    NSString *cid = [params objectForKey:@"s_cid"];
    
    return [cid isKindOfClass:NSString.class] && [cid ne_et_simplyNeedsEncoded];;
}

@end
