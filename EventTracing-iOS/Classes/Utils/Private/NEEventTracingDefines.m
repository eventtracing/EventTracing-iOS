//
//  NEEventTracingDefines.m
//  NEEventTracing
//
//  Created by dl on 2021/2/25.
//

#import "NEEventTracingDefines.h"
#import "NEEventTracingConstData.h"

NSUInteger NEEventTracingReferQueueMaxCount = 5;
NSString * const NEEventTracingExeptionErrmsgKey = @"errmsg";

NSInteger const NEEventTracingExceptionCodeNodeNotUnique                = 41;
NSInteger const NEEventTracingExceptionCodeNodeSPMNotUnique             = 42;
NSInteger const NEEventTracingExceptionCodeLogicalMountEndlessLoop      = 43;

NSInteger const NEEventTracingExceptionEventKeyInvalid                  = 51;
NSInteger const NEEventTracingExceptionEventKeyConflictWithEmbedded     = 52;
NSInteger const NEEventTracingExceptionPublicParamInvalid               = 53;
NSInteger const NEEventTracingExceptionUserParamInvalid                 = 54;
NSInteger const NEEventTracingExceptionParamConflictWithEmbedded        = 55;

#pragma mark - kETConstKeyTypeEvent Id
#define NE_ET_CONST_VALUE(_et_name_, _et_name_value_)               \
NSString *const _et_name_ = @ _et_name_value_;

#define NE_ET_CONST_VALUE_DATA(TYPE, _et_name_, _et_name_value_)    \
NSString *const _et_name_ = @ _et_name_value_;                      \
ETConstKeyValue(TYPE, _et_name_, _et_name_value_)

/******************* 事件类型 *******************/
NE_ET_CONST_VALUE_DATA(kETConstKeyTypeEvent, NE_ET_EVENT_ID_APP_ACTIVE, "_ac");
NE_ET_CONST_VALUE_DATA(kETConstKeyTypeEvent, NE_ET_EVENT_ID_APP_IN, "_ai");
NE_ET_CONST_VALUE_DATA(kETConstKeyTypeEvent, NE_ET_EVENT_ID_APP_OUT, "_ao");
NE_ET_CONST_VALUE_DATA(kETConstKeyTypeEvent, NE_ET_EVENT_ID_P_VIEW, "_pv");
NE_ET_CONST_VALUE_DATA(kETConstKeyTypeEvent, NE_ET_EVENT_ID_P_VIEW_END, "_pd");
NE_ET_CONST_VALUE_DATA(kETConstKeyTypeEvent, NE_ET_EVENT_ID_E_VIEW, "_ev");
NE_ET_CONST_VALUE_DATA(kETConstKeyTypeEvent, NE_ET_EVENT_ID_E_VIEW_END, "_ed");
NE_ET_CONST_VALUE_DATA(kETConstKeyTypeEvent, NE_ET_EVENT_ID_E_CLCK, "_ec");
NE_ET_CONST_VALUE_DATA(kETConstKeyTypeEvent, NE_ET_EVENT_ID_E_LONG_CLCK, "_elc");
NE_ET_CONST_VALUE_DATA(kETConstKeyTypeEvent, NE_ET_EVENT_ID_E_SLIDE, "_es");
NE_ET_CONST_VALUE_DATA(kETConstKeyTypeEvent, NE_ET_EVENT_ID_P_REFRESH, "_pgf");
NE_ET_CONST_VALUE_DATA(kETConstKeyTypeEvent, NE_ET_EVENT_ID_PLV, "_plv");
NE_ET_CONST_VALUE_DATA(kETConstKeyTypeEvent, NE_ET_EVENT_ID_PLD, "_pld");

/******************* refer 相关的常量值 *******************/
NE_ET_CONST_VALUE(NE_ET_REFER_KEY_S, "s");
NE_ET_CONST_VALUE(NE_ET_REFER_KEY_P, "p");
NE_ET_CONST_VALUE(NE_ET_REFER_KEY_E, "e");
NE_ET_CONST_VALUE_DATA(kETConstKeyTypeRefer, NE_ET_REFER_KEY_SPM, "_spm");
NE_ET_CONST_VALUE_DATA(kETConstKeyTypeRefer, NE_ET_REFER_KEY_SCM, "_scm");
NE_ET_CONST_VALUE_DATA(kETConstKeyTypeRefer, NE_ET_REFER_KEY_SCM_ER, "_scm_er");
NE_ET_CONST_VALUE_DATA(kETConstKeyTypeRefer, NE_ET_REFER_KEY_PGREFER, "_pgrefer");
NE_ET_CONST_VALUE_DATA(kETConstKeyTypeRefer, NE_ET_REFER_KEY_PSREFER, "_psrefer");
NE_ET_CONST_VALUE_DATA(kETConstKeyTypeRefer, NE_ET_REFER_KEY_PGSTEP, "_pgstep");
NE_ET_CONST_VALUE_DATA(kETConstKeyTypeRefer, NE_ET_REFER_KEY_ACTSEQ, "_actseq");
NE_ET_CONST_VALUE_DATA(kETConstKeyTypeRefer, NE_ET_REFER_KEY_HSREFER, "_hsrefer");
NE_ET_CONST_VALUE_DATA(kETConstKeyTypeRefer, NE_ET_REFER_KEY_SESSID, "_sessid");
NE_ET_CONST_VALUE_DATA(kETConstKeyTypeRefer, NE_ET_REFER_KEY_SIDREFER, "_sidrefer");
NE_ET_CONST_VALUE_DATA(kETConstKeyTypeRefer, NE_ET_REFER_KEY_RQREFER, "_rqrefer");
NE_ET_CONST_VALUE_DATA(kETConstKeyTypeRefer, NE_ET_REFER_KEY_POSITION, "_position");
NE_ET_CONST_VALUE_DATA(kETConstKeyTypeRefer, NE_ET_REFER_KEY_DURATION, "_duration");
NE_ET_CONST_VALUE_DATA(kETConstKeyTypeRefer, NE_ET_REFER_KEY_RATIO, "_ratio");

/******************* 日志输出相关的一些关键字 *******************/
NE_ET_CONST_VALUE_DATA(kETConstKeyTypeSpecParamKey, NE_ET_CONST_KEY_OID, "_oid");
NE_ET_CONST_VALUE_DATA(kETConstKeyTypeSpecParamKey, NE_ET_CONST_KEY_PLIST, "_plist");
NE_ET_CONST_VALUE_DATA(kETConstKeyTypeSpecParamKey, NE_ET_CONST_KEY_ELIST, "_elist");
NE_ET_CONST_VALUE_DATA(kETConstKeyTypeSpecParamKey, NE_ET_CONST_KEY_EVENT_CODE, "_eventcode");
NE_ET_CONST_VALUE_DATA(kETConstKeyTypeSpecParamKey, NE_ET_CONST_KEY_IB, "_ib");
NE_ET_CONST_VALUE_DATA(kETConstKeyTypeSpecParamKey, NE_ET_CONST_KEY_INVISIBLE, "_invisible");

/// MARK: Alert Action `position` Params Key
NE_ET_CONST_VALUE(NE_ET_PARAM_CONST_KEY_POSITION, "s_position");

/// MARK: 内部候用
NE_ET_CONST_VALUE(NE_ET_REUSE_BIZ_SET, "BIZ_SET");

/// MARK: 节点信息校验相关
NE_ET_CONST_VALUE_DATA(kETConstKeyTypeNodeValidation, NE_ET_CONST_VALIDATION_PAGE_TYPE, "_valid_page_type");
NE_ET_CONST_VALUE_DATA(kETConstKeyTypeNodeValidation, NE_ET_CONST_VALIDATION_LOGICAL_MOUNT, "_valid_logical_mount");
NE_ET_CONST_VALUE_DATA(kETConstKeyTypeNodeValidation, NE_ET_CONST_VALIDATION_IGNORE_REFER_CASCADE, "_valid_ignore_refer_cascade");
NE_ET_CONST_VALUE_DATA(kETConstKeyTypeNodeValidation, NE_ET_CONST_VALIDATION_PSREFER_MUTED, "_valid_psrefer_muted");
