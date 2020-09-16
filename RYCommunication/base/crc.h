//
//  crc.h
//  RYCommunication
//
//  Created by ldc on 2020/9/16.
//  Copyright © 2020 Xiamen Hanin. All rights reserved.
//

#ifndef crc_h
#define crc_h

#include <stdio.h>

uint32_t ry_crc32(uint32_t key, const uint8_t *buffer, uint32_t len);

#endif /* crc_h */
