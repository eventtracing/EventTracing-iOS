//
//  EventTracingEventRefer.m
//  EventTracing
//
//  Created by dl on 2022/2/23.
//

#import "EventTracingEventRefer+Private.h"
#import "EventTracingFormattedReferBuilder.h"
#import "EventTracingEngine.h"
#import "EventTracingDefines.h"
#import "EventTracingVTreeNode+Private.h"
#import "EventTracingTraverser.h"
#import "UIView+EventTracingPrivate.h"
#import "EventTracingEngine+Private.h"

id<EventTracingFormattedRefer> ET_formattedReferForNode(EventTracingVTreeNode *node, BOOL useNextActseq) {
    NSInteger actseq = useNextActseq ? (node.actseq + 1) : node.actseq;
    NSInteger pgstep = [node findToppestNode:YES].pgstep;
    
    id<EventTracingFormattedRefer> formattedRefer = [EventTracingFormattedReferBuilder build:^(id<EventTracingFormattedReferComponentBuilder>  _Nonnull builder) {
        builder
        .type(node.isPageNode ? ET_REFER_KEY_P : ET_REFER_KEY_E)
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

@interface EventTracingFormattedEventRefer ()
@property(nonatomic, strong) NSMutableArray<EventTracingFormattedEventRefer *> *innerSubRefers;
@property(nonatomic, assign, readwrite) BOOL rootPagePV;
@end

@implementation EventTracingEventRefer
- (EventTracingEventReferType)referType {
    return EventTracingEventReferTypeFormatted;
}
- (NSString *)refer {
    return @"";
}
@end

@implementation EventTracingFormattedEventRefer

- (instancetype)init {
    self = [super init];
    if (self) {
        _innerSubRefers = @[].mutableCopy;
    }
    return self;
}

+(instancetype)referWithEvent:(NSString *)event
               formattedRefer:(id<EventTracingFormattedRefer>)formattedRefer
                  rootPagePV:(BOOL)rootPagePV
                        toids:(NSArray<NSString *> * _Nullable)toids
           shouldStartHsrefer:(BOOL)shouldStartHsrefer
           isNodePsreferMuted:(BOOL)isNodePsreferMuted {
    EventTracingFormattedEventRefer *refer = [[EventTracingFormattedEventRefer alloc] init];
    refer.rootPagePV = rootPagePV;
    refer.toids = toids;
    refer.shouldStartHsrefer = shouldStartHsrefer;
    refer.event = event;
    refer.formattedRefer = formattedRefer;
    refer.eventTime = [NSDate date].timeIntervalSince1970;
    refer.appEnterBackgroundSeq = [EventTracingEngine sharedInstance].ctx.appEnterBackgroundSeq;
    refer.psreferMute = isNodePsreferMuted;
    return refer;
}

- (void)addSubRefer:(EventTracingFormattedEventRefer *)refer {
    refer.parentRefer = self;
    [_innerSubRefers addObject:refer];
}

- (NSArray<EventTracingFormattedEventRefer *> *)subRefers {
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
        [self.subRefers enumerateObjectsUsingBlock:^(EventTracingFormattedEventRefer * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [description appendFormat:@"----> [Sub%@][T: %@]: %@\n", @(idx).stringValue, @(obj.eventTime).stringValue, obj.formattedRefer.value];
        }];
    }
    
    return description.copy;
}

@end

@implementation EventTracingUndefinedXpathEventRefer
@synthesize refer = _refer;

+(instancetype)referWithEvent:(NSString *)event
          undefinedXpathRefer:(NSString *)undefinedXpathRefer {
    EventTracingUndefinedXpathEventRefer *refer = [[EventTracingUndefinedXpathEventRefer alloc] init];
    refer->_refer = undefinedXpathRefer;
    refer.event = event;
    refer.eventTime = [NSDate date].timeIntervalSince1970;
    return refer;
}

- (EventTracingEventReferType)referType {
    return EventTracingEventReferTypeUndefinedXpath;
}

- (NSString *)refer {
    return _refer;
}

@end

@implementation EventTracingFormattedEventRefer (Util)

+ (instancetype)becomeActiveRefer {
    id<EventTracingFormattedRefer> formattedRefer = [EventTracingFormattedReferBuilder build:^(id<EventTracingFormattedReferComponentBuilder>  _Nonnull builder) {
        builder
        .type(ET_REFER_KEY_S)
        .pgstep([EventTracingEngine sharedInstance].context.pgstep)
        .spm(ET_EVENT_ID_APP_ACTIVE);
    }].generateRefer;
    
    return [EventTracingFormattedEventRefer referWithEvent:ET_EVENT_ID_APP_ACTIVE
                                              formattedRefer:formattedRefer
                                                  rootPagePV:NO
                                                       toids:nil
                                          shouldStartHsrefer:NO
                                          isNodePsreferMuted:NO];
}

+ (instancetype)enterForegroundRefer {
    id<EventTracingFormattedRefer> formattedRefer = [EventTracingFormattedReferBuilder build:^(id<EventTracingFormattedReferComponentBuilder>  _Nonnull builder) {
        builder
        .type(ET_REFER_KEY_S)
        .pgstep([EventTracingEngine sharedInstance].context.pgstep)
        .spm(ET_EVENT_ID_APP_IN);
    }].generateRefer;
    
    return [EventTracingFormattedEventRefer referWithEvent:ET_EVENT_ID_APP_IN
                                              formattedRefer:formattedRefer
                                                  rootPagePV:NO
                                                       toids:nil
                                          shouldStartHsrefer:NO
                                          isNodePsreferMuted:NO];
}

@end


@implementation EventTracingFormattedWithSessidUndefinedXpathEventRefer
@synthesize refer = _refer;

+ (instancetype)referFromFormattedEventRefer:(EventTracingFormattedEventRefer *)formattedEventRefer
                                  withSessid:(BOOL)withSessid
                              undefinedXpath:(BOOL)undefinedXPath {
    EventTracingFormattedWithSessidUndefinedXpathEventRefer *refer = [[EventTracingFormattedWithSessidUndefinedXpathEventRefer alloc] init];
    refer.event = formattedEventRefer.event;
    refer.eventTime = formattedEventRefer.eventTime;
    refer->_refer = [formattedEventRefer.formattedRefer valueWithSessid:withSessid undefinedXpath:undefinedXPath];
    return refer;
}

@end
