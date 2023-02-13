//
//  EventTracingDefines.m
//  EventTracing
//
//  Created by dl on 2021/2/25.
//

#import "EventTracingDefines.h"
#import "EventTracingConstData.h"

NSUInteger EventTracingReferQueueMaxCount = 5;
NSString * const EventTracingExeptionErrmsgKey = @"errmsg";

NSInteger const EventTracingExceptionCodeNodeNotUnique                = 41;
NSInteger const EventTracingExceptionCodeNodeSPMNotUnique             = 42;
NSInteger const EventTracingExceptionCodeLogicalMountEndlessLoop      = 43;

NSInteger const EventTracingExceptionEventKeyInvalid                  = 51;
NSInteger const EventTracingExceptionEventKeyConflictWithEmbedded     = 52;
NSInteger const EventTracingExceptionPublicParamInvalid               = 53;
NSInteger const EventTracingExceptionUserParamInvalid                 = 54;
NSInteger const EventTracingExceptionParamConflictWithEmbedded        = 55;

#pragma mark - kETConstKeyTypeEvent Id
#define ET_CONST_VALUE(_et_name_, _et_name_value_)               \
NSString *const _et_name_ = @ _et_name_value_;

#define ET_CONST_VALUE_DATA(TYPE, _et_name_, _et_name_value_)    \
NSString *const _et_name_ = @ _et_name_value_;                      \
ETConstKeyValue(TYPE, _et_name_, _et_name_value_)

/******************* 事件类型 *******************/
ET_CONST_VALUE_DATA(kETConstKeyTypeEvent, ET_EVENT_ID_APP_ACTIVE, "_ac");
ET_CONST_VALUE_DATA(kETConstKeyTypeEvent, ET_EVENT_ID_APP_IN, "_ai");
ET_CONST_VALUE_DATA(kETConstKeyTypeEvent, ET_EVENT_ID_APP_OUT, "_ao");
ET_CONST_VALUE_DATA(kETConstKeyTypeEvent, ET_EVENT_ID_P_VIEW, "_pv");
ET_CONST_VALUE_DATA(kETConstKeyTypeEvent, ET_EVENT_ID_P_VIEW_END, "_pd");
ET_CONST_VALUE_DATA(kETConstKeyTypeEvent, ET_EVENT_ID_E_VIEW, "_ev");
ET_CONST_VALUE_DATA(kETConstKeyTypeEvent, ET_EVENT_ID_E_VIEW_END, "_ed");
ET_CONST_VALUE_DATA(kETConstKeyTypeEvent, ET_EVENT_ID_E_CLCK, "_ec");
ET_CONST_VALUE_DATA(kETConstKeyTypeEvent, ET_EVENT_ID_E_LONG_CLCK, "_elc");
ET_CONST_VALUE_DATA(kETConstKeyTypeEvent, ET_EVENT_ID_E_SLIDE, "_es");
ET_CONST_VALUE_DATA(kETConstKeyTypeEvent, ET_EVENT_ID_P_REFRESH, "_pgf");
ET_CONST_VALUE_DATA(kETConstKeyTypeEvent, ET_EVENT_ID_PLV, "_plv");
ET_CONST_VALUE_DATA(kETConstKeyTypeEvent, ET_EVENT_ID_PLD, "_pld");

/******************* refer 相关的常量值 *******************/
ET_CONST_VALUE(ET_REFER_KEY_S, "s");
ET_CONST_VALUE(ET_REFER_KEY_P, "p");
ET_CONST_VALUE(ET_REFER_KEY_E, "e");
ET_CONST_VALUE_DATA(kETConstKeyTypeRefer, ET_REFER_KEY_SPM, "_spm");
ET_CONST_VALUE_DATA(kETConstKeyTypeRefer, ET_REFER_KEY_SCM, "_scm");
ET_CONST_VALUE_DATA(kETConstKeyTypeRefer, ET_REFER_KEY_SCM_ER, "_scm_er");
ET_CONST_VALUE_DATA(kETConstKeyTypeRefer, ET_REFER_KEY_PGREFER, "_pgrefer");
ET_CONST_VALUE_DATA(kETConstKeyTypeRefer, ET_REFER_KEY_PSREFER, "_psrefer");
ET_CONST_VALUE_DATA(kETConstKeyTypeRefer, ET_REFER_KEY_PGSTEP, "_pgstep");
ET_CONST_VALUE_DATA(kETConstKeyTypeRefer, ET_REFER_KEY_ACTSEQ, "_actseq");
ET_CONST_VALUE_DATA(kETConstKeyTypeRefer, ET_REFER_KEY_HSREFER, "_hsrefer");
ET_CONST_VALUE_DATA(kETConstKeyTypeRefer, ET_REFER_KEY_SESSID, "_sessid");
ET_CONST_VALUE_DATA(kETConstKeyTypeRefer, ET_REFER_KEY_SIDREFER, "_sidrefer");
ET_CONST_VALUE_DATA(kETConstKeyTypeRefer, ET_REFER_KEY_RQREFER, "_rqrefer");
ET_CONST_VALUE_DATA(kETConstKeyTypeRefer, ET_REFER_KEY_POSITION, "_position");
ET_CONST_VALUE_DATA(kETConstKeyTypeRefer, ET_REFER_KEY_DURATION, "_duration");
ET_CONST_VALUE_DATA(kETConstKeyTypeRefer, ET_REFER_KEY_RATIO, "_ratio");

/******************* 日志输出相关的一些关键字 *******************/
ET_CONST_VALUE_DATA(kETConstKeyTypeSpecParamKey, ET_CONST_KEY_OID, "_oid");
ET_CONST_VALUE_DATA(kETConstKeyTypeSpecParamKey, ET_CONST_KEY_PLIST, "_plist");
ET_CONST_VALUE_DATA(kETConstKeyTypeSpecParamKey, ET_CONST_KEY_ELIST, "_elist");
ET_CONST_VALUE_DATA(kETConstKeyTypeSpecParamKey, ET_CONST_KEY_EVENT_CODE, "_eventcode");
ET_CONST_VALUE_DATA(kETConstKeyTypeSpecParamKey, ET_CONST_KEY_IB, "_ib");
ET_CONST_VALUE_DATA(kETConstKeyTypeSpecParamKey, ET_CONST_KEY_INVISIBLE, "_invisible");

/// MARK: Alert Action `position` Params Key
ET_CONST_VALUE(ET_PARAM_CONST_KEY_POSITION, "s_position");

/// MARK: 内部候用
ET_CONST_VALUE(ET_REUSE_BIZ_SET, "BIZ_SET");
