#import <Foundation/Foundation.h>

#ifndef _ET_CONFUSE_MACRO_H_
#define _ET_CONFUSE_MACRO_H_

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
    size_t len;
    uint16_t *payload;
} confused_t;

static inline confused_t *_confused_init(size_t str_len)
{
    confused_t *res = (confused_t *)malloc(sizeof(confused_t));
    res->len = 0;
    res->payload = (uint16_t *)calloc(str_len + 1, sizeof(uint16_t));
    return res;
}

#define _kConfuseMask (uint8_t)0xcd

#define _CONFUSE_G_UPDATE_FUNCTION(NAME, code) \
    _Pragma("clang diagnostic push") \
    _Pragma("clang diagnostic ignored \"-Wunneeded-internal-declaration\"") \
    static inline confused_t *NAME(confused_t *input) \
    { \
        input->payload[input->len] = (code | (uint8_t)(uint64_t)(void *)(&input->len)); \
        input->len += 1; \
        return input; \
    } \
    _Pragma("clang diagnostic pop") \

#define _CONFUSE_WRAPPED_OFFSET(offset) \
    (((offset ^ _kConfuseMask) << 8) | ((__LINE__ % 0x80) + 0x80))

// Table: 0, base: 0x30
_CONFUSE_G_UPDATE_FUNCTION(_confused_0, _CONFUSE_WRAPPED_OFFSET(0));
_CONFUSE_G_UPDATE_FUNCTION(_confused_1, _CONFUSE_WRAPPED_OFFSET(1));
_CONFUSE_G_UPDATE_FUNCTION(_confused_2, _CONFUSE_WRAPPED_OFFSET(2));
_CONFUSE_G_UPDATE_FUNCTION(_confused_3, _CONFUSE_WRAPPED_OFFSET(3));
_CONFUSE_G_UPDATE_FUNCTION(_confused_4, _CONFUSE_WRAPPED_OFFSET(4));
_CONFUSE_G_UPDATE_FUNCTION(_confused_5, _CONFUSE_WRAPPED_OFFSET(5));
_CONFUSE_G_UPDATE_FUNCTION(_confused_6, _CONFUSE_WRAPPED_OFFSET(6));
_CONFUSE_G_UPDATE_FUNCTION(_confused_7, _CONFUSE_WRAPPED_OFFSET(7));
_CONFUSE_G_UPDATE_FUNCTION(_confused_8, _CONFUSE_WRAPPED_OFFSET(8));
_CONFUSE_G_UPDATE_FUNCTION(_confused_9, _CONFUSE_WRAPPED_OFFSET(9));

// Table: 1, base: 0x40
_CONFUSE_G_UPDATE_FUNCTION(_confused_A, _CONFUSE_WRAPPED_OFFSET(65));
_CONFUSE_G_UPDATE_FUNCTION(_confused_B, _CONFUSE_WRAPPED_OFFSET(66));
_CONFUSE_G_UPDATE_FUNCTION(_confused_C, _CONFUSE_WRAPPED_OFFSET(67));
_CONFUSE_G_UPDATE_FUNCTION(_confused_D, _CONFUSE_WRAPPED_OFFSET(68));
_CONFUSE_G_UPDATE_FUNCTION(_confused_E, _CONFUSE_WRAPPED_OFFSET(69));
_CONFUSE_G_UPDATE_FUNCTION(_confused_F, _CONFUSE_WRAPPED_OFFSET(70));
_CONFUSE_G_UPDATE_FUNCTION(_confused_G, _CONFUSE_WRAPPED_OFFSET(71));
_CONFUSE_G_UPDATE_FUNCTION(_confused_H, _CONFUSE_WRAPPED_OFFSET(72));
_CONFUSE_G_UPDATE_FUNCTION(_confused_I, _CONFUSE_WRAPPED_OFFSET(73));_CONFUSE_G_UPDATE_FUNCTION(_confused_ne_I, _CONFUSE_WRAPPED_OFFSET(73));
_CONFUSE_G_UPDATE_FUNCTION(_confused_J, _CONFUSE_WRAPPED_OFFSET(74));
_CONFUSE_G_UPDATE_FUNCTION(_confused_K, _CONFUSE_WRAPPED_OFFSET(75));
_CONFUSE_G_UPDATE_FUNCTION(_confused_L, _CONFUSE_WRAPPED_OFFSET(76));
_CONFUSE_G_UPDATE_FUNCTION(_confused_M, _CONFUSE_WRAPPED_OFFSET(77));
_CONFUSE_G_UPDATE_FUNCTION(_confused_N, _CONFUSE_WRAPPED_OFFSET(78));
_CONFUSE_G_UPDATE_FUNCTION(_confused_O, _CONFUSE_WRAPPED_OFFSET(79));
_CONFUSE_G_UPDATE_FUNCTION(_confused_P, _CONFUSE_WRAPPED_OFFSET(80));
_CONFUSE_G_UPDATE_FUNCTION(_confused_Q, _CONFUSE_WRAPPED_OFFSET(81));
_CONFUSE_G_UPDATE_FUNCTION(_confused_R, _CONFUSE_WRAPPED_OFFSET(82));
_CONFUSE_G_UPDATE_FUNCTION(_confused_S, _CONFUSE_WRAPPED_OFFSET(83));
_CONFUSE_G_UPDATE_FUNCTION(_confused_T, _CONFUSE_WRAPPED_OFFSET(84));
_CONFUSE_G_UPDATE_FUNCTION(_confused_U, _CONFUSE_WRAPPED_OFFSET(85));
_CONFUSE_G_UPDATE_FUNCTION(_confused_V, _CONFUSE_WRAPPED_OFFSET(86));
_CONFUSE_G_UPDATE_FUNCTION(_confused_W, _CONFUSE_WRAPPED_OFFSET(87));
_CONFUSE_G_UPDATE_FUNCTION(_confused_X, _CONFUSE_WRAPPED_OFFSET(88));
_CONFUSE_G_UPDATE_FUNCTION(_confused_Y, _CONFUSE_WRAPPED_OFFSET(89));
_CONFUSE_G_UPDATE_FUNCTION(_confused_Z, _CONFUSE_WRAPPED_OFFSET(90));
_CONFUSE_G_UPDATE_FUNCTION(_confused__, _CONFUSE_WRAPPED_OFFSET(95));

// Table: 2, base: 0x60
_CONFUSE_G_UPDATE_FUNCTION(_confused_a, _CONFUSE_WRAPPED_OFFSET(129));
_CONFUSE_G_UPDATE_FUNCTION(_confused_b, _CONFUSE_WRAPPED_OFFSET(130));
_CONFUSE_G_UPDATE_FUNCTION(_confused_c, _CONFUSE_WRAPPED_OFFSET(131));
_CONFUSE_G_UPDATE_FUNCTION(_confused_d, _CONFUSE_WRAPPED_OFFSET(132));
_CONFUSE_G_UPDATE_FUNCTION(_confused_e, _CONFUSE_WRAPPED_OFFSET(133));
_CONFUSE_G_UPDATE_FUNCTION(_confused_f, _CONFUSE_WRAPPED_OFFSET(134));
_CONFUSE_G_UPDATE_FUNCTION(_confused_g, _CONFUSE_WRAPPED_OFFSET(135));
_CONFUSE_G_UPDATE_FUNCTION(_confused_h, _CONFUSE_WRAPPED_OFFSET(136));
_CONFUSE_G_UPDATE_FUNCTION(_confused_i, _CONFUSE_WRAPPED_OFFSET(137));
_CONFUSE_G_UPDATE_FUNCTION(_confused_j, _CONFUSE_WRAPPED_OFFSET(138));
_CONFUSE_G_UPDATE_FUNCTION(_confused_k, _CONFUSE_WRAPPED_OFFSET(139));
_CONFUSE_G_UPDATE_FUNCTION(_confused_l, _CONFUSE_WRAPPED_OFFSET(140));
_CONFUSE_G_UPDATE_FUNCTION(_confused_m, _CONFUSE_WRAPPED_OFFSET(141));
_CONFUSE_G_UPDATE_FUNCTION(_confused_n, _CONFUSE_WRAPPED_OFFSET(142));
_CONFUSE_G_UPDATE_FUNCTION(_confused_o, _CONFUSE_WRAPPED_OFFSET(143));
_CONFUSE_G_UPDATE_FUNCTION(_confused_p, _CONFUSE_WRAPPED_OFFSET(144));
_CONFUSE_G_UPDATE_FUNCTION(_confused_q, _CONFUSE_WRAPPED_OFFSET(145));
_CONFUSE_G_UPDATE_FUNCTION(_confused_r, _CONFUSE_WRAPPED_OFFSET(146));
_CONFUSE_G_UPDATE_FUNCTION(_confused_s, _CONFUSE_WRAPPED_OFFSET(147));
_CONFUSE_G_UPDATE_FUNCTION(_confused_t, _CONFUSE_WRAPPED_OFFSET(148));
_CONFUSE_G_UPDATE_FUNCTION(_confused_u, _CONFUSE_WRAPPED_OFFSET(149));
_CONFUSE_G_UPDATE_FUNCTION(_confused_v, _CONFUSE_WRAPPED_OFFSET(150));
_CONFUSE_G_UPDATE_FUNCTION(_confused_w, _CONFUSE_WRAPPED_OFFSET(151));
_CONFUSE_G_UPDATE_FUNCTION(_confused_x, _CONFUSE_WRAPPED_OFFSET(152));
_CONFUSE_G_UPDATE_FUNCTION(_confused_y, _CONFUSE_WRAPPED_OFFSET(153));
_CONFUSE_G_UPDATE_FUNCTION(_confused_z, _CONFUSE_WRAPPED_OFFSET(154));

#define _CONFUSE_FUNCTION_NAME(NAME) _confused_ ## NAME

#define _CONFUSE_2(_1, _2) _CONFUSE_FUNCTION_NAME(_2)(_CONFUSE_FUNCTION_NAME(_1)(_confused_init(2)))
#define _CONFUSE_3(_1, _2, _3) _CONFUSE_FUNCTION_NAME(_3)(_CONFUSE_FUNCTION_NAME(_2)(_CONFUSE_FUNCTION_NAME(_1)(_confused_init(3))))
#define _CONFUSE_4(_1, _2, _3, _4) _CONFUSE_FUNCTION_NAME(_4)(_CONFUSE_FUNCTION_NAME(_3)(_CONFUSE_FUNCTION_NAME(_2)(_CONFUSE_FUNCTION_NAME(_1)(_confused_init(4)))))
#define _CONFUSE_5(_1, _2, _3, _4, _5) _CONFUSE_FUNCTION_NAME(_5)(_CONFUSE_FUNCTION_NAME(_4)(_CONFUSE_FUNCTION_NAME(_3)(_CONFUSE_FUNCTION_NAME(_2)(_CONFUSE_FUNCTION_NAME(_1)(_confused_init(5))))))
#define _CONFUSE_6(_1, _2, _3, _4, _5, _6) _CONFUSE_FUNCTION_NAME(_6)(_CONFUSE_FUNCTION_NAME(_5)(_CONFUSE_FUNCTION_NAME(_4)(_CONFUSE_FUNCTION_NAME(_3)(_CONFUSE_FUNCTION_NAME(_2)(_CONFUSE_FUNCTION_NAME(_1)(_confused_init(6)))))))
#define _CONFUSE_7(_1, _2, _3, _4, _5, _6, _7) _CONFUSE_FUNCTION_NAME(_7)(_CONFUSE_FUNCTION_NAME(_6)(_CONFUSE_FUNCTION_NAME(_5)(_CONFUSE_FUNCTION_NAME(_4)(_CONFUSE_FUNCTION_NAME(_3)(_CONFUSE_FUNCTION_NAME(_2)(_CONFUSE_FUNCTION_NAME(_1)(_confused_init(7))))))))
#define _CONFUSE_8(_1, _2, _3, _4, _5, _6, _7, _8) _CONFUSE_FUNCTION_NAME(_8)(_CONFUSE_FUNCTION_NAME(_7)(_CONFUSE_FUNCTION_NAME(_6)(_CONFUSE_FUNCTION_NAME(_5)(_CONFUSE_FUNCTION_NAME(_4)(_CONFUSE_FUNCTION_NAME(_3)(_CONFUSE_FUNCTION_NAME(_2)(_CONFUSE_FUNCTION_NAME(_1)(_confused_init(8)))))))))
#define _CONFUSE_9(_1, _2, _3, _4, _5, _6, _7, _8, _9) _CONFUSE_FUNCTION_NAME(_9)(_CONFUSE_FUNCTION_NAME(_8)(_CONFUSE_FUNCTION_NAME(_7)(_CONFUSE_FUNCTION_NAME(_6)(_CONFUSE_FUNCTION_NAME(_5)(_CONFUSE_FUNCTION_NAME(_4)(_CONFUSE_FUNCTION_NAME(_3)(_CONFUSE_FUNCTION_NAME(_2)(_CONFUSE_FUNCTION_NAME(_1)(_confused_init(9))))))))))
#define _CONFUSE_10(_1, _2, _3, _4, _5, _6, _7, _8, _9, _10) _CONFUSE_FUNCTION_NAME(_10)(_CONFUSE_FUNCTION_NAME(_9)(_CONFUSE_FUNCTION_NAME(_8)(_CONFUSE_FUNCTION_NAME(_7)(_CONFUSE_FUNCTION_NAME(_6)(_CONFUSE_FUNCTION_NAME(_5)(_CONFUSE_FUNCTION_NAME(_4)(_CONFUSE_FUNCTION_NAME(_3)(_CONFUSE_FUNCTION_NAME(_2)(_CONFUSE_FUNCTION_NAME(_1)(_confused_init(10)))))))))))
#define _CONFUSE_11(_1, _2, _3, _4, _5, _6, _7, _8, _9, _10, _11) _CONFUSE_FUNCTION_NAME(_11)(_CONFUSE_FUNCTION_NAME(_10)(_CONFUSE_FUNCTION_NAME(_9)(_CONFUSE_FUNCTION_NAME(_8)(_CONFUSE_FUNCTION_NAME(_7)(_CONFUSE_FUNCTION_NAME(_6)(_CONFUSE_FUNCTION_NAME(_5)(_CONFUSE_FUNCTION_NAME(_4)(_CONFUSE_FUNCTION_NAME(_3)(_CONFUSE_FUNCTION_NAME(_2)(_CONFUSE_FUNCTION_NAME(_1)(_confused_init(11))))))))))))
#define _CONFUSE_12(_1, _2, _3, _4, _5, _6, _7, _8, _9, _10, _11, _12) _CONFUSE_FUNCTION_NAME(_12)(_CONFUSE_FUNCTION_NAME(_11)(_CONFUSE_FUNCTION_NAME(_10)(_CONFUSE_FUNCTION_NAME(_9)(_CONFUSE_FUNCTION_NAME(_8)(_CONFUSE_FUNCTION_NAME(_7)(_CONFUSE_FUNCTION_NAME(_6)(_CONFUSE_FUNCTION_NAME(_5)(_CONFUSE_FUNCTION_NAME(_4)(_CONFUSE_FUNCTION_NAME(_3)(_CONFUSE_FUNCTION_NAME(_2)(_CONFUSE_FUNCTION_NAME(_1)(_confused_init(12)))))))))))))
#define _CONFUSE_13(_1, _2, _3, _4, _5, _6, _7, _8, _9, _10, _11, _12, _13) _CONFUSE_FUNCTION_NAME(_13)(_CONFUSE_FUNCTION_NAME(_12)(_CONFUSE_FUNCTION_NAME(_11)(_CONFUSE_FUNCTION_NAME(_10)(_CONFUSE_FUNCTION_NAME(_9)(_CONFUSE_FUNCTION_NAME(_8)(_CONFUSE_FUNCTION_NAME(_7)(_CONFUSE_FUNCTION_NAME(_6)(_CONFUSE_FUNCTION_NAME(_5)(_CONFUSE_FUNCTION_NAME(_4)(_CONFUSE_FUNCTION_NAME(_3)(_CONFUSE_FUNCTION_NAME(_2)(_CONFUSE_FUNCTION_NAME(_1)(_confused_init(13))))))))))))))
#define _CONFUSE_14(_1, _2, _3, _4, _5, _6, _7, _8, _9, _10, _11, _12, _13, _14) _CONFUSE_FUNCTION_NAME(_14)(_CONFUSE_FUNCTION_NAME(_13)(_CONFUSE_FUNCTION_NAME(_12)(_CONFUSE_FUNCTION_NAME(_11)(_CONFUSE_FUNCTION_NAME(_10)(_CONFUSE_FUNCTION_NAME(_9)(_CONFUSE_FUNCTION_NAME(_8)(_CONFUSE_FUNCTION_NAME(_7)(_CONFUSE_FUNCTION_NAME(_6)(_CONFUSE_FUNCTION_NAME(_5)(_CONFUSE_FUNCTION_NAME(_4)(_CONFUSE_FUNCTION_NAME(_3)(_CONFUSE_FUNCTION_NAME(_2)(_CONFUSE_FUNCTION_NAME(_1)(_confused_init(14)))))))))))))))
#define _CONFUSE_15(_1, _2, _3, _4, _5, _6, _7, _8, _9, _10, _11, _12, _13, _14, _15) _CONFUSE_FUNCTION_NAME(_15)(_CONFUSE_FUNCTION_NAME(_14)(_CONFUSE_FUNCTION_NAME(_13)(_CONFUSE_FUNCTION_NAME(_12)(_CONFUSE_FUNCTION_NAME(_11)(_CONFUSE_FUNCTION_NAME(_10)(_CONFUSE_FUNCTION_NAME(_9)(_CONFUSE_FUNCTION_NAME(_8)(_CONFUSE_FUNCTION_NAME(_7)(_CONFUSE_FUNCTION_NAME(_6)(_CONFUSE_FUNCTION_NAME(_5)(_CONFUSE_FUNCTION_NAME(_4)(_CONFUSE_FUNCTION_NAME(_3)(_CONFUSE_FUNCTION_NAME(_2)(_CONFUSE_FUNCTION_NAME(_1)(_confused_init(15))))))))))))))))
#define _CONFUSE_16(_1, _2, _3, _4, _5, _6, _7, _8, _9, _10, _11, _12, _13, _14, _15, _16) _CONFUSE_FUNCTION_NAME(_16)(_CONFUSE_FUNCTION_NAME(_15)(_CONFUSE_FUNCTION_NAME(_14)(_CONFUSE_FUNCTION_NAME(_13)(_CONFUSE_FUNCTION_NAME(_12)(_CONFUSE_FUNCTION_NAME(_11)(_CONFUSE_FUNCTION_NAME(_10)(_CONFUSE_FUNCTION_NAME(_9)(_CONFUSE_FUNCTION_NAME(_8)(_CONFUSE_FUNCTION_NAME(_7)(_CONFUSE_FUNCTION_NAME(_6)(_CONFUSE_FUNCTION_NAME(_5)(_CONFUSE_FUNCTION_NAME(_4)(_CONFUSE_FUNCTION_NAME(_3)(_CONFUSE_FUNCTION_NAME(_2)(_CONFUSE_FUNCTION_NAME(_1)(_confused_init(16)))))))))))))))))
#define _CONFUSE_17(_1, _2, _3, _4, _5, _6, _7, _8, _9, _10, _11, _12, _13, _14, _15, _16, _17) _CONFUSE_FUNCTION_NAME(_17)(_CONFUSE_FUNCTION_NAME(_16)(_CONFUSE_FUNCTION_NAME(_15)(_CONFUSE_FUNCTION_NAME(_14)(_CONFUSE_FUNCTION_NAME(_13)(_CONFUSE_FUNCTION_NAME(_12)(_CONFUSE_FUNCTION_NAME(_11)(_CONFUSE_FUNCTION_NAME(_10)(_CONFUSE_FUNCTION_NAME(_9)(_CONFUSE_FUNCTION_NAME(_8)(_CONFUSE_FUNCTION_NAME(_7)(_CONFUSE_FUNCTION_NAME(_6)(_CONFUSE_FUNCTION_NAME(_5)(_CONFUSE_FUNCTION_NAME(_4)(_CONFUSE_FUNCTION_NAME(_3)(_CONFUSE_FUNCTION_NAME(_2)(_CONFUSE_FUNCTION_NAME(_1)(_confused_init(17))))))))))))))))))
#define _CONFUSE_18(_1, _2, _3, _4, _5, _6, _7, _8, _9, _10, _11, _12, _13, _14, _15, _16, _17, _18) _CONFUSE_FUNCTION_NAME(_18)(_CONFUSE_FUNCTION_NAME(_17)(_CONFUSE_FUNCTION_NAME(_16)(_CONFUSE_FUNCTION_NAME(_15)(_CONFUSE_FUNCTION_NAME(_14)(_CONFUSE_FUNCTION_NAME(_13)(_CONFUSE_FUNCTION_NAME(_12)(_CONFUSE_FUNCTION_NAME(_11)(_CONFUSE_FUNCTION_NAME(_10)(_CONFUSE_FUNCTION_NAME(_9)(_CONFUSE_FUNCTION_NAME(_8)(_CONFUSE_FUNCTION_NAME(_7)(_CONFUSE_FUNCTION_NAME(_6)(_CONFUSE_FUNCTION_NAME(_5)(_CONFUSE_FUNCTION_NAME(_4)(_CONFUSE_FUNCTION_NAME(_3)(_CONFUSE_FUNCTION_NAME(_2)(_CONFUSE_FUNCTION_NAME(_1)(_confused_init(18)))))))))))))))))))
#define _CONFUSE_19(_1, _2, _3, _4, _5, _6, _7, _8, _9, _10, _11, _12, _13, _14, _15, _16, _17, _18, _19) _CONFUSE_FUNCTION_NAME(_19)(_CONFUSE_FUNCTION_NAME(_18)(_CONFUSE_FUNCTION_NAME(_17)(_CONFUSE_FUNCTION_NAME(_16)(_CONFUSE_FUNCTION_NAME(_15)(_CONFUSE_FUNCTION_NAME(_14)(_CONFUSE_FUNCTION_NAME(_13)(_CONFUSE_FUNCTION_NAME(_12)(_CONFUSE_FUNCTION_NAME(_11)(_CONFUSE_FUNCTION_NAME(_10)(_CONFUSE_FUNCTION_NAME(_9)(_CONFUSE_FUNCTION_NAME(_8)(_CONFUSE_FUNCTION_NAME(_7)(_CONFUSE_FUNCTION_NAME(_6)(_CONFUSE_FUNCTION_NAME(_5)(_CONFUSE_FUNCTION_NAME(_4)(_CONFUSE_FUNCTION_NAME(_3)(_CONFUSE_FUNCTION_NAME(_2)(_CONFUSE_FUNCTION_NAME(_1)(_confused_init(19))))))))))))))))))))
#define _CONFUSE_20(_1, _2, _3, _4, _5, _6, _7, _8, _9, _10, _11, _12, _13, _14, _15, _16, _17, _18, _19, _20) _CONFUSE_FUNCTION_NAME(_20)(_CONFUSE_FUNCTION_NAME(_19)(_CONFUSE_FUNCTION_NAME(_18)(_CONFUSE_FUNCTION_NAME(_17)(_CONFUSE_FUNCTION_NAME(_16)(_CONFUSE_FUNCTION_NAME(_15)(_CONFUSE_FUNCTION_NAME(_14)(_CONFUSE_FUNCTION_NAME(_13)(_CONFUSE_FUNCTION_NAME(_12)(_CONFUSE_FUNCTION_NAME(_11)(_CONFUSE_FUNCTION_NAME(_10)(_CONFUSE_FUNCTION_NAME(_9)(_CONFUSE_FUNCTION_NAME(_8)(_CONFUSE_FUNCTION_NAME(_7)(_CONFUSE_FUNCTION_NAME(_6)(_CONFUSE_FUNCTION_NAME(_5)(_CONFUSE_FUNCTION_NAME(_4)(_CONFUSE_FUNCTION_NAME(_3)(_CONFUSE_FUNCTION_NAME(_2)(_CONFUSE_FUNCTION_NAME(_1)(_confused_init(20)))))))))))))))))))))
#define _CONFUSE_21(_1, _2, _3, _4, _5, _6, _7, _8, _9, _10, _11, _12, _13, _14, _15, _16, _17, _18, _19, _20, _21) _CONFUSE_FUNCTION_NAME(_21)(_CONFUSE_FUNCTION_NAME(_20)(_CONFUSE_FUNCTION_NAME(_19)(_CONFUSE_FUNCTION_NAME(_18)(_CONFUSE_FUNCTION_NAME(_17)(_CONFUSE_FUNCTION_NAME(_16)(_CONFUSE_FUNCTION_NAME(_15)(_CONFUSE_FUNCTION_NAME(_14)(_CONFUSE_FUNCTION_NAME(_13)(_CONFUSE_FUNCTION_NAME(_12)(_CONFUSE_FUNCTION_NAME(_11)(_CONFUSE_FUNCTION_NAME(_10)(_CONFUSE_FUNCTION_NAME(_9)(_CONFUSE_FUNCTION_NAME(_8)(_CONFUSE_FUNCTION_NAME(_7)(_CONFUSE_FUNCTION_NAME(_6)(_CONFUSE_FUNCTION_NAME(_5)(_CONFUSE_FUNCTION_NAME(_4)(_CONFUSE_FUNCTION_NAME(_3)(_CONFUSE_FUNCTION_NAME(_2)(_CONFUSE_FUNCTION_NAME(_1)(_confused_init(21))))))))))))))))))))))
#define _CONFUSE_22(_1, _2, _3, _4, _5, _6, _7, _8, _9, _10, _11, _12, _13, _14, _15, _16, _17, _18, _19, _20, _21, _22) _CONFUSE_FUNCTION_NAME(_22)(_CONFUSE_FUNCTION_NAME(_21)(_CONFUSE_FUNCTION_NAME(_20)(_CONFUSE_FUNCTION_NAME(_19)(_CONFUSE_FUNCTION_NAME(_18)(_CONFUSE_FUNCTION_NAME(_17)(_CONFUSE_FUNCTION_NAME(_16)(_CONFUSE_FUNCTION_NAME(_15)(_CONFUSE_FUNCTION_NAME(_14)(_CONFUSE_FUNCTION_NAME(_13)(_CONFUSE_FUNCTION_NAME(_12)(_CONFUSE_FUNCTION_NAME(_11)(_CONFUSE_FUNCTION_NAME(_10)(_CONFUSE_FUNCTION_NAME(_9)(_CONFUSE_FUNCTION_NAME(_8)(_CONFUSE_FUNCTION_NAME(_7)(_CONFUSE_FUNCTION_NAME(_6)(_CONFUSE_FUNCTION_NAME(_5)(_CONFUSE_FUNCTION_NAME(_4)(_CONFUSE_FUNCTION_NAME(_3)(_CONFUSE_FUNCTION_NAME(_2)(_CONFUSE_FUNCTION_NAME(_1)(_confused_init(22)))))))))))))))))))))))
#define _CONFUSE_23(_1, _2, _3, _4, _5, _6, _7, _8, _9, _10, _11, _12, _13, _14, _15, _16, _17, _18, _19, _20, _21, _22, _23) _CONFUSE_FUNCTION_NAME(_23)(_CONFUSE_FUNCTION_NAME(_22)(_CONFUSE_FUNCTION_NAME(_21)(_CONFUSE_FUNCTION_NAME(_20)(_CONFUSE_FUNCTION_NAME(_19)(_CONFUSE_FUNCTION_NAME(_18)(_CONFUSE_FUNCTION_NAME(_17)(_CONFUSE_FUNCTION_NAME(_16)(_CONFUSE_FUNCTION_NAME(_15)(_CONFUSE_FUNCTION_NAME(_14)(_CONFUSE_FUNCTION_NAME(_13)(_CONFUSE_FUNCTION_NAME(_12)(_CONFUSE_FUNCTION_NAME(_11)(_CONFUSE_FUNCTION_NAME(_10)(_CONFUSE_FUNCTION_NAME(_9)(_CONFUSE_FUNCTION_NAME(_8)(_CONFUSE_FUNCTION_NAME(_7)(_CONFUSE_FUNCTION_NAME(_6)(_CONFUSE_FUNCTION_NAME(_5)(_CONFUSE_FUNCTION_NAME(_4)(_CONFUSE_FUNCTION_NAME(_3)(_CONFUSE_FUNCTION_NAME(_2)(_CONFUSE_FUNCTION_NAME(_1)(_confused_init(23))))))))))))))))))))))))
#define _CONFUSE_24(_1, _2, _3, _4, _5, _6, _7, _8, _9, _10, _11, _12, _13, _14, _15, _16, _17, _18, _19, _20, _21, _22, _23, _24) _CONFUSE_FUNCTION_NAME(_24)(_CONFUSE_FUNCTION_NAME(_23)(_CONFUSE_FUNCTION_NAME(_22)(_CONFUSE_FUNCTION_NAME(_21)(_CONFUSE_FUNCTION_NAME(_20)(_CONFUSE_FUNCTION_NAME(_19)(_CONFUSE_FUNCTION_NAME(_18)(_CONFUSE_FUNCTION_NAME(_17)(_CONFUSE_FUNCTION_NAME(_16)(_CONFUSE_FUNCTION_NAME(_15)(_CONFUSE_FUNCTION_NAME(_14)(_CONFUSE_FUNCTION_NAME(_13)(_CONFUSE_FUNCTION_NAME(_12)(_CONFUSE_FUNCTION_NAME(_11)(_CONFUSE_FUNCTION_NAME(_10)(_CONFUSE_FUNCTION_NAME(_9)(_CONFUSE_FUNCTION_NAME(_8)(_CONFUSE_FUNCTION_NAME(_7)(_CONFUSE_FUNCTION_NAME(_6)(_CONFUSE_FUNCTION_NAME(_5)(_CONFUSE_FUNCTION_NAME(_4)(_CONFUSE_FUNCTION_NAME(_3)(_CONFUSE_FUNCTION_NAME(_2)(_CONFUSE_FUNCTION_NAME(_1)(_confused_init(24)))))))))))))))))))))))))
#define _CONFUSE_25(_1, _2, _3, _4, _5, _6, _7, _8, _9, _10, _11, _12, _13, _14, _15, _16, _17, _18, _19, _20, _21, _22, _23, _24, _25) _CONFUSE_FUNCTION_NAME(_25)(_CONFUSE_FUNCTION_NAME(_24)(_CONFUSE_FUNCTION_NAME(_23)(_CONFUSE_FUNCTION_NAME(_22)(_CONFUSE_FUNCTION_NAME(_21)(_CONFUSE_FUNCTION_NAME(_20)(_CONFUSE_FUNCTION_NAME(_19)(_CONFUSE_FUNCTION_NAME(_18)(_CONFUSE_FUNCTION_NAME(_17)(_CONFUSE_FUNCTION_NAME(_16)(_CONFUSE_FUNCTION_NAME(_15)(_CONFUSE_FUNCTION_NAME(_14)(_CONFUSE_FUNCTION_NAME(_13)(_CONFUSE_FUNCTION_NAME(_12)(_CONFUSE_FUNCTION_NAME(_11)(_CONFUSE_FUNCTION_NAME(_10)(_CONFUSE_FUNCTION_NAME(_9)(_CONFUSE_FUNCTION_NAME(_8)(_CONFUSE_FUNCTION_NAME(_7)(_CONFUSE_FUNCTION_NAME(_6)(_CONFUSE_FUNCTION_NAME(_5)(_CONFUSE_FUNCTION_NAME(_4)(_CONFUSE_FUNCTION_NAME(_3)(_CONFUSE_FUNCTION_NAME(_2)(_CONFUSE_FUNCTION_NAME(_1)(_confused_init(25))))))))))))))))))))))))))
#define _CONFUSE_26(_1, _2, _3, _4, _5, _6, _7, _8, _9, _10, _11, _12, _13, _14, _15, _16, _17, _18, _19, _20, _21, _22, _23, _24, _25, _26) _CONFUSE_FUNCTION_NAME(_26)(_CONFUSE_FUNCTION_NAME(_25)(_CONFUSE_FUNCTION_NAME(_24)(_CONFUSE_FUNCTION_NAME(_23)(_CONFUSE_FUNCTION_NAME(_22)(_CONFUSE_FUNCTION_NAME(_21)(_CONFUSE_FUNCTION_NAME(_20)(_CONFUSE_FUNCTION_NAME(_19)(_CONFUSE_FUNCTION_NAME(_18)(_CONFUSE_FUNCTION_NAME(_17)(_CONFUSE_FUNCTION_NAME(_16)(_CONFUSE_FUNCTION_NAME(_15)(_CONFUSE_FUNCTION_NAME(_14)(_CONFUSE_FUNCTION_NAME(_13)(_CONFUSE_FUNCTION_NAME(_12)(_CONFUSE_FUNCTION_NAME(_11)(_CONFUSE_FUNCTION_NAME(_10)(_CONFUSE_FUNCTION_NAME(_9)(_CONFUSE_FUNCTION_NAME(_8)(_CONFUSE_FUNCTION_NAME(_7)(_CONFUSE_FUNCTION_NAME(_6)(_CONFUSE_FUNCTION_NAME(_5)(_CONFUSE_FUNCTION_NAME(_4)(_CONFUSE_FUNCTION_NAME(_3)(_CONFUSE_FUNCTION_NAME(_2)(_CONFUSE_FUNCTION_NAME(_1)(_confused_init(26)))))))))))))))))))))))))))
#define _CONFUSE_27(_1, _2, _3, _4, _5, _6, _7, _8, _9, _10, _11, _12, _13, _14, _15, _16, _17, _18, _19, _20, _21, _22, _23, _24, _25, _26, _27) _CONFUSE_FUNCTION_NAME(_27)(_CONFUSE_FUNCTION_NAME(_26)(_CONFUSE_FUNCTION_NAME(_25)(_CONFUSE_FUNCTION_NAME(_24)(_CONFUSE_FUNCTION_NAME(_23)(_CONFUSE_FUNCTION_NAME(_22)(_CONFUSE_FUNCTION_NAME(_21)(_CONFUSE_FUNCTION_NAME(_20)(_CONFUSE_FUNCTION_NAME(_19)(_CONFUSE_FUNCTION_NAME(_18)(_CONFUSE_FUNCTION_NAME(_17)(_CONFUSE_FUNCTION_NAME(_16)(_CONFUSE_FUNCTION_NAME(_15)(_CONFUSE_FUNCTION_NAME(_14)(_CONFUSE_FUNCTION_NAME(_13)(_CONFUSE_FUNCTION_NAME(_12)(_CONFUSE_FUNCTION_NAME(_11)(_CONFUSE_FUNCTION_NAME(_10)(_CONFUSE_FUNCTION_NAME(_9)(_CONFUSE_FUNCTION_NAME(_8)(_CONFUSE_FUNCTION_NAME(_7)(_CONFUSE_FUNCTION_NAME(_6)(_CONFUSE_FUNCTION_NAME(_5)(_CONFUSE_FUNCTION_NAME(_4)(_CONFUSE_FUNCTION_NAME(_3)(_CONFUSE_FUNCTION_NAME(_2)(_CONFUSE_FUNCTION_NAME(_1)(_confused_init(27))))))))))))))))))))))))))))
#define _CONFUSE_28(_1, _2, _3, _4, _5, _6, _7, _8, _9, _10, _11, _12, _13, _14, _15, _16, _17, _18, _19, _20, _21, _22, _23, _24, _25, _26, _27, _28) _CONFUSE_FUNCTION_NAME(_28)(_CONFUSE_FUNCTION_NAME(_27)(_CONFUSE_FUNCTION_NAME(_26)(_CONFUSE_FUNCTION_NAME(_25)(_CONFUSE_FUNCTION_NAME(_24)(_CONFUSE_FUNCTION_NAME(_23)(_CONFUSE_FUNCTION_NAME(_22)(_CONFUSE_FUNCTION_NAME(_21)(_CONFUSE_FUNCTION_NAME(_20)(_CONFUSE_FUNCTION_NAME(_19)(_CONFUSE_FUNCTION_NAME(_18)(_CONFUSE_FUNCTION_NAME(_17)(_CONFUSE_FUNCTION_NAME(_16)(_CONFUSE_FUNCTION_NAME(_15)(_CONFUSE_FUNCTION_NAME(_14)(_CONFUSE_FUNCTION_NAME(_13)(_CONFUSE_FUNCTION_NAME(_12)(_CONFUSE_FUNCTION_NAME(_11)(_CONFUSE_FUNCTION_NAME(_10)(_CONFUSE_FUNCTION_NAME(_9)(_CONFUSE_FUNCTION_NAME(_8)(_CONFUSE_FUNCTION_NAME(_7)(_CONFUSE_FUNCTION_NAME(_6)(_CONFUSE_FUNCTION_NAME(_5)(_CONFUSE_FUNCTION_NAME(_4)(_CONFUSE_FUNCTION_NAME(_3)(_CONFUSE_FUNCTION_NAME(_2)(_CONFUSE_FUNCTION_NAME(_1)(_confused_init(28)))))))))))))))))))))))))))))
#define _CONFUSE_29(_1, _2, _3, _4, _5, _6, _7, _8, _9, _10, _11, _12, _13, _14, _15, _16, _17, _18, _19, _20, _21, _22, _23, _24, _25, _26, _27, _28, _29) _CONFUSE_FUNCTION_NAME(_29)(_CONFUSE_FUNCTION_NAME(_28)(_CONFUSE_FUNCTION_NAME(_27)(_CONFUSE_FUNCTION_NAME(_26)(_CONFUSE_FUNCTION_NAME(_25)(_CONFUSE_FUNCTION_NAME(_24)(_CONFUSE_FUNCTION_NAME(_23)(_CONFUSE_FUNCTION_NAME(_22)(_CONFUSE_FUNCTION_NAME(_21)(_CONFUSE_FUNCTION_NAME(_20)(_CONFUSE_FUNCTION_NAME(_19)(_CONFUSE_FUNCTION_NAME(_18)(_CONFUSE_FUNCTION_NAME(_17)(_CONFUSE_FUNCTION_NAME(_16)(_CONFUSE_FUNCTION_NAME(_15)(_CONFUSE_FUNCTION_NAME(_14)(_CONFUSE_FUNCTION_NAME(_13)(_CONFUSE_FUNCTION_NAME(_12)(_CONFUSE_FUNCTION_NAME(_11)(_CONFUSE_FUNCTION_NAME(_10)(_CONFUSE_FUNCTION_NAME(_9)(_CONFUSE_FUNCTION_NAME(_8)(_CONFUSE_FUNCTION_NAME(_7)(_CONFUSE_FUNCTION_NAME(_6)(_CONFUSE_FUNCTION_NAME(_5)(_CONFUSE_FUNCTION_NAME(_4)(_CONFUSE_FUNCTION_NAME(_3)(_CONFUSE_FUNCTION_NAME(_2)(_CONFUSE_FUNCTION_NAME(_1)(_confused_init(29))))))))))))))))))))))))))))))
#define _CONFUSE_30(_1, _2, _3, _4, _5, _6, _7, _8, _9, _10, _11, _12, _13, _14, _15, _16, _17, _18, _19, _20, _21, _22, _23, _24, _25, _26, _27, _28, _29, _30) _CONFUSE_FUNCTION_NAME(_30)(_CONFUSE_FUNCTION_NAME(_29)(_CONFUSE_FUNCTION_NAME(_28)(_CONFUSE_FUNCTION_NAME(_27)(_CONFUSE_FUNCTION_NAME(_26)(_CONFUSE_FUNCTION_NAME(_25)(_CONFUSE_FUNCTION_NAME(_24)(_CONFUSE_FUNCTION_NAME(_23)(_CONFUSE_FUNCTION_NAME(_22)(_CONFUSE_FUNCTION_NAME(_21)(_CONFUSE_FUNCTION_NAME(_20)(_CONFUSE_FUNCTION_NAME(_19)(_CONFUSE_FUNCTION_NAME(_18)(_CONFUSE_FUNCTION_NAME(_17)(_CONFUSE_FUNCTION_NAME(_16)(_CONFUSE_FUNCTION_NAME(_15)(_CONFUSE_FUNCTION_NAME(_14)(_CONFUSE_FUNCTION_NAME(_13)(_CONFUSE_FUNCTION_NAME(_12)(_CONFUSE_FUNCTION_NAME(_11)(_CONFUSE_FUNCTION_NAME(_10)(_CONFUSE_FUNCTION_NAME(_9)(_CONFUSE_FUNCTION_NAME(_8)(_CONFUSE_FUNCTION_NAME(_7)(_CONFUSE_FUNCTION_NAME(_6)(_CONFUSE_FUNCTION_NAME(_5)(_CONFUSE_FUNCTION_NAME(_4)(_CONFUSE_FUNCTION_NAME(_3)(_CONFUSE_FUNCTION_NAME(_2)(_CONFUSE_FUNCTION_NAME(_1)(_confused_init(30)))))))))))))))))))))))))))))))

#define _CONFUSE_NUM_ARGS_(_1, _2, _3, _4, _5, _6, _7, _8, _9, _10, _11, _12, _13, _14, _15, _16, _17, _18, _19, _20, _21, _22, _23, _24, _25, _26, _27, _28, _29, _30, TOTAL, ...) TOTAL
#define _CONFUSE_NUM_ARGS(...) _CONFUSE_NUM_ARGS_(__VA_ARGS__, 30, 29, 28, 27, 26, 25, 24, 23, 22, 21, 20, 19, 18, 17, 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0)
#define _CONFUSE_CONCATE_(X, Y) X##Y
#define _CONFUSE_CONCATE(MACRO, NUMBER) _CONFUSE_CONCATE_(MACRO, NUMBER)
#define _CONFUSE_VA_MACRO(MACRO, ...) _CONFUSE_CONCATE(MACRO, _CONFUSE_NUM_ARGS (__VA_ARGS__))(__VA_ARGS__)

#define _CONFUSE(...) _CONFUSE_VA_MACRO(_CONFUSE_, __VA_ARGS__)

/*
    拟合函数，保证: 0 => 0x30, 1 => 0x40, 2 => 0x60
    其他参数无意义
 */
static inline uint8_t _confused_base_of(uint8_t table_id)
{
    uint8_t table_id_times_3 = table_id << table_id;
    if (table_id % 2 == 0) {
        table_id_times_3 -= table_id;
    } else {
        table_id_times_3 += table_id;
    }                                                                                   // 0 => 0, 1 => 3, 2 => 6

    const uint8_t table_id_squared = (uint8_t)(MAX(0, table_id_times_3 - 2));           // 0 => 0, 1 => 1, 2 => 4
    const uint8_t base = (table_id_squared + table_id + 6) << 3;                        // 0 => 0x30, 1 => 0x40, 2 => 0x60

    return base;
}

static inline NSString *_confused_result_with(confused_t *res, size_t n)
{
    char* str = (char *)calloc(n, sizeof(char));
    for (size_t i = 0; i < n - 1; ++i) {
        const uint8_t value = (uint8_t)(res->payload[i] >> 8) ^ _kConfuseMask;
        const uint8_t table_id = (value & 0b11000000) >> 6;
        const uint8_t offset = (value & 0b00111111);
        const uint8_t base = _confused_base_of(table_id);
        str[i] = (char)(base + offset);
    }
    free(res->payload);
    free(res);
    NSString *result = [NSString stringWithCString:str encoding:NSASCIIStringEncoding];
    free(str);
    return result;
}

/*
 * 传入字符列表，返回它们组合出的字符串(NSString)
 *
 * 例如:
 *
 *    NSString *str0 = ET_CONFUSED(A,a,_,1,Z); // => Aa_1Z
 *
 * 最多支持30个字符
 */
#define ET_CONFUSED(...) \
    _confused_result_with(_CONFUSE(__VA_ARGS__), _CONFUSE_NUM_ARGS (__VA_ARGS__) + 1)

static inline BOOL _ne_utility_str_matches(NSString *target, size_t nargs, ...)
{
    if (target == nil) {
        return NO;
    }

    NSRange range = NSMakeRange(0, 0);
    BOOL result = YES;

    va_list args;
    va_start(args, nargs);
    for (size_t i = 0; i < nargs; ++i) {
        NSString *part = va_arg(args, NSString *);
        NSRange substringRange = [target rangeOfString:part];
        if (substringRange.location == NSNotFound || substringRange.location < range.location) {
            result = NO;
            break;
        }
        range = substringRange;
    }
    va_end(args);

    return result;
}

/**
 * 传入一个目标字符串和一个或多个子串，判断字串是否按顺序出现在目标字符串中(可穿插)，参数都必须是 NSString * 类型
 *
 * NSString *targetString = [obj description];
 * BOOL matches = ET_STR_MATCHES(targetString, @"UINavigationBar", @"Background");
 *
 */
#define ET_STR_MATCHES(TARGET, ...) \
    _ne_utility_str_matches(TARGET, _CONFUSE_NUM_ARGS (__VA_ARGS__), __VA_ARGS__)

#ifdef __cplusplus
}
#endif

#endif
