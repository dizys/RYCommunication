//
//  RYDataRouter.m
//  RYCommunication
//
//  Created by ldc on 2020/9/10.
//  Copyright © 2020 Xiamen Hanin. All rights reserved.
//

#import "RYDataRouter.h"

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
