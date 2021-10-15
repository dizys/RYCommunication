//
//  DC24ADataResolver.m
//  HPrint
//
//  Created by ldc on 2020/9/15.
//  Copyright © 2020 Hanin. All rights reserved.
//

#import "DC24ADataResolver.h"

@implementation DC24AResolverModel

@end

@implementation DC24ADataResolver

- (void)registerHandle {
    
    NSData *key = [NSData dataWithBytes:"\x10\x11\x12\x13" length:4];
    RYDataRouterBlock *block = [[RYDataRouterBlock alloc] init];
    block.minDataLength = 16;
    block.handleBlock = ^DC24AResolverModel * _Nullable(NSData * _Nonnull data) {
        Byte *temp = (Byte *)data.bytes;
        temp += 4;
        uint16_t length = *(uint16_t *)temp;
        NSInteger cost = length + 16;
        if (data.length < cost) {
            return nil;
        }
        DC24AResolverModel *model = [[DC24AResolverModel alloc] init];
        model.cost = cost;
        model.rawData = [data subdataWithRange:NSMakeRange(0, cost)];
        temp += 4;
        model.packageId = *(uint16_t *)temp;
        temp += 2;
        temp += 2;
        NSData * contentData = [NSData dataWithBytes:temp length:length];
        Byte *dataTemp = (Byte *)contentData.bytes;
        model.commandType = *(uint16_t *)temp;
        dataTemp += 2;
        model.success = *(uint16_t *)temp;
        dataTemp += 2;
        model.data = [NSData dataWithBytes:dataTemp length:length - 4];
        return model;
    };
    [self.router registerHandle:key block:block];
}

@end


//@implementation DC24ACommandResolveModel
//
//- (instancetype)initWith:(DC24AResolverModel *)model {
//    
//    self = [super init];
//    if (self) {
//        Byte *temp = (Byte *)(model.data.bytes);
//        UInt16 code = *(UInt16 *)temp;
//        temp += 2;
//        self.packeId = *temp;
//        temp++;
//        self.result = (DC24APackageResult)*temp;
//        temp++;
//        UInt16 subtype = 0;
//        NSMutableData *content = [[NSMutableData alloc] init];
//        switch (code) {
//            case 1:
//            case 2:
//            case 3:
//            case 4:
//            case 0xa:
//                subtype = *(UInt16 *)temp;
//                [content appendData:[model.data subdataWithRange:NSMakeRange(6, model.data.length - 6)]];
//                break;
//            default:
//                break;
//        }
//        self.type = (((UInt32)code) << 16) + (UInt32)subtype;
//        self.content = content;
//    }
//    return self;
//}
//
//@end
