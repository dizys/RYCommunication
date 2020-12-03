//
//  FT800DataResolver.m
//  HPrint
//
//  Created by ldc on 2020/9/15.
//  Copyright © 2020 Hanin. All rights reserved.
//

#import "FT800DataResolver.h"

@implementation FT800ResolverModel

@end

@implementation FT800DataResolver

- (void)registerHandle {
    
    NSData *key = [NSData dataWithBytes:"\x1b\x1a" length:2];
    RYDataRouterBlock *block = [[RYDataRouterBlock alloc] init];
    block.minDataLength = 18;
    block.handleBlock = ^FT800ResolverModel * _Nullable(NSData * _Nonnull data) {
        Byte *head = (Byte *)data.bytes;
        head += 10;
        uint32_t dataLength = *((uint32_t *)head);
        if (data.length < 18 + dataLength) {
            return nil;
        }
        FT800ResolverModel *model = [[FT800ResolverModel alloc] init];
        head -= 8;
        model.protocolVersion = *head;
        head++;
        model.packageId = *head;
        head++;
        model.type = *head;
        head++;
        model.control = *head;
        head++;
        model.app_port = *head;
        model.data = [data subdataWithRange:NSMakeRange(14, dataLength)];
        model.cost = 18 + dataLength;
        model.rawData = [data subdataWithRange:NSMakeRange(0, model.cost)];
        Byte port = 0;
        switch (model.type) {
            case FT800PackageTypeHandshake:
                port = ((Byte *)model.data.bytes)[3];
                [FT800LikeCommandGenerator default].port = port;
                break;
            default:
                break;
        }
        return model;
    };
    [self.router registerHandle:key block:block];
}

@end


@implementation FT800CommandResolveModel

- (instancetype)initWith:(FT800ResolverModel *)model {
    
    if (model.type != FT800PackageTypeCommand) {
        return  nil;
    }
    self = [super init];
    if (self) {
        Byte *head = (Byte *)(model.data.bytes);
        UInt16 code = *(UInt16 *)head;
        head += 2;
        self.packeId = *head;
        head++;
        self.result = (FT800PackageResult)*head;
        head++;
        UInt16 subtype = 0;
        NSMutableData *content = [[NSMutableData alloc] init];
        switch (code) {
            case 1:
            case 2:
            case 3:
            case 4:
            case 0xa:
                subtype = *(UInt16 *)head;
                [content appendData:[model.data subdataWithRange:NSMakeRange(6, model.data.length - 6)]];
                break;
            default:
                break;
        }
        self.type = (((UInt32)code) << 16) + (UInt32)subtype;
        self.content = content;
    }
    return self;
}

@end
