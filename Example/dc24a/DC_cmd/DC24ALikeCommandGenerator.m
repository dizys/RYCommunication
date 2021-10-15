//
//  DC24ALikeCommandGenerator.default().m
//  HPrint
//
//  Created by ldc on 2020/9/11.
//  Copyright © 2020 Hanin. All rights reserved.
//

#import "DC24ALikeCommandGenerator.h"
#import "crc.h"

@interface DC24ALikeCommandGenerator ()

@property (nonatomic, assign) UInt16 packageId;

@property (nonatomic, assign) Byte version;

@property (nonatomic, assign) uint32_t dataPackageMaxLength;

@end

@implementation DC24ALikeCommandGenerator

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.packageId = 0;
        self.version = 1;
        self.dataPackageMaxLength = UINT32_MAX;
//        self.port = 0;
    }
    return self;
}

+ (instancetype)default {
    
    static dispatch_once_t onceToken;
    static DC24ALikeCommandGenerator *share;
    dispatch_once(&onceToken, ^{
        share = [[self alloc] init];
    });
    return share;
}

+ (instancetype)sharedCloud {
    
    static dispatch_once_t onceToken;
    static DC24ALikeCommandGenerator *share;
    dispatch_once(&onceToken, ^{
        share = [[self alloc] init];
    });
    return share;
}

- (NSData *)commandWithType:(DC24ACommandType)type data:(NSData *)content {
    NSMutableData * result = [[NSMutableData alloc] initWithBytes:"\x10\x11\x12\x13" length:4];
    UInt16 _type = type;
//    [result appendBytes:&_type length:4];
    
    NSMutableData * data = [[NSMutableData alloc] initWithBytes:&_type length:2];
//    [data appendBytes:"\x00" length:2];
    if (content != nil) {
        [data appendData:content];
    }
    uint32_t length = (uint32_t)data.length;
    [result appendBytes:&length length:4];
    
    UInt16 packageId = self.packageId;
    [result appendBytes:&packageId length:2];
    
    [result appendBytes:"\x00\x00" length:2];//预留Reserve
    
    [result appendData:data];
    
    uint32_t crc = ry_crc32(0xffffffffL, data.bytes, (uint32_t)data.length);
    [result appendBytes:&crc length:4];
    
    return result;
}

- (NSData *)cancelPrint {
    return nil;
//    return [self commandWithType:DC24ACommandTypeCancelPrint data:nil];
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

//- (NSData *)firmwarePackageUpdateCmd:(NSData *)data {
//
//    uint32_t length = (uint32_t)data.length;
//    NSData *content = [NSData dataWithBytes:&length length:4];
//    return [self commandWithType:DC24ACommandTypeFirmwarePackageUpdate data:content];
//}
//
//- (NSData *)firmwarePackageUpdateData:(NSData *)data {
//
//    return [self dataPackage:data command:DC24ACommandTypeFirmwarePackageUpdate taskId:0][0];
//}
//
//- (NSArray<NSData *> *)dataPackage:(NSData *)data command: (DC24ACommandType)code taskId:(Byte)ID {
//
//    NSMutableArray<NSData *> *packages = [[NSMutableArray alloc] init];
//    uint32_t total = (uint32_t)data.length;
//    uint32_t offset = 0;
//    while (offset < total) {
//        uint32_t contentLength = MIN(self.dataPackageMaxLength, total - offset);
//        NSMutableData *content = [[NSMutableData alloc] init];
//        UInt16 _code = (UInt16)(code >> 16);
//        [content appendBytes:&_code length:2];
//        [content appendBytes:&ID length:1];
//        [content appendBytes:"\x00" length:1];
//        [content appendBytes:&offset length:4];
//        [content appendBytes:&contentLength length:4];
//        [content appendData:[data subdataWithRange:NSMakeRange(offset, contentLength)]];
////        NSData *package = [self packageNeedResponse:DC24APackageTypeData data:content];
////        [packages addObject:package];
//        offset += contentLength;
//    }
//    return packages;
//}
//
//
//- (NSData *)packageNeedResponse:(DC24APackageType)type data:(NSData *)data {
//
//    return [self package:type control:self.control data:data];
//}
//
//- (NSData *)package:(DC24APackageType)type control:(DC24APackageControl)control data:(NSData *)data {
//
//    NSMutableData *result = [NSMutableData dataWithBytes:"\x1b\x1a" length:2];
//    Byte version = self.version;
//    [result appendBytes:&version length:1];
//    Byte packageId = self.packageId;
//    [result appendBytes:&packageId length:1];
//    [result appendBytes:&type length:1];
//    [result appendBytes:&control length:1];
//    Byte port = self.port;
//    [result appendBytes:&port length:1];
//    [result appendBytes:"\x00\x00\x00" length:3];
//    uint32_t length = (uint32_t)data.length;
//    [result appendBytes:&length length:4];
//    [result appendData:data];
//    Byte *temp = (Byte *)result.bytes;
//    temp += 2;
//    uint32_t crc = ry_crc32(0xffffffff, temp, length + 12);
//    [result appendBytes:&crc length:4];
//
//    if (self.packageId == 0xff) {
//        self.packageId = 0;
//    }else {
//        self.packageId++;
//    }
//    return result;
//}

@end
