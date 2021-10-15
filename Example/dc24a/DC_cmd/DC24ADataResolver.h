//
//  DC24ADataResolver.h
//  HPrint
//
//  Created by ldc on 2020/9/15.
//  Copyright © 2020 Hanin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "base.h"
#import "RYResolver.h"
#import "DC24ALikeCommandGenerator.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_OPTIONS(UInt16, DC24APrinterStatus) {
   
   DC24APrinterStatusTandaiHuishouYichang = 1 << 0,///碳带回收异常
   
   DC24APrinterStatusTandaiWeiJiaozhun = 1 << 1,///碳带未校准
   
   DC24APrinterStatusGaowen = 1 << 2,///高温
   
   DC24APrinterStatusDianyaGuodi = 1 << 3,///电压过低
   
   DC24APrinterStatusDianyaGuogao = 1 << 4,///电压过高
   
   DC24APrinterStatusFeifaHaocai = 1 << 5,///非法耗材
    
    DC24APrinterStatusHaocaiYongjin = 1 << 6,///耗材用尽
    
    DC24APrinterStatusHuancunFeikong = 1 << 7,///缓存非空
    
    DC24APrinterStatusTandaiGunzhouYichang = 1 << 8,///< \~碳带滚轴异常
};
/**
 *  \~chinese
 *
 *  DC24A数据解析器
 *
 *  \~english
 *
 *  Data resolver for DC24A printer.
 *
 */
@interface DC24ADataResolver : RYCommonResolver

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
@interface DC24AResolverModel : RYCommonResolveModel

@property (nonatomic, assign) Byte packageId;///< \~chinese 包序号 \~english package id

@property (nonatomic, assign) DC24ACommandType commandType;

@property (nonatomic, assign) BOOL success;

@end

NS_ASSUME_NONNULL_END
