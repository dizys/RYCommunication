//
//  HDataResolver.m
//  MocolourSDK
//
//  Created by ldc on 2019/12/17.
//  Copyright © 2019 swiftHY. All rights reserved.
//

#import "HDataResolver.h"
#import "MTCmdGenerator.h"

@implementation MTResolverModel

@end

@implementation MTDataResolver

- (void)registerHandle {
    
    //打印机状态
    RYDataRouterBlock *block = [[RYDataRouterBlock alloc] init];
    block.minDataLength = 18;
    block.handleBlock = ^MTResolverModel * _Nullable(NSData * _Nonnull data) {
        MTResolverModel *model = [[MTResolverModel alloc] init];
        model.data = [data subdataWithRange:NSMakeRange(5, 12)];
        model.cost = 18;
        model.type = MTCmdTypePrinterInfo;
        model.rawData = [data subdataWithRange:NSMakeRange(0, 18)];
        return model;
    };
    NSData *key = [NSData dataWithBytes:"rtsts" length:5];
    [self.router registerHandle:key block:block];
    //碳带品牌
    block = [[RYDataRouterBlock alloc] init];
    block.minDataLength = 6;
    block.handleBlock = ^MTResolverModel * _Nullable(NSData * _Nonnull data) {
        Byte length = ((Byte *)data.bytes)[5];
        NSInteger cost = length + 6;
        if (data.length < cost) {
            return nil;
        }
        MTResolverModel *model = [[MTResolverModel alloc] init];
        model.data = [data subdataWithRange:NSMakeRange(6, length)];
        model.cost = cost;
        model.type = MTCmdTypeCarbonRibbonBrand;
        model.rawData = [data subdataWithRange:NSMakeRange(0, cost)];
        return model;
    };
    key = [NSData dataWithBytes:"rbbnd" length:5];
    [self.router registerHandle:key block:block];
    //碳带余量
    block = [[RYDataRouterBlock alloc] init];
    block.minDataLength = 9;
    block.handleBlock = ^MTResolverModel * _Nullable(NSData * _Nonnull data) {
        MTResolverModel *model = [[MTResolverModel alloc] init];
        model.data = [data subdataWithRange:NSMakeRange(5, 4)];
        model.cost = 9;
        model.type = MTCmdTypeCarbonRibbonRemainCount;
        model.rawData = [data subdataWithRange:NSMakeRange(0, 9)];
        return model;
    };
    key = [NSData dataWithBytes:"rbspl" length:5];
    [self.router registerHandle:key block:block];
    //序列号
    block = [[RYDataRouterBlock alloc] init];
    block.minDataLength = 3;
    block.handleBlock = ^MTResolverModel * _Nullable(NSData * _Nonnull data) {
        Byte length = ((Byte *)data.bytes)[2];
        NSInteger cost = length + 3;
        if (data.length < cost) {
            return nil;
        }
        MTResolverModel *model = [[MTResolverModel alloc] init];
        model.data = [data subdataWithRange:NSMakeRange(3, length)];
        model.cost = cost;
        model.type = MTCmdTypeSn;
        model.rawData = [data subdataWithRange:NSMakeRange(0, cost)];
        return model;
    };
    key = [NSData dataWithBytes:"sn" length:2];
    [self.router registerHandle:key block:block];
    //固件版本
    block = [[RYDataRouterBlock alloc] init];
    block.minDataLength = 4;
    block.handleBlock = ^MTResolverModel * _Nullable(NSData * _Nonnull data) {
        Byte length = ((Byte *)data.bytes)[3];
        NSInteger cost = length + 4;
        if (data.length < cost) {
            return nil;
        }
        MTResolverModel *model = [[MTResolverModel alloc] init];
        model.data = [data subdataWithRange:NSMakeRange(4, length)];
        model.cost = cost;
        model.type = MTCmdTypeFirmwareVersion;
        model.rawData = [data subdataWithRange:NSMakeRange(0, cost)];
        return model;
    };
    key = [NSData dataWithBytes:"ver" length:3];
    [self.router registerHandle:key block:block];
    //清除缓存
    block = [[RYDataRouterBlock alloc] init];
    block.minDataLength = 4;
    block.handleBlock = ^MTResolverModel * _Nullable(NSData * _Nonnull data) {
        MTResolverModel *model = [[MTResolverModel alloc] init];
        model.data = [data subdataWithRange:NSMakeRange(3, 1)];
        model.cost = 4;
        model.type = MTCmdTypeClearBuffer;
        model.rawData = [data subdataWithRange:NSMakeRange(0, 4)];
        return model;
    };
    key = [NSData dataWithBytes:"can" length:3];
    [self.router registerHandle:key block:block];
    //状态自动回传
    block = [[RYDataRouterBlock alloc] init];
    block.minDataLength = 9;
    block.handleBlock = ^MTResolverModel * _Nullable(NSData * _Nonnull data) {
        MTResolverModel *model = [[MTResolverModel alloc] init];
        model.data = [data subdataWithRange:NSMakeRange(7, 2)];
        model.cost = 9;
        model.type = MTCmdTypeAutoStatus;
        model.rawData = [data subdataWithRange:NSMakeRange(0, 9)];
        return model;
    };
    key = [NSData dataWithBytes:"status:" length:3];
    [self.router registerHandle:key block:block];
    //图片分包数据
    block = [[RYDataRouterBlock alloc] init];
    block.minDataLength = 10;
    block.handleBlock = ^MTResolverModel * _Nullable(NSData * _Nonnull data) {
        MTResolverModel *model = [[MTResolverModel alloc] init];
        model.data = [data subdataWithRange:NSMakeRange(3, 7)];
        model.cost = 10;
        model.type = MTCmdTypeImageSliceAck;
        model.rawData = [data subdataWithRange:NSMakeRange(0, 10)];
        return model;
    };
    key = [NSData dataWithBytes:"\x1b\x12\x76" length:3];
    [self.router registerHandle:key block:block];
    //固件分包数据
    block = [[RYDataRouterBlock alloc] init];
    block.minDataLength = 8;
    block.handleBlock = ^MTResolverModel * _Nullable(NSData * _Nonnull data) {
        MTResolverModel *model = [[MTResolverModel alloc] init];
        model.data = [data subdataWithRange:NSMakeRange(3, 5)];
        model.cost = 8;
        model.type = MTCmdTypeFirmwareSliceAck;
        model.rawData = [data subdataWithRange:NSMakeRange(0, 8)];
        return model;
    };
    key = [NSData dataWithBytes:"\x1b\x1c\x26" length:3];
    [self.router registerHandle:key block:block];
    //通用指令设置
    block = [[RYDataRouterBlock alloc] init];
    block.minDataLength = 9;
    block.handleBlock = ^MTResolverModel * _Nullable(NSData * _Nonnull data) {
        MTResolverModel *model = [[MTResolverModel alloc] init];
        model.data = [data subdataWithRange:NSMakeRange(6, 3)];
        model.cost = 9;
        model.type = MTCmdTypeCommonSet;
        model.rawData = [data subdataWithRange:NSMakeRange(0, 9)];
        return model;
    };
    key = [NSData dataWithBytes:"setkey" length:6];
    [self.router registerHandle:key block:block];
    //通用指令查询
    block = [[RYDataRouterBlock alloc] init];
    block.minDataLength = 9;
    block.handleBlock = ^MTResolverModel * _Nullable(NSData * _Nonnull data) {
        Byte length = ((Byte *)data.bytes)[8];
        NSInteger cost = length + 9;
        if (data.length < cost) {
            return nil;
        }
        MTResolverModel *model = [[MTResolverModel alloc] init];
        model.data = [data subdataWithRange:NSMakeRange(6, length + 3)];
        model.cost = cost;
        model.type = MTCmdTypeCommonGet;
        model.rawData = [data subdataWithRange:NSMakeRange(0, cost)];
        return model;
    };
    key = [NSData dataWithBytes:"getkey" length:6];
    [self.router registerHandle:key block:block];
    //碳带相关信息查询
    block = [[RYDataRouterBlock alloc] init];
    block.minDataLength = 3;
    block.handleBlock = ^MTResolverModel * _Nullable(NSData * _Nonnull data) {
        Byte length = ((Byte *)data.bytes)[2];
        NSInteger cost = length + 3;
        if (data.length < cost) {
            return nil;
        }
        MTResolverModel *model = [[MTResolverModel alloc] init];
        model.data = [data subdataWithRange:NSMakeRange(1, length+2)];
        model.cost = cost;
        model.type = MTCmdTypeCarbonRibbonProperty;
        model.rawData = [data subdataWithRange:NSMakeRange(0, cost)];
        return model;
    };
    key = [NSData dataWithBytes:"\xAA" length:1];
    [self.router registerHandle:key block:block];
}

@end
