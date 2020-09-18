//
//  PoooliCmdGenerator.h
//  Bluetooth
//
//  Created by ldc on 2019/11/29.
//  Copyright © 2019 Xiamen Hanin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_OPTIONS(UInt16, PoooliPrinterStatus) {
    PoooliPrinterStatusPaperAbsent = 1,
    PoooliPrinterStatusHighTemperature = 1<<1,
    PoooliPrinterStatusLowTemperature = 1<<2,
    PoooliPrinterStatusLowVoltage = 1<<3,
    PoooliPrinterStatusCoverOpened = 1<<4,
    PoooliPrinterStatusBatteryDamaged = 1<<5,
    PoooliPrinterStatusLocateFail = 1<<6,
};

typedef NS_ENUM(Byte, PoooliPaperType) {
    PoooliPaperTypeReceipt,
    PoooliPaperTypeLabel,
};

@interface PoooliCmdGenerator : NSObject
/*!
 *  \~chinese
 *
 *  设置打印机浓度 范围: 0x0~0xff
 *
 *  @note L3 只支持 55 75 95 三个值
 *
 *  @param density 浓度
 *
 *  \~english
 *
 *
 *
 */
+ (NSData *)setDensity:(Byte)density;

/*!
 *  \~chinese
 *
 *  设置打印机自动关机时间
 *
 *  @note USB模式下，设置后断开USB连接才能生效
 *
 *  @param time 关机时间 单位: 秒
 *
 *  \~english
 *
 *
 *
 */
+ (NSData *)setStandbyTime:(UInt16)time;

/*!
 *  \~chinese
 *
 *  打印黑白二值图片
 *
 *  @note 图片的像素宽度只能是确定的几种宽度 L1-> 384  L1 PRO-> 432 L2-> 640 L2 PRO-> 640 L3-> 648 864 1248
 *
 *  @param cgImage 图片
 *
 *  @return cgImage宽度不对时，返回nil
 *
 *  \~english
 *
 *
 *
 */
+ (NSData * _Nullable)printBlackAndWhiteImage:(CGImageRef)cgImage;

/*!
 *  \~chinese
 *
 *  位图打印
 *
 *  @param bitmap 位图
 *
 *  @param height 位图高度
 *
 *  @note 位图数据长度必须是高度的倍数，倍值为: L1-> 48  L1 PRO-> 54 L2-> 80 L2 PRO-> 80 L3-> 81 108 156
 *
 *  @return bitmap长度与height不匹配时，返回nil
 *
 *  \~english
 *
 *
 *
 */
+ (NSData * _Nullable)printBitmap:(NSData *)bitmap height:(NSUInteger)height;

/*!
 *  \~chinese
 *
 *  获取打印机设备信息
 *
 *  \~english
 *
 *
 *
 */
+ (NSData *)requestPrinterInfo;

/*!
 *  \~chinese
 *
 *  获取打印机状态信息
 *
 *  \~english
 *
 *
 *
 */
+ (NSData *)requestPrinterStatus;

/*!
 *  \~chinese
 *
 *  走纸
 *
 *  @param lineCount 走纸行数，一行0.125mm
 *
 *  \~english
 *
 *
 *
 */
+ (NSData *)feedPaper:(uint16_t)lineCount;

/*!
 *  \~chinese
 *
 *  打印自检页
 *
 *  \~english
 *
 *
 *
 */
+ (NSData *)printConfigPage;

/*!
 *  \~chinese
 *
 *  设置纸张类型
 *
 *  @param type 纸张类型
 *
 *  \~english
 *
 *
 *
 */
+ (NSData *)setPaperType:(PoooliPaperType)type;

/*!
 *  \~chinese
 *
 *  定位走纸
 *
 *  @param lineCount 走纸行数，一行0.125mm
 *
 *  @note 标签纸可用
 *
 *  \~english
 *
 *
 *
 */
+ (NSData *)feedPaperAndLocate:(uint16_t)lineCount;

@end

@interface PoooliPrinterInfo : NSObject

@property (nonatomic, copy) NSString *name;

@property (nonatomic, copy) NSString *mode;

@property (nonatomic, copy) NSString *sn;

@property (nonatomic, copy) NSString *firmwareVersion;

@property (nonatomic, copy) NSString *hardwareVersion;

@property (nonatomic, copy) NSString *bluetoothName;

@property (nonatomic, copy) NSString *bluetoothFirwareVersion;

@property (nonatomic, copy) NSString *bluetoothMac;

@property (nonatomic, copy) NSString *bluetoothPIN;

- (instancetype _Nullable)initWithData:(NSData *)data;

@end

@interface PoooliPrinterStatusInfo : NSObject

@property (nonatomic, assign) PoooliPrinterStatus status;

@property (nonatomic, assign) BOOL isIdle;

@property (nonatomic, assign) Byte power;

@property (nonatomic, assign) UInt16 standbyTime;

@property (nonatomic, assign) Byte density;

@property (nonatomic, assign) PoooliPaperType paperType;

@property (nonatomic, assign) UInt16 tphTemperature;

- (instancetype _Nullable)initWithData:(NSData *)data;

@end

NS_ASSUME_NONNULL_END
