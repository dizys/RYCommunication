//
//  FT800DataResolver.h
//  HPrint
//
//  Created by ldc on 2020/9/15.
//  Copyright © 2020 Hanin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "base.h"
#import "RYResolver.h"
#import "FT800LikeCommandGenerator.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  \~chinese
 *
 *  打印机状态1
 *
 *  \~english
 *
 *  Printer status 1
 *
 */
typedef NS_OPTIONS(Byte, FT800PrinterStatus1) {
    
    FT800PrinterStatus1Offline = 1 << 0,///< \~chinese 离线 \~english offline
    
    FT800PrinterStatus1PaperAbsent = 1 << 1,///< \~chinese 缺纸 \~english paper absent
    
    FT800PrinterStatus1CoverOpen = 1 << 2,///< \~chinese 开盖 \~english cover open
    
    FT800PrinterStatus1HighTemperature = 1 << 3,///< \~chinese 高温 \~english high temperature
    
    FT800PrinterStatus1PaperNotTakeOut = 1 << 4,///< \~chinese 纸张未取出 \~english paper not take out
    
    FT800PrinterStatus1PowerTooLow = 1 << 5,///< \~chinese 低电量 \~english power too low
    
    FT800PrinterStatus1CutterError = 1 << 6,///< \~chinese 切刀错误 \~english cutter error
    
    FT800PrinterStatus1LocationError = 1 << 7,///< \~chinese 定位错误 \~english location error
};

/**
 *  \~chinese
 *
 *  打印机状态2
 *
 *  \~english
 *
 *  Printer status 2
 *
 */
typedef NS_OPTIONS(Byte, FT800PrinterStatus2) {
    
    FT800PrinterStatus2BufferIsNotEmpty = 1 << 1,///< \~chinese 缓存非空 \~english buffer is not empty
    
    FT800PrinterStatus2IllegalRibbon = 1 << 2,///< \~chinese 非法碳带 \~english illegal ribbon
    
    FT800PrinterStatus2RibbonExhausted = 1 << 3,///< \~chinese 碳带用尽 \~english ribbon exhausted
    
    FT800PrinterStatus2Paused = 1 << 4,///< \~chinese 暂停 \~english paused
};

/**
 *  \~chinese
 *
 *  打印机状态3
 *
 *  \~english
 *
 *  Printer status 3
 *
 */
typedef NS_OPTIONS(Byte, FT800PrinterStatus3) {
    
    FT800PrinterStatus3Idle = 1 << 0,///< \~chinese 空闲 \~english idle
};

/**
 *  \~chinese
 *
 *  自动回传数据类型
 *
 *  \~english
 *
 *  Auto response data type
 *
 */
typedef NS_ENUM(Byte, FT800AutoResponseType) {
    
    FT800AutoResponseTypePrinterStatus = 0,///< \~chinese 打印机状态 \~english Printer status
    
    FT800AutoResponseTypeTaskCompleted = 1,///< \~chinese 任务完成 \~english task completed
    
    FT800AutoResponseTypeShutdown = 2,///< \~chinese 打印机关机 \~english shutdown
    
    FT800AutoResponseTypePrintRecord = 3,///< \~chinese 打印里程 \~english print record
};

/**
 *  \~chinese
 *
 *  数据包响应结果
 *
 *  \~english
 *
 *  Package response result
 *
 */
typedef NS_ENUM(Byte, FT800PackageResult) {
    
    FT800PackageResultOk = 0,///< \~chinese ok \~english ok
    
    FT800PackageResultFail,///< \~chinese 失败 \~english fail
    
    FT800PackageResultCrcError,///< \~chinese crc错误 \~english crc error
    
    FT800PackageResultFormatError,///< \~chinese 格式错误 \~english format error
    
    FT800PackageResultBusy,///< \~chinese 打印机正忙 \~english printer is busy
};

/**
 *  \~chinese
 *
 *  FT800打印机解析模型    
 *
 *  \~english
 *
 *  Resovle model for FT800 printer.
 *
 */
@interface FT800ResolverModel : RYCommonResolveModel

@property (nonatomic, assign) Byte protocolVersion;///< \~chinese 协议版本 \~english protocol version

@property (nonatomic, assign) Byte packageId;///< \~chinese 包序号 \~english package id

@property (nonatomic, assign) FT800PackageControl control;///< \~chinese 控制位 \~english control byte

@property (nonatomic, assign) Byte app_port;///< \~chinese 应用端口 \~english application port

@property (nonatomic, assign) FT800PackageType type;///< \~chinese 包类型 \~english package type

@end

/**
 *  \~chinese
 *
 *  FT800数据解析器
 *
 *  \~english
 *
 *  Data resolver for FT800 printer.
 *
 */
@interface FT800DataResolver : RYCommonResolver

@end

/**
 *  \~chinese
 *
 *  命令数据包解析模型
 *
 *  \~english
 *
 *  Command data package resolve model.
 *
 */
@interface FT800CommandResolveModel : NSObject

@property (nonatomic, assign) Byte packeId;

@property (nonatomic, assign) FT800CommandType type;

@property (nonatomic, assign) FT800PackageResult result;

@property (nonatomic, strong) NSData *content;

- (instancetype _Nullable)initWith:(FT800ResolverModel *)model;

@end

NS_ASSUME_NONNULL_END
