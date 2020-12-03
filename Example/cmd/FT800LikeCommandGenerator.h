//
//  FT800LikeCommandGenerator.default().h
//  HPrint
//
//  Created by ldc on 2020/9/11.
//  Copyright © 2020 Hanin. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  \~chinese
 *
 *  包类型 
 *
 *  \~english
 *
 *  Package Type
 *
 */
typedef NS_ENUM(Byte, FT800PackageType) {
    
    FT800PackageTypeHandshake = 0,///< \~chinese 握手包 \~english handshake
    
    FT800PackageTypeCommand = 1,///< \~chinese 命令包 \~english command
    
    FT800PackageTypeData = 2,///< \~chinese 数据包 \~english data
    
    FT800PackageTypeAutoResponse = 3,///< \~chinese 主动回传包 \~english auto response
    
    FT800PackageTypeRepeater = 4,///< \~chinese 转发包 \~english repeater
};

typedef NS_OPTIONS(Byte, FT800PackageControl) {
    FT800PackageControlEmpty = 1 << 0,
};

/**
 *  \~chinese
 *
 *  命令类型
 *
 *  \~english
 *
 *  Command Type
 *
 */
typedef NS_ENUM(UInt32, FT800CommandType) {
    
    FT800CommandTypeGetSn = 0x10001,///< \~chinese 序列号 \~english Serial Number
    
    FT800CommandTypeGetManuName = 0x10003,///< \~chinese 制造商 \~english manufacturer name
    
    FT800CommandTypeGetPrinterName = 0x10004,///< \~chinese 打印机名称 \~english printer name
    
    FT800CommandTypeGetDensity = 0x100cb,///< \~chinese 浓度(0~3) \~english density(0～3)
    
    FT800CommandTypeGetShutdownTime = 0x10190,///< \~chinese 自动关机时间,单位秒 \~english auto shutdown time (second)
    
    FT800CommandTypeSetDensity = 0x200cb,///< \~chinese 浓度(0~3) \~english density(0～3)
    
    FT800CommandTypeSetShutdownTime = 0x20190,///< \~chinese 自动关机时间,单位秒 \~english auto shutdown time (second)
    
    FT800CommandTypeGetFirmwareVersion = 0x30001,///< \~chinese 固件版本 \~english firmware version
    
    FT800CommandTypeGetPower = 0x30002,///< \~chinese 电量 \~english power
    
    FT800CommandTypeGetStatus = 0x30003,///< \~chinese 打印机状态 \~english printer status
    
    FT800CommandTypeGetWiFiMode = 0x30005,///< \~chinese 获取Wi-Fi模式 \~english Get Wi-Fi mode
    
    FT800CommandTypeGetStaInfo = 0x30006,///< \~chinese STA网络信息 \~english STA info
    
    FT800CommandTypeGetPrinterModel = 0x30007,///< \~chinese 打印机模型 \~english printer model
    
    FT800CommandTypeGetBtName = 0x30008,///< \~chinese 蓝牙名称 \~english bluetooth name
    
    FT800CommandTypeGetWifiVersion = 0x30009,///< \~chinese Wi-Fi固件版本 \~english version of Wi-Fi firmware
    
    FT800CommandTypeSetWiFiMode = 0x40001,///< \~chinese 设置Wi-Fi模式 \~english Set Wi-Fi mode
    
    FT800CommandTypeBlackAndWhitePrint = 0x50000,///< \~chinese 黑白位图打印 \~english black-and-white bitmap print
    
    FT800CommandTypeCancelPrint = 0x60000,///< \~chinese 取消打印 \~english cancel print
    
    FT800CommandTypeReprint = 0x70000,///< \~chinese 重新打印 \~english reprint
    
    FT800CommandTypeConfigureStaWiFi = 0x80000,///< \~chinese 配置打印机STA热点信息 \~english configure STA hotspot info
    
    FT800CommandTypeWifiFirmwareUpdate = 0x90000,///< \~chinese Wi-Fi固件更新 \~english Wi-Fi firmware update
    
    FT800CommandTypeDoSaveConfig = 0xa0001,///< \~chinese do操作 \~english do
    
    FT800CommandTypeTianMaoVolume = 0xb0000,///< \~chinese 天猫音量 \~english tianmao volume
    
    FT800CommandTypeFirmwarePackageUpdate = 0xc0000,///< \~chinese 固件包更新 \~english firmware package update
};

typedef NS_ENUM(UInt8, FT800WiFiSecurity) {
    FT800WiFiSecurityOpen = 0,
    FT800WiFiSecurityWep = 1,
    FT800WiFiSecurityWpa2_psk = 2,
    FT800WiFiSecurityWpa_wpa2_psk = 3,
    FT800WiFiSecurityWpa_psk = 4,
    FT800WiFiSecurityWpa = 5,
    FT800WiFiSecurityWpa2 = 6,
    FT800WiFiSecuritySae = 7,
    FT800WiFiSecurityUnkown = 8,
};

/**
 *  \~chinese
 *
 *  天猫精灵音量操作
 *
 *  \~english
 *
 *  tianmao volume operation.
 *
 */
typedef NS_ENUM(Byte, FT800TianMaoVolumeType) {
    
    FT800TianMaoVolumeTypeSet = 0,///< \~chinese 设置 \~english set
    
    FT800TianMaoVolumeTypeIncrease = 1,///< \~chinese 增加 \~english increase
    
    FT800TianMaoVolumeTypeDecrease = 2,///< \~chinese 降低 \~english decrease
};

/**
 *  \~chinese
 *
 *  图片打印选项
 *
 *  \~english
 *
 *  bitmap print options
 *
 */
typedef NS_OPTIONS(Byte, FT800BitmapPrintOptions) {
    
    FT800BitmapPrintOptionsCut = 1 << 0,///< \~chinese 打印后切刀 \~english cut after print
    
    FT800BitmapPrintOptionsLocate = 1 << 1,///< \~chinese 打印后定位 \~english locate after print
};

Byte FT800GetValueSize(UInt16 type);

/**
 *  \~chinese
 *
 *  FT800系列机型指令组装类
 *
 *  \~english
 *
 *  Class for assembling FT800 series printer command.
 *
 */
@interface FT800LikeCommandGenerator : NSObject

@property (nonatomic, assign) Byte port;

+ (instancetype)default;

/**
 *  \~chinese
 *
 *  发送握手数据
 *
 *  @param autoResponse 是否需要打印机自动回传状态
 *
 *  \~english
 *
 *  send handshake data
 *
 *  @param autoResponse Whether respond status automatically
 *
 */
- (NSData *)handshake:(BOOL)autoResponse;

/**
 *  \~chinese
 *
 *  配置STA网络
 *
 *  @param ssid Wi-Fi名称，1～32字节
 *  @param password Wi-Fi密码，0～32字节
 *  @param security 加密方式
 *
 *  \~english
 *
 *  configure STA network
 *
 *  @param ssid name of hotspot,1～32bytes
 *  @param password password of hotspot,0～32bytes
 *  @param security FT800WiFiSecurity
 *
 */
- (NSData *)configureStaWiFi:(NSData *)ssid password:(NSData *)password security:(FT800WiFiSecurity)security;

/**
 *  \~chinese
 *
 *  命令类型指令
 *
 *  @param type 指令类型
 *  @param content 数据内容
 *
 *  \~english
 *
 *  Command Type Command
 *
 *  @param type command type
 *  @param content content
 *
 */
- (NSData *)commandWithType:(FT800CommandType)type data:(NSData * _Nullable)content;

/**
 *  \~chinese
 *
 *  图片打印命令
 *
 *  @param bitmap 位图数据
 *  @param height 位图高度
 *  @param options 打印选项
 *  @param copies 份数
 *  @param index 当前页数
 *  @param count 总页数
 *  @param ID 任务id
 *
 *  \~english
 *
 *  image print command
 *
 *  @param bitmap bitmap data
 *  @param height height of bitmap
 *  @param options print options
 *  @param copies copies
 *  @param index current page index
 *  @param count count of pages
 *  @param ID task id
 *
 */
- (NSData *)imagePrintCmd:(NSData *)bitmap height:(NSInteger)height options:(FT800BitmapPrintOptions)options copies:(Byte)copies taskIndex:(Byte)index taskCount:(Byte)count taskId:(Byte)ID;

/**
 *  \~chinese
 *
 *  图片打印数据
 *
 *  @param bitmap 位图数据
 *  @param ID 任务id
 *  
 *
 *  \~english
 *
 *  image print data
 *
 *  @param bitmap bitmap data
 *  @param ID task id
 *
 */
- (NSData *)imagePrintData:(NSData *)bitmap taskId:(Byte)ID;

/**
 *  \~chinese
 *
 *  取消打印任务
 *
 *  \~english
 *
 *  cancel print task
 *
 */
- (NSData *)cancelPrint;

@end

NS_ASSUME_NONNULL_END
