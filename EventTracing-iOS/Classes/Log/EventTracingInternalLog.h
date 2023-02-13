//
//  EventTracingInternalLog.h
//  BlocksKit
//
//  Created by dl on 2021/3/9.
//
#ifndef EventTracingInternalLog_h
#define EventTracingInternalLog_h

#import "EventTracingDefines.h"

FOUNDATION_EXPORT void _ETLog(ETLogLevel level, NSString *levelStr, NSString *tag, const char *file, const char *function, NSUInteger line, NSString *format, ...);

#define _ETLog_(level, tag, FORMAT, ...)                                                                        \
do {                                                                                                            \
    _ETLog(ETLogLevel ## level, @# level, tag, __FILE__, __PRETTY_FUNCTION__, __LINE__, FORMAT, ## __VA_ARGS__);          \
} while(0);

#define ETLogV(tag, format, ...)         _ETLog_(Verbose, tag, format, ## __VA_ARGS__)
#define ETLogE(tag, format, ...)         _ETLog_(Error, tag, format, ## __VA_ARGS__)
#define ETLogI(tag, format, ...)         _ETLog_(Info, tag, format, ## __VA_ARGS__)
#define ETLogD(tag, format, ...)         _ETLog_(Debug, tag, format, ## __VA_ARGS__)
#define ETLogS(tag, format, ...)         _ETLog_(System, tag, format, ## __VA_ARGS__)
#define ETLogW(tag, format, ...)         _ETLog_(Warning, tag, format, ## __VA_ARGS__)

#endif /* EventTracingInternalLog_h */
