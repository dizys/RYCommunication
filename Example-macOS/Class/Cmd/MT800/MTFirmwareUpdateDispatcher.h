//
//  MTFirmwareUpdateDispatcher.h
//  Example
//
//  Created by ldc on 2020/4/17.
//  Copyright © 2020 Xiamen Hanin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MTCmdGenerator.h"
#import "HDataResolver.h"
#import <RYCommunication/RYCommunication.h>

NS_ASSUME_NONNULL_BEGIN

OBJC_EXTERN NSErrorDomain MTFirmwareUpdateDispatcherErrorDomain;

typedef NS_ENUM(NSUInteger, MTFirmwareUpdateDispatcherErrorCode) {
    MTFirmwareUpdateDispatcherErrorCodeTimeoutTooMuch,
};
//固件分包发送调度器，分包缓存区最多保留两包的数据
@interface MTFirmwareUpdateDispatcher : NSObject

@property (nonatomic, copy) void (^ _Nullable completeBlock)(NSError * _Nullable);

@property (nonatomic, weak) id<RYAccessory> transmitter;

@property (nonatomic, copy) void (^ _Nullable progressBlock)(NSProgress *);

@property (nonatomic, assign) NSInteger maxResendCount;

- (void)start;

- (void)readSliceAck:(MTResolverModel *)model;

- (instancetype)initWithBinary:(NSData *)binary transmitter:(id<RYAccessory>)transmitter;

@end

NS_ASSUME_NONNULL_END
