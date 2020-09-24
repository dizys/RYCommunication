//
//  RYNotHandlingResolver.m
//  RYCommunication
//
//  Created by ldc on 2020/9/7.
//  Copyright © 2020 Xiamen Hanin. All rights reserved.
//

#import "RYResolver.h"

@implementation RYCommonResolverModel

@end

@implementation RYDataRouterBlock

@end

#define Handle 0xffff

@interface RYDataRouter ()

@property (nonatomic, strong) NSMutableDictionary<NSNumber *, id> *table;

@end

@implementation RYDataRouter

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.table = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)registerHandle:(NSData *)key block:(RYDataRouterBlock *)block {
    
    NSUInteger count = key.length;
    Byte *head = (Byte *)key.bytes;
    NSMutableDictionary<NSNumber *, id> *dic = self.table;
    for (int i = 0; i < count; i++) {
        NSNumber *_key = [NSNumber numberWithUnsignedChar:head[i]];
        if (dic[_key] && [dic[_key] isKindOfClass:[NSMutableDictionary class]]) {
            dic = dic[_key];
        }else {
            NSMutableDictionary *temp = [[NSMutableDictionary alloc] init];
            dic[_key] = temp;
            dic = temp;
        }
    }
    NSNumber *handleKey = [NSNumber numberWithUnsignedShort:Handle];
    dic[handleKey] = block;
    //    NSLog(@"%@", self.table);
}

- (RYDataRouterBlock *)handle:(NSData *)key {
    
    NSUInteger count = key.length;
    Byte *head = (Byte *)key.bytes;
    NSMutableDictionary<NSNumber *, id> *dic = self.table;
    NSNumber *handleKey = [NSNumber numberWithUnsignedShort:Handle];
    NSMutableArray<RYDataRouterBlock *> *blocks = [[NSMutableArray alloc] init];
    for (int i = 0; i < count; i++) {
        NSNumber *_key = [NSNumber numberWithUnsignedChar:head[i]];
        if (dic[_key] && [dic[_key] isKindOfClass:[NSMutableDictionary class]]) {
            dic = dic[_key];
            if (dic[handleKey]) {
                [blocks addObject:dic[handleKey]];
            }
        }else {
            return blocks.lastObject;
        }
    }
    RYDataRouterBlock *block = [[RYDataRouterBlock alloc] init];
    block.minDataLength = NSIntegerMax;
    return block;
}

@end

@implementation RYNotHandlingResolver
@synthesize resolvedBlock;

- (void)readInput:(NSData *)data {
    
    if (self.resolvedBlock) {
        self.resolvedBlock(data);
    }
}

@end

@interface RYCommonResolver ()

@property (nonatomic, strong) NSMutableData *cacheData;

@property (nonatomic, strong) NSMutableData *handleFailData;

@end

@implementation RYCommonResolver
@synthesize resolvedBlock;

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.cacheData = [[NSMutableData alloc] init];
        self.handleFailData = [[NSMutableData alloc] init];
        self.router = [[RYDataRouter alloc] init];
        [self registerHandle];
    }
    return self;
}

- (void)registerHandle {
    
}

- (void)readInput:(nonnull NSData *)data { 
    
    [self.cacheData appendData:data];
    [self resolveData];
}

- (void)handleNotResolvedData {
    
    if (self.handleFailData.length > 0) {
        NSData *data = self.handleFailData;
        self.handleFailData = [[NSMutableData alloc] init];
        if (self.handleFailBlock) {
            self.handleFailBlock(data);
        }
    }
}

- (void)resolveData {
    
    if (self.cacheData.length == 0) {
        [self handleNotResolvedData];
        return;
    }
    RYDataRouterBlock *block = [self.router handle:self.cacheData];
    if (block) {
        if (self.cacheData.length < block.minDataLength) {
            return;
        }else {
            RYCommonResolverModel *model = block.handleBlock(self.cacheData);
            if (model) {
                [self handleNotResolvedData];
                NSRange range = NSMakeRange(0, model.cost);
                [self.cacheData replaceBytesInRange:range withBytes:NULL length:0];
                if (self.resolvedBlock && !model.isDiscardable) {
                    self.resolvedBlock(model);
                }
                [self resolveData];
            }
        }
    }else {
        [self.cacheData replaceBytesInRange:NSMakeRange(0, 1) withBytes:NULL length:0];
        [self resolveData];
    }
}

@end
