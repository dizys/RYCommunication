//
//  MTImagePrintDispatcher.m
//  Example
//
//  Created by ldc on 2020/4/17.
//  Copyright © 2020 Xiamen Hanin. All rights reserved.
//

#import "MTImagePrintDispatcher.h"
#if NeedLog
#import <HPrint-Swift.h>
#endif

static CFAbsoluteTime start;

NSErrorDomain MTImagePrintDispatcherErrorDomain = @"image.dispatcher.error.domain";

@interface MTImagePrintDispatcher ()

@property (nonatomic, strong) NSMutableArray<MTBitmapSlice *> *slices;

@property (nonatomic, strong) NSMutableArray<MTBitmapSlice *> *sendingSlices;

@property (nonatomic, assign) NSInteger resendCount;

@end

@implementation MTImagePrintDispatcher

- (instancetype)initWithBitmap:(NSData *)bitmap height:(uint16_t)height transmitter:(id<RYAccessory>)transmitter
{
    self = [super init];
    if (self) {
        self.transmitter = transmitter;
        self.slices = [MTCmdGenerator sliceImageBitmap:bitmap height:height];
        self.sendingSlices = [[NSMutableArray alloc] init];
        self.maxResendCount = 5;
        NSLog(@"图片分包总数: %lu", (unsigned long)self.slices.count);
    }
    return self;
}

- (void)start {
    
    if (self.slices.count == 0) {
        if (self.completeBlock) {
            self.completeBlock(nil);
        }
        return;
    }
    start = CFAbsoluteTimeGetCurrent();
    MTBitmapSlice *slice = self.slices[0];
    [self.sendingSlices addObject:slice];
    [self.slices removeObjectAtIndex:0];
    [self writeSlice:slice];
    NSLog(@"开始: %lf", CFAbsoluteTimeGetCurrent());
}

- (void)stop {
    
    for (MTBitmapSlice *slice in self.sendingSlices) {
        [slice.timer invalidate];
    }
    [self.sendingSlices removeAllObjects];
    [self.slices removeAllObjects];
}

- (void)writeSlice:(MTBitmapSlice *)slice {
    
    [self.transmitter write:slice.data progress:nil];
    NSLog(@"发送图片分包: id => %u", slice.serial);
    slice.timer = [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(sendTimeout:) userInfo:slice repeats:false];
}

- (void)readSliceAck:(MTResolverModel *)model {
    
    NSLog(@"%lf", CFAbsoluteTimeGetCurrent());
    uint16_t serialId = *((uint16_t *)model.data.bytes);
    if (self.sendingSlices.count == 0) {
        return;
    }
    MTBitmapSlice *destinationSlice = self.sendingSlices[0];
    if (destinationSlice.serial != serialId) {
        return;
    }
    [destinationSlice.timer invalidate];
    destinationSlice.timer = nil;
    BOOL success = ((Byte *)model.data.bytes)[2] == 0;
    if (!success) {
        NSLog(@"分包发送失败 包序号 => %u  错误码%02x", destinationSlice.serial, ((Byte *)model.data.bytes)[2]);
    }
    if (self.sendingSlices.count == 1) {
        if (self.slices.count == 0) {
            //将要发完
            if (success) {
                self.resendCount = 0;
                [self.sendingSlices removeAllObjects];
                if (self.completeBlock) {
                    self.completeBlock(nil);
                }
            }else {
                [self writeSlice:destinationSlice];
            }
        }else {
            //刚开始发
            if (success) {
                [self.sendingSlices removeAllObjects];
                
                MTBitmapSlice *slice1 = self.slices[0];
                [self.sendingSlices addObject:slice1];
                [self.slices removeObjectAtIndex:0];
                [self writeSlice:slice1];
                
                if (self.slices.count > 0) {
                    MTBitmapSlice *slice2 = self.slices[0];
                    [self.sendingSlices addObject:slice2];
                    [self.slices removeObjectAtIndex:0];
                    [self writeSlice:slice2];
                }
            }else {
                [destinationSlice.timer invalidate];
                [self writeSlice:destinationSlice];
            }
        }
    }else {
        if (success) {
            self.resendCount = 0;
            [self.sendingSlices removeObjectAtIndex:0];
            if (self.slices.count > 0) {
                MTBitmapSlice *slice = self.slices[0];
                [self.sendingSlices addObject:slice];
                [self.slices removeObjectAtIndex:0];
                [self writeSlice:slice];
            }
        }else {
            for (MTBitmapSlice *slice in self.sendingSlices) {
                [slice.timer invalidate];
                [self writeSlice:slice];
            }
        }
    }
}

- (void)sendTimeout: (NSTimer *)timer {
    
    self.resendCount += 1;
    if (self.resendCount > self.maxResendCount) {
        for (MTBitmapSlice *slice in self.sendingSlices) {
            [slice.timer invalidate];
            slice.timer = nil;
        }
        [self.sendingSlices removeAllObjects];
        [self.slices removeAllObjects];
        if (self.completeBlock) {
            self.completeBlock([NSError errorWithDomain:MTImagePrintDispatcherErrorDomain code:MTImagePrintDispatcherErrorCodeTimeoutTooMuch userInfo:nil]);
        }
    }else {
        MTBitmapSlice *slice = (MTBitmapSlice *)timer.userInfo;
        NSLog(@"分包超时 包序号 => %u", slice.serial);
        for (MTBitmapSlice *slice in self.sendingSlices) {
            [slice.timer invalidate];
            [self writeSlice:slice];
        }
    }
}

@end
