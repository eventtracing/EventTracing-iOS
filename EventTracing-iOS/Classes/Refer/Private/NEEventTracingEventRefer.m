//
//  NEEventTracingEventRefer.m
//  NEEventTracing
//
//  Created by dl on 2022/2/23.
//

#import "NEEventTracingEventRefer+Private.h"
#import "NEEventTracingFormattedReferBuilder.h"
#import "NEEventTracingEngine.h"
#import "NEEventTracingDefines.h"
#import "NEEventTracingVTreeNode+Private.h"
#import "NEEventTracingTraverser.h"
#import "UIView+EventTracingPrivate.h"
#import "NEEventTracingEngine+Private.h"

id<NEEventTracingFormattedRefer> NE_ET_formattedReferForNode(NEEventTracingVTreeNode *node, BOOL useNextActseq) {
    NSInteger actseq = useNextActseq ? (node.actseq + 1) : node.actseq;
    NSInteger pgstep = [node findToppestNode:YES].pgstep;
    
    id<NEEventTracingFormattedRefer> formattedRefer = [NEEventTracingFormattedReferBuilder build:^(id<NEEventTracingFormattedReferComponentBuilder>  _Nonnull builder) {
        builder
        .type(node.isPageNode ? NE_ET_REFER_KEY_P : NE_ET_REFER_KEY_E)
        .actseq(actseq)
        .pgstep(pgstep)
        .spm(node.spm)
        .scm(node.scm);
        
        if (node.isSCMNeedsER) {
            builder.er();
        }
    }].generateRefer;
    
    return formattedRefer;
}

@interface NEEventTracingFormattedEventRefer ()
@property(nonatomic, strong) NSMutableArray<NEEventTracingFormattedEventRefer *> *innerSubRefers;
@property(nonatomic, assign, readwrite) BOOL rootPagePV;
@end

@implementation NEEventTracingEventRefer
- (NEEventTracingEventReferType)referType {
    return NEEventTracingEventReferTypeFormatted;
}
- (NSString *)refer {
    return @"";
}
@end

@implementation NEEventTracingFormattedEventRefer

- (instancetype)init {
    self = [super init];
    if (self) {
        _innerSubRefers = @[].mutableCopy;
    }
    return self;
}

+(instancetype)referWithEvent:(NSString *)event
               formattedRefer:(id<NEEventTracingFormattedRefer>)formattedRefer
                  rootPagePV:(BOOL)rootPagePV
           shouldStartHsrefer:(BOOL)shouldStartHsrefer
           isNodePsreferMuted:(BOOL)isNodePsreferMuted {
    NEEventTracingFormattedEventRefer *refer = [[NEEventTracingFormattedEventRefer alloc] init];
    refer.rootPagePV = rootPagePV;
    refer.shouldStartHsrefer = shouldStartHsrefer;
    refer.event = event;
    refer.formattedRefer = formattedRefer;
    refer.eventTime = [NSDate date].timeIntervalSince1970;
    refer.appEnterBackgroundSeq = [NEEventTracingEngine sharedInstance].ctx.appEnterBackgroundSeq;
    refer.psreferMute = isNodePsreferMuted;
    return refer;
}

- (void)addSubRefer:(NEEventTracingFormattedEventRefer *)refer {
    refer.parentRefer = self;
    [_innerSubRefers addObject:refer];
}

- (NSArray<NEEventTracingFormattedEventRefer *> *)subRefers {
    return _innerSubRefers.copy;
}

- (NSString *)refer {
    return _formattedRefer.value;
}

- (NSString *)description {
    NSMutableString *description = @"[".mutableCopy;
    if (self.isRootPagePV) {
        [description appendString:@"r,"];
    }
    if (self.shouldStartHsrefer) {
        [description appendString:@"hs"];
    }
    [description appendString:@"]"];
    [description appendFormat:@"[T: %@] => ", @(self.eventTime).stringValue];
    [description appendString:self.formattedRefer.value];
    [description appendString:@"\n"];
    
    if (self.parentRefer) {
        [description appendFormat:@"====> [Parent][T: %@]: %@", @(self.parentRefer.eventTime).stringValue, self.parentRefer.formattedRefer.value];
        [description appendString:@"\n"];
    }
    
    if (self.subRefers.count) {
        [self.subRefers enumerateObjectsUsingBlock:^(NEEventTracingFormattedEventRefer * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [description appendFormat:@"----> [Sub%@][T: %@]: %@\n", @(idx).stringValue, @(obj.eventTime).stringValue, obj.formattedRefer.value];
        }];
    }
    
    return description.copy;
}

@end

@implementation NEEventTracingUndefinedXpathEventRefer
@synthesize refer = _refer;

+(instancetype)referWithEvent:(NSString *)event
          undefinedXpathRefer:(NSString *)undefinedXpathRefer {
    NEEventTracingUndefinedXpathEventRefer *refer = [[NEEventTracingUndefinedXpathEventRefer alloc] init];
    refer->_refer = undefinedXpathRefer;
    refer.event = event;
    refer.eventTime = [NSDate date].timeIntervalSince1970;
    return refer;
}

- (NEEventTracingEventReferType)referType {
    return NEEventTracingEventReferTypeUndefinedXpath;
}

- (NSString *)refer {
    return _refer;
}

@end

@implementation NEEventTracingFormattedEventRefer (Util)

+ (instancetype)becomeActiveRefer {
    id<NEEventTracingFormattedRefer> formattedRefer = [NEEventTracingFormattedReferBuilder build:^(id<NEEventTracingFormattedReferComponentBuilder>  _Nonnull builder) {
        builder
        .type(NE_ET_REFER_KEY_S)
        .pgstep([NEEventTracingEngine sharedInstance].context.pgstep)
        .spm(NE_ET_EVENT_ID_APP_ACTIVE);
    }].generateRefer;
    
    return [NEEventTracingFormattedEventRefer referWithEvent:NE_ET_EVENT_ID_APP_ACTIVE
                                              formattedRefer:formattedRefer
                                                  rootPagePV:NO
                                          shouldStartHsrefer:NO
                                          isNodePsreferMuted:NO];
}

+ (instancetype)enterForegroundRefer {
    id<NEEventTracingFormattedRefer> formattedRefer = [NEEventTracingFormattedReferBuilder build:^(id<NEEventTracingFormattedReferComponentBuilder>  _Nonnull builder) {
        builder
        .type(NE_ET_REFER_KEY_S)
        .pgstep([NEEventTracingEngine sharedInstance].context.pgstep)
        .spm(NE_ET_EVENT_ID_APP_IN);
    }].generateRefer;
    
    return [NEEventTracingFormattedEventRefer referWithEvent:NE_ET_EVENT_ID_APP_IN
                                              formattedRefer:formattedRefer
                                                  rootPagePV:NO
                                          shouldStartHsrefer:NO
                                          isNodePsreferMuted:NO];
}

@end


@implementation NEEventTracingFormattedWithSessidUndefinedXpathEventRefer
@synthesize refer = _refer;

+ (instancetype)referFromFormattedEventRefer:(NEEventTracingFormattedEventRefer *)formattedEventRefer
                                  withSessid:(BOOL)withSessid
                              undefinedXpath:(BOOL)undefinedXPath {
    NEEventTracingFormattedWithSessidUndefinedXpathEventRefer *refer = [[NEEventTracingFormattedWithSessidUndefinedXpathEventRefer alloc] init];
    refer.event = formattedEventRefer.event;
    refer.eventTime = formattedEventRefer.eventTime;
    refer->_refer = [formattedEventRefer.formattedRefer valueWithSessid:withSessid undefinedXpath:undefinedXPath];
    return refer;
}

@end
