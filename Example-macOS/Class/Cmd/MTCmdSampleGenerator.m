//
//  MTCmdSampleGenerator.m
//  PoooliExample
//
//  Created by ldc on 2019/12/3.
//  Copyright © 2019 Xiamen Hanin. All rights reserved.
//

#import "MTCmdSampleGenerator.h"
#import "HDataResolver.h"
#import "MTCmdGenerator.h"
#import "MTImagePrintDispatcher.h"
#import "MTFirmwareUpdateDispatcher.h"
#import <RYCommunication/RYCommunication.h>

NSString * descForMTPrinterStatus(MTPrinterStatus status) {
    
    NSMutableArray<NSString *> *items = [[NSMutableArray alloc] init];
    if ((status & MTPrinterStatusPaperAbsent) != 0) {
        [items addObject:@"缺纸"];
    }
    if ((status & MTPrinterStatusHighTemperature) != 0) {
        [items addObject:@"高温"];
    }
    if ((status & MTPrinterStatusLowTemperature) != 0) {
        [items addObject:@"低温"];
    }
    if ((status & MTPrinterStatusLowVoltage) != 0) {
        [items addObject:@"低电量"];
    }
    if ((status & MTPrinterStatusHeadOpened) != 0) {
        [items addObject:@"开盖"];
    }
    if ((status & MTPrinterStatusCarbonRibbonEnd) != 0) {
        [items addObject:@"碳带用尽"];
    }
    if ((status & MTPrinterStatusPaperSmashe) != 0) {
        [items addObject:@"纸装歪"];
    }
    if ((status & MTPrinterStatusCarbonRibbonNotAuthorization) != 0) {
        [items addObject:@"碳带未授权"];
    }
    if ((status & MTPrinterStatusBufferFull) != 0) {
        [items addObject:@"缓存区已满"];
    }
    if ((status & MTPrinterStatusNoMileage) != 0) {
        [items addObject:@"里程不足"];
    }
    return [items componentsJoinedByString:@"-"];
}

NSString *titleForCarbonRibbonResponseProperty(MTCarbonRibbonResponseProperty propery) {
    
    switch (propery) {
        case MTCarbonRibbonResponsePropertyUid:
            return @"RFID标签UID";
        case MTCarbonRibbonResponsePropertyPrinterModelAvailable:
            return @"查询碳带适用机型";
        case MTCarbonRibbonResponsePropertyWidth:
            return @"碳带宽度";
        case MTCarbonRibbonResponsePropertyType:
            return @"碳带类型";
        case MTCarbonRibbonResponsePropertyVenderId:
            return @"厂商ID";
        case MTCarbonRibbonResponsePropertyHeatFactor:
            return @"加热系数";
        case MTCarbonRibbonResponsePropertyLengthPrinted:
            return @"打印里程查询";
        default:
            return @"未知属性";
    }
}

@interface MTPrinterInfo (Description)

@end

@implementation MTPrinterInfo (Description)

- (NSString *)description {
    
    NSMutableString *result = [[NSMutableString alloc] init];
    [result appendFormat:@"打印机状态: %@\n", descForMTPrinterStatus(self.status)];
    [result appendFormat:@"空闲: %@\n", self.idle ? @"是" : @"否"];
    [result appendFormat:@"电量: %u\n", self.electricQuantity];
    [result appendFormat:@"自动关机时间: %u\n", self.autoShutdownTime];
    [result appendFormat:@"打印浓度: %u\n", self.printDensity];
    [result appendFormat:@"纸张类型: %@\n", self.paperType == MTPaperTypeThermal ? @"热敏纸" : @"A4纸"];
    [result appendFormat:@"TPH温度: %u\n", self.tphTemperature];
    return result;
}

@end

@interface MTCmdSampleGenerator ()

@property (nonatomic, strong) MTImagePrintDispatcher *imageDispatcher;

@property (nonatomic, strong) MTFirmwareUpdateDispatcher *updateDispatcher;

@end

@implementation MTCmdSampleGenerator
@synthesize sampleList;

- (instancetype)initWith:(id<RYAccessory>)transmitter target:(NSViewController *)target
{
    self = [super init];
    if (self) {
        self.transimitter = transmitter;
        self.target = target;
        [self configureResolveBlock];
    }
    return self;
}

- (void)configureResolveBlock {
    
    self.transimitter.resolver = [[MTDataResolver alloc] init];
    self.transimitter.resolver.resolvedBlock = ^(id  _Nonnull result) {
        if (![result isMemberOfClass:[MTResolverModel class]]) {
            return;
        }
        MTResolverModel *model = (MTResolverModel *)result;
//        NSLog(@"%@--%@", model.content, model.rawData);
        switch (model.type) {
            case MTCmdTypePrinterInfo:
                [self showMessage:[NSString stringWithFormat:@"读取到打印机信息: %@", [[MTPrinterInfo alloc] initWithData:model.data]]];
                break;
            case MTCmdTypeCarbonRibbonBrand:
                [self showMessage:[NSString stringWithFormat:@"读取到碳带品牌: %@", [[NSString alloc] initWithData:model.data encoding:NSUTF8StringEncoding]]];
                break;
            case MTCmdTypeCarbonRibbonRemainCount:
                [self showMessage:[NSString stringWithFormat:@"读取到碳带余量: %imm", *((int32_t *)model.data.bytes)]];
                break;
            case MTCmdTypeSn:
                [self showMessage:[NSString stringWithFormat:@"读取到序列号: %@", [[NSString alloc] initWithData:model.data encoding:NSUTF8StringEncoding]]];
                break;
            case MTCmdTypeFirmwareVersion:
                [self showMessage:[NSString stringWithFormat:@"读取到固件版本: %@", [[NSString alloc] initWithData:model.data encoding:NSUTF8StringEncoding]]];
                break;
            case MTCmdTypeClearBuffer:
                [self showMessage:[NSString stringWithFormat:@"清空缓存: %@", *((Byte *)model.data.bytes) == 1 ? @"成功" : @"失败"]];
                break;
            case MTCmdTypeAutoStatus:
                [self showMessage:[NSString stringWithFormat:@"自动回传: %@", descForMTPrinterStatus((MTPrinterStatus)*((uint16_t *)model.data.bytes))]];
                break;
            case MTCmdTypeImageSliceAck:
                [self.imageDispatcher readSliceAck:model];
                break;
            case MTCmdTypeFirmwareSliceAck:
                [self.updateDispatcher readSliceAck:model];
                break;
            case MTCmdTypeCommonGet:
                [self whenGetCommonCmdSuccess:model];
                break;
            case MTCmdTypeCommonSet:
                [self whenSetCommonCmdSuccess:model];
                break;
            case MTCmdTypeCarbonRibbonProperty:
                [self whenGetCarbonRibbonResponseProperty:model];
                break;
            default:
                break;
        }
    };
}

- (void)whenGetCarbonRibbonResponseProperty:(MTResolverModel *)model {
    
    NSData *data = model.data;
    MTCarbonRibbonResponseProperty property = (MTCarbonRibbonResponseProperty)((Byte *)data.bytes)[0];
    NSString *desc;
    NSData *content = [data subdataWithRange:NSMakeRange(2, data.length-2)];
    uint32_t temp;
    switch (property) {
        case MTCarbonRibbonResponsePropertyPrinterModelAvailable:
        case MTCarbonRibbonResponsePropertyType:
            desc = [[NSString alloc] initWithData:content encoding:NSUTF8StringEncoding];
            break;
        case MTCarbonRibbonResponsePropertyUid:
        case MTCarbonRibbonResponsePropertyVenderId:
            temp = *(uint32_t *)content.bytes;
            htonl(temp);
            desc = [NSString stringWithFormat:@"%X", temp];
            break;
        case MTCarbonRibbonResponsePropertyWidth:
        case MTCarbonRibbonResponsePropertyHeatFactor:
        case MTCarbonRibbonResponsePropertyLengthPrinted:
            temp = *(uint32_t *)content.bytes;
            desc = [NSString stringWithFormat:@"%i", temp];
            break;
        default:
            break;
    }
    [self showMessage:[NSString stringWithFormat:@"%@: %@", titleForCarbonRibbonResponseProperty(property), desc]];
}

- (void)whenGetCommonCmdSuccess:(MTResolverModel *)model {
    
    NSString *type = @"";
    NSString *desc = @"";
    Byte *head = (Byte *)model.data.bytes;
    MTCommonCmdKey key = (MTCommonCmdKey)*((uint16_t *)head);
    Byte size = head[2];
    switch (key) {
        case MTCommonCmdKeyPrinterName:
            type = @"机型名称";
            desc = [[NSString alloc] initWithData:[model.data subdataWithRange:NSMakeRange(3, size)] encoding:NSUTF8StringEncoding];
            break;
        case MTCommonCmdKeyPrintDensity:
            type = @"打印浓度";
            desc = [NSString stringWithFormat:@"%u", head[3]];
            break;
        case MTCommonCmdKeyShutdownTime:
            type = @"自动关机时间";
            head += 3;
            desc = [NSString stringWithFormat:@"%u分钟", *(uint32_t *)head];
            break;
        default:
            return;
    }
    [self showMessage:[NSString stringWithFormat:@"查询结果: %@ ==> %@", type, desc]];
}

- (void)whenSetCommonCmdSuccess:(MTResolverModel *)model {
    
    NSString *type = @"";
    Byte *head = (Byte *)model.data.bytes;
    MTCommonCmdKey key = (MTCommonCmdKey)*((uint16_t *)head);
    switch (key) {
        case MTCommonCmdKeyPrinterName:
            type = @"机型名称";
            break;
        case MTCommonCmdKeyPrintDensity:
            type = @"打印浓度";
            break;
        case MTCommonCmdKeyShutdownTime:
            type = @"自动关机时间";
            break;
        default:
            return;
    }
    [self showMessage:[NSString stringWithFormat:@"设置结果: %@ ==> %@", type, head[2] == 0 ? @"成功" : @"失败"]];
}

- (void)test {
    
    Byte byte[] = {0x1B, 0x1C, 0x26, 0x20, 0x56, 0x31, 0x20, 0x67, 0x65, 0x74, 0x6B, 0x65, 0x79, 0x0D, 0x0A, 0x01, 0xCB, 0x00, 0x01};
    NSData *data = [NSData dataWithBytes:byte length:sizeof(byte)];
    [self.transimitter write:data progress:nil];
}

- (void)getPrinterStatusInfo {
    
    NSData *data = [MTCmdGenerator getPrinterStatusInfo];
    [self.transimitter write:data progress:nil];
}

- (void)getRibbonConsumablesBrandInfo {
    
    NSData *data = [MTCmdGenerator getRibbonConsumablesBrandInfo];
    [self.transimitter write:data progress:nil];
}

- (void)requestRemainCarbonRibbonCount {
    
    NSData *data = [MTCmdGenerator getRibbonRemainCount];
    [self.transimitter write:data progress:nil];
}

- (void)getPrinterSerialNumber {
    
    NSData *data = [MTCmdGenerator getPrinterSerialNumber];
    [self.transimitter write:data progress:nil];
}

- (void)getPrinterFirmwareVersion {
    
    NSData *data = [MTCmdGenerator getPrinterFirmwareVersion];
    [self.transimitter write:data progress:nil];
}

- (void)clearPrinterBuffer {
    
    NSData *data = [MTCmdGenerator clearPrinterBuffer];
    [self.transimitter write:data progress:nil];
}

- (void)printImage {
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"bitmap" ofType:@"bin"];
    NSData *bitmap = [NSData dataWithContentsOfFile:path];
    self.imageDispatcher = [[MTImagePrintDispatcher alloc] initWithBitmap:bitmap height:3304 transmitter:self.transimitter];
    __weak typeof(self) weakSelf = self;
    self.imageDispatcher.completeBlock = ^(NSError *error) {
        weakSelf.imageDispatcher = nil;
        if (error) {
            switch (error.code) {
                case MTImagePrintDispatcherErrorCodeTimeoutTooMuch:
                    [weakSelf showMessage:@"图片数据发送失败: 超时次数过多"];
                    break;
                default:
                    break;
            }
        }else {
            MTPaperType type = MTPaperTypeA4;
            if (type == MTPaperTypeA4) {
                [weakSelf.transimitter write:[NSData dataWithBytes:"\x0c" length:1] progress:nil];
            }else {
                Byte cmd[13];
                for (int i = 0; i < 13; i++) {
                    cmd[i] = 0xa;
                }
                [weakSelf.transimitter write:[NSData dataWithBytes:cmd length:13] progress:nil];
            }
            [weakSelf showMessage:@"图片数据发送完成"];
        }
    };
    [self.imageDispatcher start];
}

- (void)firmwareUpdate {
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"mt_beta" ofType:@"bin"];
    NSData *data = [NSData dataWithContentsOfFile:path];
    self.updateDispatcher = [[MTFirmwareUpdateDispatcher alloc] initWithBinary:data transmitter:self.transimitter];
    __weak typeof(self) weakSelf = self;
    self.updateDispatcher.completeBlock = ^(NSError *error) {
        weakSelf.updateDispatcher = nil;
        if (error) {
            switch (error.code) {
                case MTFirmwareUpdateDispatcherErrorCodeTimeoutTooMuch:
                    [weakSelf showMessage:@"固件数据发送失败: 超时次数过多"];
                    break;
                default:
                    break;
            }
        }else {
            [weakSelf showMessage:@"固件数据发送完成"];
        }
    };
    [self.updateDispatcher start];
}

- (void)getShutdownTime {
    
    NSData *cmd = [MTCmdGenerator getPrinterShutdownTime];
    [self.transimitter write:cmd progress:nil];
    
}

- (void)setShutdownTime {
    
    NSData *cmd = [MTCmdGenerator setPrinterShutdownTime:0x100];
    [self.transimitter write:cmd progress:nil];
}

- (void)getPrinterName {
    
    NSData *cmd = [MTCmdGenerator getPrinterName];
    [self.transimitter write:cmd progress:nil];
}

- (void)getPrinterDensity {
    
    NSData *cmd = [MTCmdGenerator getPrinterDensity];
    [self.transimitter write:cmd progress:nil];
}

- (void)setPrinterDensity {
    //1~3
    NSData *cmd = [MTCmdGenerator setPrinterDensity:1];
    [self.transimitter write:cmd progress:nil];
}

- (void)getCarbonRibbonUid {
    
    NSData *cmd = [MTCmdGenerator getCarbonInfo:MTCarbonRibbonPropertyUid];
    [self.transimitter write:cmd progress:nil];
}

- (void)getCarbonRibbonPrinterModelAvailable {
    
    NSData *cmd = [MTCmdGenerator getCarbonInfo:MTCarbonRibbonPropertyPrinterModelAvailable];
    [self.transimitter write:cmd progress:nil];
}

- (void)getCarbonRibbonWidth {
    
    NSData *cmd = [MTCmdGenerator getCarbonInfo:MTCarbonRibbonPropertyWidth];
    [self.transimitter write:cmd progress:nil];
}

- (void)getCarbonRibbonType {
    
    NSData *cmd = [MTCmdGenerator getCarbonInfo:MTCarbonRibbonPropertyType];
    [self.transimitter write:cmd progress:nil];
}

- (void)getCarbonRibbonVenderId {
    
    NSData *cmd = [MTCmdGenerator getCarbonInfo:MTCarbonRibbonPropertyVenderId];
    [self.transimitter write:cmd progress:nil];
}

- (void)getCarbonRibbonHeatFactor {
    
    NSData *cmd = [MTCmdGenerator getCarbonInfo:MTCarbonRibbonPropertyHeatFactor];
    [self.transimitter write:cmd progress:nil];
}

- (void)getLengthPrinted {
    
    NSData *cmd = [MTCmdGenerator getLengthPrinted];
    [self.transimitter write:cmd progress:nil];
}

- (void)showMessage:(NSString *)msg {
    
    NSAlert *alert = [NSAlert new];
    [alert addButtonWithTitle:@"确定"];
    [alert setMessageText:@"接收消息"];
    [alert setInformativeText:msg];
    [alert setAlertStyle:NSWarningAlertStyle];
    [alert beginSheetModalForWindow:[self.target.view window] completionHandler:nil];
}

- (NSMutableArray<HSampleModel *> *)sampleList {
    
    if (!sampleList) {
        sampleList = [NSMutableArray new];
        HSampleModel *model;
        
        model = [[HSampleModel alloc] initWith:@selector(getPrinterStatusInfo) title:@"获取打印机状态" detail:nil];
        [sampleList addObject:model];
        
        model = [[HSampleModel alloc] initWith:@selector(getRibbonConsumablesBrandInfo) title:@"获取耗材品牌" detail:nil];
        [sampleList addObject:model];
        
        model = [[HSampleModel alloc] initWith:@selector(requestRemainCarbonRibbonCount ) title:@"获取碳带余量" detail:nil];
        [sampleList addObject:model];
        
        model = [[HSampleModel alloc] initWith:@selector(getPrinterSerialNumber) title:@"获取序列号" detail:nil];
        [sampleList addObject:model];
        
        model = [[HSampleModel alloc] initWith:@selector(getPrinterFirmwareVersion) title:@"获取固件版本" detail:nil];
        [sampleList addObject:model];
        
        model = [[HSampleModel alloc] initWith:@selector(clearPrinterBuffer) title:@"清除打印机缓存" detail:nil];
        [sampleList addObject:model];
        
        model = [[HSampleModel alloc] initWith:@selector(printImage) title:@"图片打印" detail:nil];
        [sampleList addObject:model];
        
        model = [[HSampleModel alloc] initWith:@selector(firmwareUpdate) title:@"固件更新" detail:nil];
        [sampleList addObject:model];
        
#pragma mark --V1.1.8可用
        model = [[HSampleModel alloc] initWith:@selector(getCarbonRibbonUid) title:@"RFID标签UID查询" detail:nil];
        [sampleList addObject:model];
        
        model = [[HSampleModel alloc] initWith:@selector(getCarbonRibbonPrinterModelAvailable) title:@"碳带适用机型查询" detail:nil];
        [sampleList addObject:model];
        
        model = [[HSampleModel alloc] initWith:@selector(getCarbonRibbonWidth) title:@"碳带宽度查询" detail:nil];
        [sampleList addObject:model];
        
        model = [[HSampleModel alloc] initWith:@selector(getCarbonRibbonType) title:@"碳带类型查询" detail:nil];
        [sampleList addObject:model];
        
        model = [[HSampleModel alloc] initWith:@selector(getCarbonRibbonVenderId) title:@"碳带厂商ID查询" detail:nil];
        [sampleList addObject:model];
        
        model = [[HSampleModel alloc] initWith:@selector(getCarbonRibbonHeatFactor) title:@"碳带加热系数查询" detail:nil];
        [sampleList addObject:model];
        
        model = [[HSampleModel alloc] initWith:@selector(getLengthPrinted) title:@"打印里程查询" detail:nil];
        [sampleList addObject:model];
        
#pragma mark --V1.1.9可用
        model = [[HSampleModel alloc] initWith:@selector(getShutdownTime) title:@"获取自动关机时间" detail:nil];
        [sampleList addObject:model];
        
        model = [[HSampleModel alloc] initWith:@selector(setShutdownTime) title:@"设置自动关机时间" detail:nil];
        [sampleList addObject:model];
        
        model = [[HSampleModel alloc] initWith:@selector(getPrinterName) title:@"获取打印机名称" detail:nil];
        [sampleList addObject:model];
        
        model = [[HSampleModel alloc] initWith:@selector(setPrinterDensity) title:@"设置打印浓度" detail:nil];
        [sampleList addObject:model];
        
        model = [[HSampleModel alloc] initWith:@selector(getPrinterDensity) title:@"获取打印机浓度" detail:nil];
        [sampleList addObject:model];
    }
    return sampleList;
}

@end
