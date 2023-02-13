//
//  ETCommonDefines.h
//  EventTracing-iOS_Example
//
//  Created by dl on 2023/1/5.
//  Copyright © 2023 9446796. All rights reserved.
//

#ifndef ETCommonDefines_h
#define ETCommonDefines_h

/// MARK: 如果你自己启动了 H5 Demo, 则开启如下，如果需要，你还需要修改 `H5_Demo_URL` 的值
//#define H5_Demo_Use_Remote 1

#ifdef H5_Demo_Use_Remote
#define H5_Demo_URL @"http://localhost:8000/"
#else
#define H5_Demo_URL @""
#endif

#endif /* ETCommonDefines_h */
