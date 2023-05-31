//
//  NEEventTracingInternalLog.m
//  BlocksKit
//
//  Created by dl on 2021/3/9.
//

#import "NEEventTracingInternalLog.h"
#import "NEEventTracingEngine+Private.h"

void _ETLog(ETLogLevel level, NSString *levelStr, NSString *tag, const char *file, const char *function, NSUInteger line, NSString *format, ...) {
    va_list arglist;
    va_start(arglist, format);
    
    NSString *message = [[NSString alloc] initWithFormat:format arguments:arglist];
    NSString *outContent = [NSString stringWithFormat:@"[NEEventTracing][%@]: %@, %@", levelStr, tag, message];

    id<NEEventTracingInternalLogOutputInterface> internalLogOutputInterface = [[[NEEventTracingEngine sharedInstance] context] internalLogOutputInterface];
    if ([internalLogOutputInterface respondsToSelector:@selector(logLevel:content:)]) {
        [internalLogOutputInterface logLevel:level content:outContent];
    }
    
    va_end(arglist);
}
