//
//  FT800LikeCommandGenerator.default().m
//  HPrint
//
//  Created by ldc on 2020/9/11.
//  Copyright © 2020 Hanin. All rights reserved.
//

#import "FT800LikeCommandGenerator.h"
#import "crc.h"

Byte FT800GetValueSize(UInt16 type) {
    
    switch (type) {
        case 1:
        case 2:
        case 3:
        case 4:
        case 5:
            return 32;
        case 0x190:
            return 4;
        case 0xcb:
            return 1;
        default:
            return 32;
    }
}

@interface FT800LikeCommandGenerator ()

@property (nonatomic, assign) Byte packetId;

@property (nonatomic, assign) Byte version;

@property (nonatomic, assign) FT800PackageControl control;

@property (nonatomic, assign) uint32_t dataPackageMaxLength;

@end

@implementation FT800LikeCommandGenerator

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.packetId = 0;
        self.version = 1;
        self.control = 0;
        self.dataPackageMaxLength = UINT32_MAX;
        self.port = 0;
    }
    return self;
}

+ (instancetype)default {
    
    static dispatch_once_t onceToken;
    static FT800LikeCommandGenerator *share;
    dispatch_once(&onceToken, ^{
        share = [[self alloc] init];
    });
    return share;
}

+ (instancetype)sharedCloud {
    
    static dispatch_once_t onceToken;
    static FT800LikeCommandGenerator *share;
    dispatch_once(&onceToken, ^{
        share = [[self alloc] init];
    });
    return share;
}

- (NSData *)handshake:(BOOL)autoResponse {
    
    Byte content[4];
    content[0] = autoResponse ? 1 : 0;
    return [self packageNeedResponse:FT800PackageTypeHandshake data:[NSData dataWithBytes:content length:4]];
}

- (NSData *)configureStaWiFi:(NSData *)ssid password:(NSData *)password security:(FT800WiFiSecurity)security {
    
    NSMutableData *content = [[NSMutableData alloc] init];
    Byte length = (Byte)ssid.length;
    [content appendBytes:&length length:1];
    [content appendData:ssid];
    length = (Byte)password.length;
    [content appendBytes:&length length:1];
    [content appendData:password];
    [content appendBytes:&security length:1];
    return [self commandWithType:FT800CommandTypeConfigureStaWiFi data:content];
}

- (NSData *)commandWithType:(FT800CommandType)type data:(NSData *)content {
    
    UInt32 _type = type;
    UInt16 code = (UInt16)(_type >> 16);
    UInt16 subtype = (UInt16)_type;
    NSMutableData *data = [[NSMutableData alloc] init];
    switch (code) {
        case 3:
        case 4:
        case 0xa:
            [data appendBytes:&subtype length:2];
            if (data) {
                [data appendData:content];
            }
            return [self cmdPackage:code data:data];
        case 1:
        case 2:
            [data appendBytes:"\x01" length:1];
            [data appendBytes:&subtype length:2];
            Byte size = FT800GetValueSize(subtype);
            [data appendBytes:&size length:1];
            if (data) {
                [data appendData:content];
            }
            return [self cmdPackage:code data:data];
        default:
            [data appendData:content];
            return [self cmdPackage:code data:data];
    }
}

- (NSData *)imagePrintCmd:(NSData *)bitmap height:(NSInteger)height options:(FT800BitmapPrintOptions)options copies:(Byte)copies taskIndex:(Byte)index taskCount:(Byte)count taskId:(Byte)ID {
    
    NSMutableData *bitmapCmd = [[NSMutableData alloc] init];
    [bitmapCmd appendBytes:&index length:1];
    [bitmapCmd appendBytes:&count length:1];
    uint16_t width = bitmap.length/height;
    [bitmapCmd appendBytes:&width length:2];
    uint16_t h = height;
    [bitmapCmd appendBytes:&h length:2];
    [bitmapCmd appendBytes:&options length:1];
    [bitmapCmd appendBytes:&copies length:1];
    [bitmapCmd appendBytes:&ID length:1];
    //预留
    [bitmapCmd appendBytes:"\x00\x00\x00" length:3];
    return [self commandWithType:FT800CommandTypeBlackAndWhitePrint data:bitmapCmd];
}

- (NSData *)imagePrintData:(NSData *)bitmap taskId:(Byte)ID {
    
    return [self dataPackage:bitmap command:FT800CommandTypeBlackAndWhitePrint taskId:ID][0];
}

- (NSData *)wifiUpdateCmd:(NSData *)data {
    
    uint32_t length = (uint32_t)data.length;
    NSData *content = [NSData dataWithBytes:&length length:4];
    return [self commandWithType:FT800CommandTypeWifiFirmwareUpdate data:content];
}

- (NSData *)wifiUpdateData:(NSData *)data {
    
    return [self dataPackage:data command:FT800CommandTypeWifiFirmwareUpdate taskId:0][0];
}

- (NSData *)imagePrint:(NSData *)bitmap height:(NSInteger)height  options:(FT800BitmapPrintOptions)options copies:(Byte)copies taskIndex:(Byte)index taskCount:(Byte)count taskId:(Byte)ID {
    
    NSMutableData *data = [[NSMutableData alloc] init];
    
    NSMutableData *bitmapCmd = [[NSMutableData alloc] init];
    [bitmapCmd appendBytes:&index length:1];
    [bitmapCmd appendBytes:&count length:1];
    uint16_t width = bitmap.length/height;
    [bitmapCmd appendBytes:&width length:2];
    uint16_t h = height;
    [bitmapCmd appendBytes:&h length:2];
    [bitmapCmd appendBytes:&options length:1];
    [bitmapCmd appendBytes:&copies length:1];
    [bitmapCmd appendBytes:&ID length:1];
    [bitmapCmd appendBytes:"\x00\x00\x00" length:3];
    
    [data appendData:[self commandWithType:FT800CommandTypeBlackAndWhitePrint data:bitmapCmd]];
    [data appendData:[self dataPackage:bitmap command:FT800CommandTypeBlackAndWhitePrint taskId:ID][0]];
    return data;
}

- (NSData *)cancelPrint {
    
    return [self commandWithType:FT800CommandTypeCancelPrint data:nil];
}

- (NSData *)firmwareUpdate:(NSData *)data {
    
    Byte head[17] = {0x1b, 0x1c, 0x26, 0x20, 0x56, 0x31, 0x20, 0x64, 0x6f, 0x20, 0x22, 0x6f, 0x74, 0x61, 0x22, 0x0d, 0x0a};
    uint32_t crc;
    
    NSMutableData *content = [NSMutableData data];
    [content appendBytes:&head length:sizeof(head)];
    uint32_t offset = 0;
    [content appendBytes:&offset length:4];
    uint32_t contentLength = (uint32_t)data.length;
    [content appendBytes:&contentLength length:4];
    
    crc = ry_crc32(0xffffffff, (Byte *)data.bytes, contentLength);
    [content appendBytes:&crc length:4];
    [content appendData:data];
    return content;
}

- (NSData *)tianMaoVolume:(FT800TianMaoVolumeType)type volume:(Byte)volume {
    
    NSMutableData *content = [NSMutableData dataWithBytes:&type length:1];
    [content appendBytes:&volume length:1];
    return [self commandWithType:FT800CommandTypeTianMaoVolume data:content];
}

- (NSData *)firmwarePackageUpdateCmd:(NSData *)data {
    
    uint32_t length = (uint32_t)data.length;
    NSData *content = [NSData dataWithBytes:&length length:4];
    return [self commandWithType:FT800CommandTypeFirmwarePackageUpdate data:content];
}

- (NSData *)firmwarePackageUpdateData:(NSData *)data {
    
    return [self dataPackage:data command:FT800CommandTypeFirmwarePackageUpdate taskId:0][0];
}

- (NSArray<NSData *> *)dataPackage:(NSData *)data command: (FT800CommandType)code taskId:(Byte)ID {
    
    NSMutableArray<NSData *> *packages = [[NSMutableArray alloc] init];
    uint32_t total = (uint32_t)data.length;
    uint32_t offset = 0;
    while (offset < total) {
        uint32_t contentLength = MIN(self.dataPackageMaxLength, total - offset);
        NSMutableData *content = [[NSMutableData alloc] init];
        UInt16 _code = (UInt16)(code >> 16);
        [content appendBytes:&_code length:2];
        [content appendBytes:&ID length:1];
        [content appendBytes:"\x00" length:1];
        [content appendBytes:&offset length:4];
        [content appendBytes:&contentLength length:4];
        [content appendData:[data subdataWithRange:NSMakeRange(offset, contentLength)]];
        NSData *package = [self packageNeedResponse:FT800PackageTypeData data:content];
        [packages addObject:package];
        offset += contentLength;
    }
    return packages;
}

- (NSData *)cmdPackage:(UInt16)code data:(NSData *)data {
    
    NSMutableData *content = [[NSMutableData alloc] init];
    [content appendBytes:&code length:2];
    [content appendData:data];
    return [self packageNeedResponse:FT800PackageTypeCommand data:content];
}

- (NSData *)packageNeedResponse:(FT800PackageType)type data:(NSData *)data {
    
    return [self package:type control:self.control data:data];
}

- (NSData *)package:(FT800PackageType)type control:(FT800PackageControl)control data:(NSData *)data {
    
    NSMutableData *result = [NSMutableData dataWithBytes:"\x1b\x1a" length:2];
    Byte version = self.version;
    [result appendBytes:&version length:1];
    Byte packetId = self.packetId;
    [result appendBytes:&packetId length:1];
    [result appendBytes:&type length:1];
    [result appendBytes:&control length:1];
    Byte port = self.port;
    [result appendBytes:&port length:1];
    [result appendBytes:"\x00\x00\x00" length:3];
    uint32_t length = (uint32_t)data.length;
    [result appendBytes:&length length:4];
    [result appendData:data];
    Byte *temp = (Byte *)result.bytes;
    temp += 2;
    uint32_t crc = ry_crc32(0xffffffff, temp, length + 12);
    [result appendBytes:&crc length:4];
    
    if (self.packetId == 0xff) {
        self.packetId = 0;
    }else {
        self.packetId++;
    }
    return result;
}

@end
