//
//  MTFirmwareUpdateDispatcher.m
//  Example
//
//  Created by ldc on 2020/4/17.
//  Copyright © 2020 Xiamen Hanin. All rights reserved.
//

#import "MTFirmwareUpdateDispatcher.h"

NSErrorDomain MTFirmwareUpdateDispatcherErrorDomain = @"firmware.dispatcher.error.domain";

@interface MTFirmwareUpdateDispatcher ()

@property (nonatomic, strong) NSMutableArray<MTFirmwareSlice *> *slices;

@property (nonatomic, assign) NSInteger resendCount;

@property (nonatomic, assign) UInt64 totalPackageCount;

@property (nonatomic, strong) NSMutableDictionary<NSNumber *, MTFirmwareSlice *> *sendingSlices;

@end

@implementation MTFirmwareUpdateDispatcher

- (instancetype)initWithBinary:(NSData *)binary transmitter:(id<RYAccessory>)transmitter
{
    self = [super init];
    if (self) {
        self.transmitter = transmitter;
        self.slices = [MTCmdGenerator sliceFirmware:binary];
        self.totalPackageCount = self.slices.count;
        self.sendingSlices = [[NSMutableDictionary alloc] init];
        self.maxResendCount = 5;
        NSLog(@"分包数: %lu", (unsigned long)self.slices.count);
    }
    return self;
}

- (void)start {
    
    if (self.slices.count == 0) {
        if (self.completeBlock) {
            self.completeBlock(nil);
        }
        self.completeBlock = nil;
        return;
    }
    MTFirmwareSlice *slice = self.slices[0];
    self.sendingSlices[[NSNumber numberWithUnsignedShort:slice.offset]] = slice;
    [self.slices removeObjectAtIndex:0];
    [self writeSlice:slice];
    
    if (self.slices.count > 0) {
        MTFirmwareSlice *slice2 = self.slices[0];
        self.sendingSlices[[NSNumber numberWithUnsignedShort:slice2.offset]] = slice2;
        [self.slices removeObjectAtIndex:0];
        [self writeSlice:slice2];
    }
}

- (void)writeSlice:(MTFirmwareSlice *)slice {
    
    [self.transmitter write:slice.data progress:nil];
    slice.timer = [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(sendTimeout:) userInfo:slice repeats:false];
}

- (void)readSliceAck:(MTResolverModel *)model {
    
    uint16_t offset = *((uint32_t *)model.data.bytes);
    MTFirmwareSlice *destinationSlice = self.sendingSlices[[NSNumber numberWithUnsignedShort:offset]];
    if (destinationSlice == nil) {
        return;
    }
    [destinationSlice.timer invalidate];
    destinationSlice.timer = nil;
    BOOL success = ((Byte *)model.data.bytes)[4] == 0;
    if (self.sendingSlices.count == 1) {
        if (self.slices.count == 0) {
            //将要发完
            if (success) {
                self.resendCount = 0;
                [self.sendingSlices removeAllObjects];
                [self updateProgress];
                if (self.completeBlock) {
                    self.completeBlock(nil);
                }
                self.completeBlock = nil;
            }else {
                [self writeSlice:destinationSlice];
            }
        }else {
            //刚开始发
            if (success) {
                self.resendCount = 0;
                [self.sendingSlices removeObjectForKey:[NSNumber numberWithUnsignedShort:offset]];
                [self updateProgress];
                if (self.slices.count > 0) {
                    MTFirmwareSlice *slice = self.slices[0];
                    self.sendingSlices[[NSNumber numberWithUnsignedShort:slice.offset]] = slice;
                    [self.slices removeObjectAtIndex:0];
                    [self writeSlice:slice];
                }
            }else {
                [destinationSlice.timer invalidate];
                [self writeSlice:destinationSlice];
            }
        }
    }else {
        if (success) {
            self.resendCount = 0;
            [self.sendingSlices removeObjectForKey:[NSNumber numberWithUnsignedShort:offset]];
            [self updateProgress];
            if (self.slices.count > 0) {
                MTFirmwareSlice *slice = self.slices[0];
                self.sendingSlices[[NSNumber numberWithUnsignedShort:slice.offset]] = slice;
                [self.slices removeObjectAtIndex:0];
                [self writeSlice:slice];
            }
        }else {
            [self writeSlice:destinationSlice];
        }
    }
}

- (void)updateProgress {
    
    if (self.progressBlock) {
        NSProgress *progress = [[NSProgress alloc] init];
        progress.totalUnitCount = self.totalPackageCount;
        progress.completedUnitCount = self.totalPackageCount - self.slices.count - self.sendingSlices.count;
        self.progressBlock(progress);
    }
}

- (void)sendTimeout: (NSTimer *)timer {
    
    self.resendCount += 1;
    if (self.resendCount > self.maxResendCount) {
        for (MTFirmwareSlice *slice in self.sendingSlices.allValues) {
            [slice.timer invalidate];
            slice.timer = nil;
        }
        [self.sendingSlices removeAllObjects];
        if (self.completeBlock) {
            self.completeBlock([NSError errorWithDomain:MTFirmwareUpdateDispatcherErrorDomain code:MTFirmwareUpdateDispatcherErrorCodeTimeoutTooMuch userInfo:nil]);
        }
        self.completeBlock = nil;
    }else {
        MTFirmwareSlice *slice = (MTFirmwareSlice *)timer.userInfo;
        NSLog(@"重发固件 偏移: %u", slice.offset);
        [self writeSlice:slice];
    }
}

@end
