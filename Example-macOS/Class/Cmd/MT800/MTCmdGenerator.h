//
//  MTCmdGenerator.h
//  MTSDK
//
//  Created by ldc on 2020/4/13.
//  Copyright © 2020 Xiamen Hanin. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(uint16_t, MTCommonCmdKey) {
    MTCommonCmdKeyShutdownTime = 0x191,
    MTCommonCmdKeyPrintDensity = 0xcb,
    MTCommonCmdKeyPrinterName = 0x4,
};

typedef NS_ENUM(Byte, MTCarbonRibbonProperty) {
    MTCarbonRibbonPropertyUid = 0x75,
    MTCarbonRibbonPropertyPrinterModelAvailable = 0x70,
    MTCarbonRibbonPropertyWidth = 0x77,
    MTCarbonRibbonPropertyType = 0x74,
    MTCarbonRibbonPropertyVenderId = 0x6d,
    MTCarbonRibbonPropertyHeatFactor = 0x68,
};

Byte valSizeForCommonCmd(MTCommonCmdKey key);

@interface MTBitmapSlice : NSObject

@property (nonatomic, assign) uint16_t serial;

@property (nonatomic, strong) NSData *data;

@property (nonatomic, strong) NSTimer * _Nullable timer;

@end

@interface MTFirmwareSlice : NSObject

@property (nonatomic, assign) uint32_t offset;

@property (nonatomic, strong) NSData *data;

@property (nonatomic, strong) NSTimer * _Nullable timer;

@end

typedef NS_OPTIONS(UInt16, MTPrinterStatus) {
    MTPrinterStatusPaperAbsent = 1 << 0,///缺纸
    MTPrinterStatusHighTemperature = 1 << 1,///高温
    MTPrinterStatusLowTemperature = 1 << 2,///低温
    MTPrinterStatusLowVoltage = 1 << 3,///低电量
    MTPrinterStatusHeadOpened = 1 << 4,///开盖
    MTPrinterStatusCarbonRibbonEnd = 1 << 5,///碳带用尽
    MTPrinterStatusPaperSmashe = 1 << 6,///纸装歪
    MTPrinterStatusCarbonRibbonNotAuthorization = 1 << 7,///碳带未授权
    MTPrinterStatusBufferFull = 1 << 8,///缓存已满
    MTPrinterStatusNoMileage = 1 << 9,///里程不足
};

typedef NS_ENUM(Byte, MTPaperType) {
    MTPaperTypeThermal,///热敏纸
    MTPaperTypeA4,///A4纸
};

@interface MTPrinterInfo : NSObject

@property (nonatomic, assign) MTPrinterStatus status;

@property (nonatomic, assign) BOOL idle;

@property (nonatomic, assign) Byte electricQuantity;

@property (nonatomic, assign) uint32_t autoShutdownTime;

@property (nonatomic, assign) Byte printDensity;

@property (nonatomic, assign) MTPaperType paperType;

@property (nonatomic, assign) uint16_t tphTemperature;

- (instancetype)initWithData:(NSData *)data;

@end

@interface MTCmdGenerator : NSObject

+ (NSData *)requestRemainCarbonRibbonCount;

+ (NSData *)setPrinterDensity:(Byte)density;

+ (NSData *)clearPrinterBuffer;

/**
 获取打印机信息
 2个字节状态 1个字节空闲 1个字节电池百分比 4个字节自动关机时间 1个浓度 1个纸张类型(1:A4) 2个温度
 */
+ (NSData *)getPrinterStatusInfo;

/**
 获取碳带耗材品牌，字符串，以00结尾
 */
+ (NSData *)getRibbonConsumablesBrandInfo;

/**
 获取碳带剩余量，4个字节，int类型 单位mm
 */
+ (NSData *)getRibbonRemainCount;

/**
 获取打印机序列号，字符串，以00结尾
 */
+ (NSData *)getPrinterSerialNumber;

/**
 获取打印机固件版本，字符串，以00结尾
 */
+ (NSData *)getPrinterFirmwareVersion;

/**
 获取打印浓度
 */
+ (NSData *)getPrinterDensity;

/**
 获取关机时间
 */
+ (NSData *)getPrinterShutdownTime;

/**
 设置关机时间
 
 @param time 关机时间
 */
+ (NSData *)setPrinterShutdownTime:(uint32_t)time;

+ (NSData *)getLengthPrinted;

+ (NSData *)getPrinterName;

+ (NSData *)getCarbonInfo:(MTCarbonRibbonProperty)property;

+ (NSMutableArray<MTBitmapSlice *> *)sliceImageBitmap:(NSData *)data height:(uint16_t)height;

+ (NSMutableArray<MTFirmwareSlice *> *)sliceFirmware:(NSData *)data;

@end

NS_ASSUME_NONNULL_END
