//
//  DC24ALikeCommandGenerator.default().h
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
 *  命令类型
 *
 *  \~english
 *
 *  Command Type
 *
 */
typedef NS_ENUM(UInt16, DC24ACommandType) {
    
    DC24ACommandTypeGetFirmwareVersion = 0x0001,///< \~chinese 固件版本 \~english firmware version
    
    DC24ACommandTypeGetPrinterName = 0x0002,///< \~chinese 打印机名称 \~english printer name
    
    DC24ACommandTypeGetSn = 0x0003,///< \~chinese 序列号 \~english Serial Number
    
    DC24ACommandTypePrinterMileage = 0x0004,///< \~chinese打印里程
    
    DC24ACommandTypeGetStatus = 0x0005,///< \~chinese 打印机状态 \~english printer status data[4]为第一顺位状态，Bit0~Bit7 每一个位代表一个状态，状态不够时扩展data[5]，附表1：状态说明表 |
    
    DC24ACommandTypeDownModel = 0x0006,///< \~chinese 下载模板
    
    DC24ACommandTypeUpdateTime = 0x0007,///< \~chinese 更新时间 时间格式（低字节在前，高字节在后）：年+月+日+时+分+秒 |
    
    DC24ACommandTypeGetDensity = 0x0008,///< \~chinese 浓度(0~2) \~english density(0～2)
    
    DC24ACommandTypeSetDensity = 0x0009,///< \~chinese 浓度(0~2) \~english density(0～2)
    
    
    
    DC24ACommandTypeAutoResponse = 0x000a,///< \~chinese 主动回传
    
    DC24ACommandTypeHandshake = 0x000b,///< \~chinese 握手校验
    
    DC24ACommandTypeHeadTemperature = 0x000c,///< \~chinese 获取头片温度
    
    DC24ACommandTypePrintModel = 0x000d,///< \~chinese 打印模板
    
    DC24ACommandTypeControlHeadPressingDown = 0x000e,///< \~chinese 控制头片抬起下压       | data：00（抬起），01（下压）
    
    DC24ACommandTypeGetCarbonBeltAllowance = 0x000f,///< \~chinese 碳带余量
    
    DC24ACommandTypeGetVersionCode = 0x0010,///< \~chinese 获取VersionCode
    
    DC24ACommandTypeSetPotentiometerGearWhenPrinting = 0x0011,///< \~chinese 设置打印时的电位器档位 | data：0x00~0x3F
    
    DC24ACommandTypeGetPotentiometerGearWhenPrinting = 0x0012,///< \~chinese 获取打印时的电位器档位
    
    DC24ACommandTypeSetPositionPrintHeadBracket = 0x0013,///< \~chinese 设置打印头托架位置     | 范围 5mm~15mm, 距离mm*8后发送打印机，1字节
    
    DC24ACommandTypeGetPositionPrintHeadBracket = 0x0014,///< \~chinese 获取打印头托架位置
    
    DC24ACommandTypeSetPrintLocation = 0x0015,///< \~chinese 设置打印位置           | 0dot ~ 104dot
    
    DC24ACommandTypeGetPrintLocation = 0x0016,///< \~chinese 获取打印位置
    
    DC24ACommandTypeSetPrintDirection = 0x0017,///< \~chinese 设置打印方向           | 正（0） 反（1）
    
    DC24ACommandTypeGetPrintDirection = 0x0018,///< \~chinese 获取打印方向
    
    DC24ACommandTypeSetPrintDelay = 0x0019,///< \~chinese 设置打印延时
    
    DC24ACommandTypeGetPrintDelay = 0x001a,///< \~chinese 获取打印延时
    
    DC24ACommandTypeSetHeadBracketFrets = 0x001b,///< \~chinese 头托架微动
    
    DC24ACommandTypeBatchPrintedNumber = 0x001c,///< \~chinese 本批印刷数 (开机从0开始累积 4字节)
    
    DC24ACommandTypeBatchPrintedTotalNumber = 0x001d,///< \~chinese 总印刷数(4字节)
    
    DC24ACommandTypePrintSpeed = 0x001e,///< \~chinese 印刷速率 (张/分钟  1字节 )
    
    DC24ACommandTypeBuzzerDetection = 0x001f,///< \~chinese 蜂鸣器检测   (0开启检测 1关闭检测)
    
    DC24ACommandTypeLedsDetection = 0x0020,///< \~chinese LED灯检测              | 0开启检测 1关闭检测
    
    DC24ACommandTypeCheckPrintHeadBracket = 0x0021,///< \~chinese 检测打印头托架
    
    DC24ACommandTypeGetPrinterInfo = 0x0022,///< \~chinese 获取打印机信息
    
    DC24ACommandTypeFirmwarePackageUpdate = 0x00ff,///< \~chinese 固件包更新 \~english firmware package update
};


Byte DC24AGetValueSize(UInt16 type);

/**
 *  \~chinese
 *
 *  DC24A系列机型指令组装类
 *
 *  \~english
 *
 *  Class for assembling DC24A series printer command.
 *
 */
@interface DC24ALikeCommandGenerator : NSObject

//@property (nonatomic, assign) Byte port;

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
//- (NSData *)handshake:(BOOL)autoResponse;

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
- (NSData *)commandWithType:(DC24ACommandType)type data:(NSData * _Nullable)content;

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
//- (NSData *)imagePrintCmd:(NSData *)bitmap height:(NSInteger)height options:(DC24ABitmapPrintOptions)options copies:(Byte)copies taskIndex:(Byte)index taskCount:(Byte)count taskId:(Byte)ID;

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
//- (NSData *)imagePrintData:(NSData *)bitmap taskId:(Byte)ID;

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
