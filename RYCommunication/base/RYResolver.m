//
//  RYNotHandlingResolver.m
//  RYCommunication
//
//  Created by ldc on 2020/9/7.
//  Copyright © 2020 Xiamen Hanin. All rights reserved.
//

#import "RYResolver.h"

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

@end

@implementation RYCommonResolver
@synthesize resolvedBlock;

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.cacheData = [[NSMutableData alloc] init];
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

- (void)resolveData {
    
    if (self.cacheData.length == 0) {
        return;
    }
    RYDataRouterBlock *block = [self.router handle:self.cacheData];
    if (block) {
        if (self.cacheData.length < block.minDataLength) {
            return;
        }else {
            RYCommonResolverModel *model = block.handleBlock(self.cacheData);
            if (model) {
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
