//
//  HPoooliCmdSampleGenerator.m
//  PoooliExample
//
//  Created by ldc on 2019/12/3.
//  Copyright © 2019 Xiamen Hanin. All rights reserved.
//

#import "HPoooliCmdSampleGenerator.h"
#import "PoooliCmdGenerator.h"

NSString *descForPaperType(PoooliPaperType type) {
    
    switch (type) {
        case PoooliPaperTypeReceipt:
            return @"连续纸";
        case PoooliPaperTypeLabel:
            return @"标签纸";
        default:
            return @"";
    }
}

NSString *descForPoooliPrinterStatus(PoooliPrinterStatus status) {
    
    NSMutableArray<NSString *> *array = [[NSMutableArray alloc] init];
    if ((status & PoooliPrinterStatusPaperAbsent) != 0) {
        [array addObject:@"缺纸"];
    }
    if ((status & PoooliPrinterStatusHighTemperature) != 0) {
        [array addObject:@"高温"];
    }
    if ((status & PoooliPrinterStatusLowTemperature) != 0) {
        [array addObject:@"低温"];
    }
    if ((status & PoooliPrinterStatusLowVoltage) != 0) {
        [array addObject:@"低电量"];
    }
    if ((status & PoooliPrinterStatusCoverOpened) != 0) {
        [array addObject:@"开盖"];
    }
    if ((status & PoooliPrinterStatusBatteryDamaged) != 0) {
        [array addObject:@"电池损坏"];
    }
    if ((status & PoooliPrinterStatusLocateFail) != 0) {
        [array addObject:@"定位失败"];
    }
    return array.count == 0 ? @"" : [array componentsJoinedByString:@"-"];
}

NSString *descForPrinterStatusInfo(PoooliPrinterStatusInfo *info) {
    
    return [NSString stringWithFormat:@"打印机状态: %@\n是否空闲: %@\n电量: %u\n自动关机时间: %u\n打印浓度: %u\n纸张类型: %@\nTPH温度: %u\n", descForPoooliPrinterStatus(info.status), info.isIdle ? @"是" : @"否", info.power, info.standbyTime, info.density, descForPaperType(info.paperType), info.tphTemperature];
}

@implementation HPoooliCmdSampleGenerator
@synthesize sampleList;

- (instancetype)initWith:(id<RYAccessory>)transmitter target:(NSViewController *)target
{
    self = [super init];
    if (self) {
        self.transimitter = transmitter;
        self.target = target;
        self.cacheData = [[NSMutableData alloc] init];
    }
    return self;
}

- (void)setDensity {
    
    self.transimitter.resolver.resolvedBlock = ^(id  _Nonnull result) {
        NSData *d = (NSData *)result;
        if (d.length != 2) {
            return;
        }
        NSString *ack = [[NSString alloc] initWithData:d encoding:NSASCIIStringEncoding];
        if ([ack isEqualToString:@"OK"]) {
            [self showMessage:@"设置浓度成功"];
        }else if ([ack isEqualToString:@"NG"]) {
            [self showMessage:@"设置浓度失败"];
        }
    };
    NSData *data = [PoooliCmdGenerator setDensity:75];
    [self.transimitter write:data progress:nil];
}

- (void)setStandbyTime {
    
    self.transimitter.resolver.resolvedBlock = ^(id  _Nonnull result) {
        NSData *d = (NSData *)result;
        if (d.length != 2) {
            return;
        }
        NSString *ack = [[NSString alloc] initWithData:d encoding:NSASCIIStringEncoding];
        if ([ack isEqualToString:@"OK"]) {
            [self showMessage:@"设置待机时间成功"];
        }else if ([ack isEqualToString:@"NG"]) {
            [self showMessage:@"设置待机时间失败"];
        }
    };
    NSData *data = [PoooliCmdGenerator setStandbyTime:1800];
    [self.transimitter write:data progress:nil];
}

- (void)printImage {
    
    NSURL *path = [[NSBundle mainBundle] URLForResource:@"sample" withExtension:@"jpg"];
    NSBitmapImageRep *rep = [NSBitmapImageRep imageRepWithData:[NSData dataWithContentsOfURL:path]];
    self.transimitter.resolver.resolvedBlock = ^(id  _Nonnull result) {
        NSData *d = (NSData *)result;
        NSLog(@"%@", d);
    };
    NSData *data = [PoooliCmdGenerator printBlackAndWhiteImage:rep.CGImage];
    [self.transimitter write:data progress:^(NSProgress * _Nonnull p) {
        NSLog(@"发送进度: %llu-%llu", p.completedUnitCount, p.totalUnitCount);
    }];
}

- (void)requestPrinterInfo {
    
    self.cacheData = [[NSMutableData alloc] init];
    self.transimitter.resolver.resolvedBlock = ^(id  _Nonnull result) {
        NSData *d = (NSData *)result;
        [self.cacheData appendData:d];
        PoooliPrinterInfo *info = [[PoooliPrinterInfo alloc] initWithData:self.cacheData];
        if (info) {
            [self showMessage:[info description]];
        }
    };
    NSData *data = [PoooliCmdGenerator requestPrinterInfo];
    [self.transimitter write:data progress:nil];
}

- (void)requestPrinterStatus {
    
    self.cacheData = [[NSMutableData alloc] init];
    self.transimitter.resolver.resolvedBlock = ^(id  _Nonnull result) {
        NSData *d = (NSData *)result;
        [self.cacheData appendData:d];
        PoooliPrinterStatusInfo *info = [[PoooliPrinterStatusInfo alloc] initWithData:self.cacheData];
        if (info) {
            [self showMessage:descForPrinterStatusInfo(info)];
        }
    };
    NSData *data = [PoooliCmdGenerator requestPrinterStatus];
    [self.transimitter write:data progress:nil];
}

- (void)feedPaper {
    
    NSData *data = [PoooliCmdGenerator feedPaper:80];
    [self.transimitter write:data progress:nil];
}

- (void)printConfigPage {
    
    NSData *data = [PoooliCmdGenerator printConfigPage];
    [self.transimitter write:data progress:nil];
}

- (void)feedPaperAndLocate {
    
    NSData *data = [PoooliCmdGenerator feedPaperAndLocate:80];
    [self.transimitter write:data progress:nil];
}

- (void)setPaperType {
    
    self.transimitter.resolver.resolvedBlock = ^(id  _Nonnull result) {
        NSData *d = (NSData *)result;
        if (d.length != 2) {
            return;
        }
        NSString *ack = [[NSString alloc] initWithData:d encoding:NSASCIIStringEncoding];
        if ([ack isEqualToString:@"OK"]) {
            [self showMessage:@"设置纸张类型成功"];
        }else if ([ack isEqualToString:@"NG"]) {
            [self showMessage:@"设置纸张类型失败"];
        }
    };
    NSData *data = [PoooliCmdGenerator setPaperType:PoooliPaperTypeReceipt];
    [self.transimitter write:data progress:nil];
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
        model = [[HSampleModel alloc] initWith:@selector(setDensity) title:@"设置打印浓度" detail:nil];
        [sampleList addObject:model];
        model = [[HSampleModel alloc] initWith:@selector(setStandbyTime) title:@"设置休眠时间" detail:nil];
        [sampleList addObject:model];
        model = [[HSampleModel alloc] initWith:@selector(printImage) title:@"打印图片" detail:nil];
        [sampleList addObject:model];
        model = [[HSampleModel alloc] initWith:@selector(requestPrinterInfo) title:@"获取打印机设备信息" detail:nil];
        [sampleList addObject:model];
        model = [[HSampleModel alloc] initWith:@selector(requestPrinterStatus) title:@"获取打印机状态" detail:nil];
        [sampleList addObject:model];
        model = [[HSampleModel alloc] initWith:@selector(feedPaper) title:@"走纸" detail:nil];
        [sampleList addObject:model];
        model = [[HSampleModel alloc] initWith:@selector(printConfigPage) title:@"打印自检页" detail:nil];
        [sampleList addObject:model];
        model = [[HSampleModel alloc] initWith:@selector(feedPaperAndLocate) title:@"定位走纸" detail:nil];
        [sampleList addObject:model];
        model = [[HSampleModel alloc] initWith:@selector(setPaperType) title:@"设置纸张类型" detail:nil];
        [sampleList addObject:model];
    }
    return sampleList;
}

@end
