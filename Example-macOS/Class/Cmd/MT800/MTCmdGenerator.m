//
//  MTCmdGenerator.m
//  MTSDK
//
//  Created by ldc on 2020/4/13.
//  Copyright © 2020 Xiamen Hanin. All rights reserved.
//

#import "MTCmdGenerator.h"

uint32_t crc32(uint32_t crc,const uint8_t *buffer, uint32_t len);

Byte valSizeForCommonCmd(MTCommonCmdKey key) {
    
    switch (key) {
        case MTCommonCmdKeyShutdownTime:
            return 4;
        case MTCommonCmdKeyPrintDensity:
            return 1;
        case MTCommonCmdKeyPrinterName:
            return 32;
        default:
            break;
    }
    return 0;
}

@implementation MTBitmapSlice

@end

@implementation MTFirmwareSlice

@end

@implementation MTPrinterInfo

- (instancetype)initWithData:(NSData *)data
{
    if (data.length < 12) {
        return nil;
    }
    self = [super init];
    if (self) {
        Byte *head = (Byte *)data.bytes;
        self.status = *((uint16_t *)head);
        head += 2;
        self.idle = *head == 1;
        head++;
        self.electricQuantity = *head;
        head++;
        self.autoShutdownTime = *((uint32_t *)head);
        head += 4;
        self.printDensity = *head;
        head++;
        self.paperType = *head;
        head++;
        self.tphTemperature = *((uint16_t *)head);
    }
    return self;
}

@end

@implementation MTCmdGenerator

+ (NSData *)requestRemainCarbonRibbonCount {
    
    Byte cmd[] = {0x1B, 0x12, 0x53};
    return [NSData dataWithBytes:cmd length:sizeof(cmd)];
}

+ (NSData *)clearPrinterBuffer {
    
    return [NSData dataWithBytes:"\x1b\x12\x43\x1b\x12\x43" length:6];
}

/**
 获取打印机信息
 2个字节状态 1个字节空闲 1个字节电池百分比 4个字节自动关机时间 1个浓度 1个纸张类型(1:A4) 2个温度
 */
+ (NSData *)getPrinterStatusInfo {
    
    return [NSData dataWithBytes:"\x1b\x12\x73\x1b\x12\x73" length:6];
}

/**
 获取碳带耗材品牌，字符串，以00结尾
 */
+ (NSData *)getRibbonConsumablesBrandInfo {
    
    return [NSData dataWithBytes:"\x1b\x12\x52" length:3];
}

/**
 获取碳带剩余量，4个字节，int类型 单位mm
 */
+ (NSData *)getRibbonRemainCount {
    
    return [NSData dataWithBytes:"\x1b\x12\x53" length:3];
}

/**
 获取打印机序列号，字符串，以00结尾
 */
+ (NSData *)getPrinterSerialNumber {
    
    return [NSData dataWithBytes:"\x1b\x12\x4E" length:3];
}

/**
 获取打印机固件版本，字符串，以00结尾
 */
+ (NSData *)getPrinterFirmwareVersion {
    
    return [NSData dataWithBytes:"\x1b\x12\x56" length:3];
}

+ (NSData *)getLengthPrinted {
    
    return [NSData dataWithBytes:"\x1b\x12\x4d\x61" length:4];
}

+ (NSData *)getCarbonInfo:(MTCarbonRibbonProperty)property {
    
    Byte cmd[] = { 0x1b, 0x12, 0x72, property};
    return [NSData dataWithBytes:cmd length:4];
}

+ (NSData *)getPrinterShutdownTime {
    
    return [self commonGetCmd:MTCommonCmdKeyShutdownTime];
}

+ (NSData *)setPrinterShutdownTime:(uint32_t)time {
    
    NSData *content = [NSData dataWithBytes:&time length:4];
    return [self commonSetCmd:MTCommonCmdKeyShutdownTime val:content];
}

+ (NSData *)getPrinterName {
    
    return [self commonGetCmd:MTCommonCmdKeyPrinterName];
}

+ (NSData *)setPrinterDensity:(Byte)density {
    
    return [self commonSetCmd:MTCommonCmdKeyPrintDensity val:[NSData dataWithBytes:&density length:1]];
}

+ (NSData *)getPrinterDensity {
    
    return [self commonGetCmd:MTCommonCmdKeyPrintDensity];
}

+ (NSMutableArray<MTBitmapSlice *> *)sliceImageBitmap:(NSData *)data height:(uint16_t)height {
    
    if (data.length%height != 0) {
        [NSException raise:@"" format:@"%@ parameter error, \"data.length%%width == 0\" is expected.", NSStringFromSelector(_cmd)];
    }
    NSMutableArray<MTBitmapSlice *> *result = [NSMutableArray array];
    NSInteger loc = 0;
    uint16_t bitmapWidth = data.length/height;
    uint16_t maxLength = 32 * bitmapWidth;
    uint16_t pack_serial = 0;
    Byte bitmapHead[] = {0x1b, 0x12, 0x77};
    Byte sliceHead[] = {0x1b, 0x12, 0x76};
    uint32_t crc;
    
    while (data.length > loc) {
        
        uint16_t contentLength = MIN(maxLength, data.length - loc);
        NSData *subData = [data subdataWithRange:NSMakeRange(loc, contentLength)];
        
        NSMutableData *childPackage = [NSMutableData data];
        if (loc == 0) {
            [childPackage appendBytes:bitmapHead length:3];
            [childPackage appendBytes:&bitmapWidth length:2];
            [childPackage appendBytes:&height length:2];
        }
        [childPackage appendBytes:&sliceHead length:3];
        [childPackage appendBytes:&pack_serial length:2];
        [childPackage appendBytes:&contentLength length:2];
        [childPackage appendData:subData];
        
        crc = crc32(0xffffffff, (Byte *)subData.bytes, (uint32_t)subData.length);
        [childPackage appendBytes:&crc length:4];
        
        MTBitmapSlice *slice = [[MTBitmapSlice alloc] init];
        slice.serial = pack_serial;
        slice.data = childPackage;
        [result addObject:slice];
        
        loc += contentLength;
        pack_serial++;
    }
    return result;
}

+ (NSMutableArray<MTFirmwareSlice *> *)sliceFirmware:(NSData *)data {
    
    NSMutableArray<MTFirmwareSlice *> *result = [NSMutableArray array];
    NSInteger loc = 0;
    uint32_t maxLength = 2048;
    uint16_t pack_serial = 0;
    Byte head[17] = {0x1b, 0x1c, 0x26, 0x20, 0x56, 0x31, 0x20, 0x64, 0x6f, 0x20, 0x22, 0x6f, 0x74, 0x61, 0x22, 0x0d, 0x0a};
    uint32_t crc;
    
    while (data.length > loc) {
        
        uint32_t contentLength = (uint32_t)MIN(maxLength, data.length - loc);
        NSData *subData = [data subdataWithRange:NSMakeRange(loc, contentLength)];
        
        NSMutableData *childPackage = [NSMutableData data];
        [childPackage appendBytes:&head length:sizeof(head)];
        uint32_t offset = (uint32_t)loc;
        [childPackage appendBytes:&offset length:4];
        [childPackage appendBytes:&contentLength length:4];
        
        crc = crc32(0xffffffff, (Byte *)subData.bytes, (uint32_t)subData.length);
        [childPackage appendBytes:&crc length:4];
        [childPackage appendData:subData];
        
        MTFirmwareSlice *slice = [[MTFirmwareSlice alloc] init];
        slice.offset = offset;
        slice.data = childPackage;
        [result addObject:slice];
        
        loc += contentLength;
        pack_serial++;
    }
    return result;
}

//通用指令
+ (NSData *)commonGetCmd:(uint16_t)key {
    
    NSMutableData *result = [[NSMutableData alloc] init];
    [result appendBytes:"\x1B\x1C\x26\x20\x56\x32\x20\x67\x65\x74\x6B\x65\x79\x0D\x0A" length:15];
    [result appendBytes:"\x01" length:1];
    [result appendBytes:&key length:2];
    Byte size = valSizeForCommonCmd(key);
    [result appendBytes:&size length:1];
    return result;
}

+ (NSData *)commonSetCmd:(uint16_t)key val:(NSData *)val {
    
    NSMutableData *result = [[NSMutableData alloc] init];
    [result appendBytes:"\x1b\x1c\x26\x20\x56\x32\x20\x73\x65\x74\x6B\x65\x79\x0D\x0A" length:15];
    [result appendBytes:"\x01" length:1];
    [result appendBytes:&key length:2];
    Byte size = valSizeForCommonCmd(key);
    [result appendBytes:&size length:1];
    [result appendData:val];
    return result;
}

@end

//打印机固件升级需要
static const uint32_t crc32tab[] = {
    0x00000000L, 0x77073096L, 0xee0e612cL, 0x990951baL,
    0x076dc419L, 0x706af48fL, 0xe963a535L, 0x9e6495a3L,
    0x0edb8832L, 0x79dcb8a4L, 0xe0d5e91eL, 0x97d2d988L,
    0x09b64c2bL, 0x7eb17cbdL, 0xe7b82d07L, 0x90bf1d91L,
    0x1db71064L, 0x6ab020f2L, 0xf3b97148L, 0x84be41deL,
    0x1adad47dL, 0x6ddde4ebL, 0xf4d4b551L, 0x83d385c7L,
    0x136c9856L, 0x646ba8c0L, 0xfd62f97aL, 0x8a65c9ecL,
    0x14015c4fL, 0x63066cd9L, 0xfa0f3d63L, 0x8d080df5L,
    0x3b6e20c8L, 0x4c69105eL, 0xd56041e4L, 0xa2677172L,
    0x3c03e4d1L, 0x4b04d447L, 0xd20d85fdL, 0xa50ab56bL,
    0x35b5a8faL, 0x42b2986cL, 0xdbbbc9d6L, 0xacbcf940L,
    0x32d86ce3L, 0x45df5c75L, 0xdcd60dcfL, 0xabd13d59L,
    0x26d930acL, 0x51de003aL, 0xc8d75180L, 0xbfd06116L,
    0x21b4f4b5L, 0x56b3c423L, 0xcfba9599L, 0xb8bda50fL,
    0x2802b89eL, 0x5f058808L, 0xc60cd9b2L, 0xb10be924L,
    0x2f6f7c87L, 0x58684c11L, 0xc1611dabL, 0xb6662d3dL,
    0x76dc4190L, 0x01db7106L, 0x98d220bcL, 0xefd5102aL,
    0x71b18589L, 0x06b6b51fL, 0x9fbfe4a5L, 0xe8b8d433L,
    0x7807c9a2L, 0x0f00f934L, 0x9609a88eL, 0xe10e9818L,
    0x7f6a0dbbL, 0x086d3d2dL, 0x91646c97L, 0xe6635c01L,
    0x6b6b51f4L, 0x1c6c6162L, 0x856530d8L, 0xf262004eL,
    0x6c0695edL, 0x1b01a57bL, 0x8208f4c1L, 0xf50fc457L,
    0x65b0d9c6L, 0x12b7e950L, 0x8bbeb8eaL, 0xfcb9887cL,
    0x62dd1ddfL, 0x15da2d49L, 0x8cd37cf3L, 0xfbd44c65L,
    0x4db26158L, 0x3ab551ceL, 0xa3bc0074L, 0xd4bb30e2L,
    0x4adfa541L, 0x3dd895d7L, 0xa4d1c46dL, 0xd3d6f4fbL,
    0x4369e96aL, 0x346ed9fcL, 0xad678846L, 0xda60b8d0L,
    0x44042d73L, 0x33031de5L, 0xaa0a4c5fL, 0xdd0d7cc9L,
    0x5005713cL, 0x270241aaL, 0xbe0b1010L, 0xc90c2086L,
    0x5768b525L, 0x206f85b3L, 0xb966d409L, 0xce61e49fL,
    0x5edef90eL, 0x29d9c998L, 0xb0d09822L, 0xc7d7a8b4L,
    0x59b33d17L, 0x2eb40d81L, 0xb7bd5c3bL, 0xc0ba6cadL,
    0xedb88320L, 0x9abfb3b6L, 0x03b6e20cL, 0x74b1d29aL,
    0xead54739L, 0x9dd277afL, 0x04db2615L, 0x73dc1683L,
    0xe3630b12L, 0x94643b84L, 0x0d6d6a3eL, 0x7a6a5aa8L,
    0xe40ecf0bL, 0x9309ff9dL, 0x0a00ae27L, 0x7d079eb1L,
    0xf00f9344L, 0x8708a3d2L, 0x1e01f268L, 0x6906c2feL,
    0xf762575dL, 0x806567cbL, 0x196c3671L, 0x6e6b06e7L,
    0xfed41b76L, 0x89d32be0L, 0x10da7a5aL, 0x67dd4accL,
    0xf9b9df6fL, 0x8ebeeff9L, 0x17b7be43L, 0x60b08ed5L,
    0xd6d6a3e8L, 0xa1d1937eL, 0x38d8c2c4L, 0x4fdff252L,
    0xd1bb67f1L, 0xa6bc5767L, 0x3fb506ddL, 0x48b2364bL,
    0xd80d2bdaL, 0xaf0a1b4cL, 0x36034af6L, 0x41047a60L,
    0xdf60efc3L, 0xa867df55L, 0x316e8eefL, 0x4669be79L,
    0xcb61b38cL, 0xbc66831aL, 0x256fd2a0L, 0x5268e236L,
    0xcc0c7795L, 0xbb0b4703L, 0x220216b9L, 0x5505262fL,
    0xc5ba3bbeL, 0xb2bd0b28L, 0x2bb45a92L, 0x5cb36a04L,
    0xc2d7ffa7L, 0xb5d0cf31L, 0x2cd99e8bL, 0x5bdeae1dL,
    0x9b64c2b0L, 0xec63f226L, 0x756aa39cL, 0x026d930aL,
    0x9c0906a9L, 0xeb0e363fL, 0x72076785L, 0x05005713L,
    0x95bf4a82L, 0xe2b87a14L, 0x7bb12baeL, 0x0cb61b38L,
    0x92d28e9bL, 0xe5d5be0dL, 0x7cdcefb7L, 0x0bdbdf21L,
    0x86d3d2d4L, 0xf1d4e242L, 0x68ddb3f8L, 0x1fda836eL,
    0x81be16cdL, 0xf6b9265bL, 0x6fb077e1L, 0x18b74777L,
    0x88085ae6L, 0xff0f6a70L, 0x66063bcaL, 0x11010b5cL,
    0x8f659effL, 0xf862ae69L, 0x616bffd3L, 0x166ccf45L,
    0xa00ae278L, 0xd70dd2eeL, 0x4e048354L, 0x3903b3c2L,
    0xa7672661L, 0xd06016f7L, 0x4969474dL, 0x3e6e77dbL,
    0xaed16a4aL, 0xd9d65adcL, 0x40df0b66L, 0x37d83bf0L,
    0xa9bcae53L, 0xdebb9ec5L, 0x47b2cf7fL, 0x30b5ffe9L,
    0xbdbdf21cL, 0xcabac28aL, 0x53b39330L, 0x24b4a3a6L,
    0xbad03605L, 0xcdd70693L, 0x54de5729L, 0x23d967bfL,
    0xb3667a2eL, 0xc4614ab8L, 0x5d681b02L, 0x2a6f2b94L,
    0xb40bbe37L, 0xc30c8ea1L, 0x5a05df1bL, 0x2d02ef8dL
};

//打印机固件升级需要
uint32_t crc32(uint32_t crc,const uint8_t *buffer, uint32_t len) {
    uint32_t i;
    crc ^= 0xffffffffL;
    for (i = 0; i < len; i++) {
        crc = crc32tab[(crc ^ buffer[i]) & 0xff] ^ (crc >> 8);
    }
    crc ^= 0xffffffffL;
    return crc;
}
