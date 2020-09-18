//
//  compress.h
//  Bluetooth
//
//  Created by ldc on 2019/11/29.
//  Copyright © 2019 Xiamen Hanin. All rights reserved.
//

#ifndef compress_h
#define compress_h

#include <stdio.h>

/** LZO压缩算法 */
long lzo_compress(void *inData, unsigned inData_len, void *outData);

#endif /* compress_h */
