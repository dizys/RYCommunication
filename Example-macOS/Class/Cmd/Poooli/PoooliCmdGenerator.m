//
//  PoooliCmdGenerator.m
//  Bluetooth
//
//  Created by ldc on 2019/11/29.
//  Copyright © 2019 Xiamen Hanin. All rights reserved.
//

#import "PoooliCmdGenerator.h"
#include "compress.h"

@implementation PoooliCmdGenerator

+ (NSData *)setDensity:(Byte)density {
    
    Byte buffer[6] = {0x1d, 0x73, 0x65, 0x74, 0x63, density};
    return [NSData dataWithBytes:buffer length:6];
}

+ (NSData *)setStandbyTime:(UInt16)time {
    
    Byte buffer[7] = {0x1d, 0x73, 0x65, 0x74, 0x74, 0 , 0};
    UInt16 *temp = (UInt16 *)(buffer + 5);
    temp[0] = time;
    return [NSData dataWithBytes:buffer length:7];
}

+ (NSData *)printBlackAndWhiteImage:(CGImageRef)cgImage {
    
    // 384 432 640 648 864 1248
    int width = (int)CGImageGetWidth(cgImage);
    if (width != 384 && width != 432 && width != 640 && width != 648 && width != 864 && width != 1248) {
        NSLog(@"%@ cgImage invalid parameter, 384 432 640 648 864 1248 width is expected", NSStringFromSelector(_cmd));
        return nil;
    }
    uint16_t height = (int)CGImageGetHeight(cgImage);
    Byte *bytes = (Byte *)calloc(width*height, 1);
    CGContextRef ctx = CGBitmapContextCreate(bytes, width, height, 8, width, CGColorSpaceCreateDeviceGray(), kCGImageAlphaNone);
    CGContextDrawImage(ctx, CGRectMake(0, 0, width, height), cgImage);
    CGContextRelease(ctx);
    Byte threshold = 127;
    uint16_t bitmapByteWidth = (width + 7)/8;
    int totalBitmapByte = bitmapByteWidth*height;
    Byte *result = calloc(totalBitmapByte, 1);
    for (int j = 0; j < height; j++) {
        for (int i = 0; i < width; i++) {
            if (bytes[width*j+i] < threshold) {
                result[bitmapByteWidth*j + i/8] |= 1 << (7-i%8);
            }
        }
    }
    NSData *bitmap = [NSData dataWithBytes:result length:totalBitmapByte];
    NSData *printedData = [self printBitmap:bitmap height:height];
    free(bytes);
    free(result);
    return printedData;
}

+ (NSData *)printBitmap:(NSData *)bitmap height:(NSUInteger)height {
    
    if (bitmap.length%height!=0) {
        NSLog(@"%@ parameter error, bitmap.length%%height must be zero", NSStringFromSelector(_cmd));
        return nil;
    }
    int width = (int)bitmap.length/height;
    if (width != 48 && width != 54 && width != 80 && width != 81 && width != 108 && width != 156) {
        NSLog(@"%@ bitmap width error, 48 54 80 81 108 156 is expected", NSStringFromSelector(_cmd));
        return nil;
    }
    NSMutableData *mData = [NSMutableData new];
    Byte *result = (Byte *)bitmap.bytes;
    //由宽度确定子包数据最大的位图行数
    NSUInteger maxPacketCount = (width > 48 ? 16 : 32)*width;
    unsigned char *output = calloc(maxPacketCount*2, 1);
    NSUInteger offset = 0;
    while (offset < bitmap.length) {
        NSUInteger packetContentByte;
        if (offset + maxPacketCount > bitmap.length) {
            packetContentByte = bitmap.length - offset;
        }else {
            packetContentByte = maxPacketCount;
        }
        uint16_t packetHeight = packetContentByte/width;
        [mData appendBytes:"\x1d\x76\x30\x30" length:4];
        Byte *temp = result + offset;
        uint32_t compressedLength = (uint32_t)lzo_compress(temp, (int)packetContentByte, output);
        [mData appendBytes:&width length:2];
        [mData appendBytes:&packetHeight length:2];
        [mData appendBytes:&compressedLength length:4];
        [mData appendBytes:output length:compressedLength];
        offset += packetContentByte;
    }
    free(output);
    return mData;
}

+ (NSData *)requestPrinterInfo {
    
    return [NSData dataWithBytes:"\x1b\x12\x64" length:3];
}

+ (NSData *)requestPrinterStatus {
    
    return [NSData dataWithBytes:"\x1b\x12\x73" length:3];
}

+ (NSData *)feedPaper:(uint16_t)lineCount {
    
    NSMutableData *data = [NSMutableData dataWithBytes:"\x1b\x1b\x01" length:3];
    [data appendBytes:&lineCount length:2];
    return data;
}

+ (NSData *)printConfigPage {
    
    return [NSData dataWithBytes:"\x1b\x1b\x00" length:3];
}

+ (NSData *)setPaperType:(PoooliPaperType)type {
    
    NSMutableData *data = [NSMutableData dataWithBytes:"\x1d\x73\x65\x74\x70" length:5];
    Byte temp = type;
    [data appendBytes:&temp length:1];
    return data;
}

+ (NSData *)feedPaperAndLocate:(uint16_t)lineCount {
    
    NSMutableData *data = [NSMutableData dataWithBytes:"\x1d\x66" length:2];
    [data appendBytes:&lineCount length:2];
    return data;
}

@end

@implementation NSData (ZeroIndex)

- (NSInteger)firstIndexOf:(Byte)value {
    
    Byte *pointer = (Byte *)self.bytes;
    for (int i = 0; i < self.length; i ++) {
        if (pointer[i] == value) {
            return i;
        }
    }
    return -1;
}

@end

@implementation PoooliPrinterInfo

- (instancetype)initWithData:(NSData *)data {
    
    if (data.length < 143) {
        return nil;
    }
    self = [super init];
    if (self) {
        NSData *tempData;
        NSInteger index;
        Byte *bytes;
        
        tempData = [data subdataWithRange:NSMakeRange(0, 32)];
        index = [tempData firstIndexOf:0];
        if (index > 0) {
            tempData = [tempData subdataWithRange:NSMakeRange(0, index)];
        }
        self.name = [[NSString alloc] initWithData:tempData encoding:NSUTF8StringEncoding];
        
        tempData = [data subdataWithRange:NSMakeRange(32, 24)];
        index = [tempData firstIndexOf:0];
        if (index > 0) {
            tempData = [tempData subdataWithRange:NSMakeRange(0, index)];
        }
        self.mode = [[NSString alloc] initWithData:tempData encoding:NSUTF8StringEncoding];
        
        tempData = [data subdataWithRange:NSMakeRange(56, 32)];
        index = [tempData firstIndexOf:0];
        if (index > 0) {
            tempData = [tempData subdataWithRange:NSMakeRange(0, index)];
        }
        self.sn = [[NSString alloc] initWithData:tempData encoding:NSUTF8StringEncoding];
        
        tempData = [data subdataWithRange:NSMakeRange(88, 3)];
        bytes = (Byte *)tempData.bytes;
        self.firmwareVersion = [@[
            [NSString stringWithFormat:@"%i", bytes[0]],
            [NSString stringWithFormat:@"%i", bytes[1]],
            [NSString stringWithFormat:@"%i", bytes[2]]
        ] componentsJoinedByString:@"."];
        
        tempData = [data subdataWithRange:NSMakeRange(91, 3)];
        bytes = (Byte *)tempData.bytes;
        self.hardwareVersion = [@[
            [NSString stringWithFormat:@"%i", bytes[0]],
            [NSString stringWithFormat:@"%i", bytes[1]],
            [NSString stringWithFormat:@"%i", bytes[2]]
        ] componentsJoinedByString:@"."];
        
        tempData = [data subdataWithRange:NSMakeRange(94, 18)];
        index = [tempData firstIndexOf:0];
        if (index > 0) {
            tempData = [tempData subdataWithRange:NSMakeRange(0, index)];
        }
        self.bluetoothName = [[NSString alloc] initWithData:tempData encoding:NSUTF8StringEncoding];
        
        tempData = [data subdataWithRange:NSMakeRange(112, 12)];
        index = [tempData firstIndexOf:0];
        if (index > 0) {
            tempData = [tempData subdataWithRange:NSMakeRange(0, index)];
        }
        self.bluetoothFirwareVersion = [[NSString alloc] initWithData:tempData encoding:NSUTF8StringEncoding];
        
        tempData = [data subdataWithRange:NSMakeRange(124, 12)];
        index = [tempData firstIndexOf:0];
        if (index > 0) {
            tempData = [tempData subdataWithRange:NSMakeRange(0, index)];
        }
        self.bluetoothMac = [[NSString alloc] initWithData:tempData encoding:NSUTF8StringEncoding];
        
        tempData = [data subdataWithRange:NSMakeRange(136, 4)];
        self.bluetoothPIN = [[NSString alloc] initWithData:tempData encoding:NSUTF8StringEncoding];
    }
    return self;
}

- (NSString *)description {
    
    return [NSString stringWithFormat:@"设备名: %@\n设备模型: %@\nSN: %@\n固件版本: %@\n硬件版本: %@\n蓝牙名称: %@\n蓝牙固件版本: %@\n蓝牙MAC: %@\n蓝牙PIN: %@\n", self.name, self.mode, self.sn, self.firmwareVersion, self.hardwareVersion, self.bluetoothName, self.bluetoothFirwareVersion, self.bluetoothMac, self.bluetoothPIN];
}

@end


@implementation PoooliPrinterStatusInfo

- (instancetype _Nullable)initWithData:(NSData *)data {
    
    if (data.length < 17) {
        return nil;
    }
    self = [super init];
    if (self) {
        Byte *pointer = (Byte *)data.bytes;
        self.status = (PoooliPrinterStatus)*(UInt16 *)pointer;
        pointer+=2;
        self.isIdle = *pointer == 1;
        pointer++;
        self.power = *pointer;
        pointer++;
        self.standbyTime = *(UInt16 *)pointer;
        pointer+=2;
        self.density = *pointer;
        pointer++;
        self.paperType = (PoooliPaperType)*pointer;
        pointer+=5;
        self.tphTemperature = *(UInt16 *)pointer;
    }
    return self;
}

@end
