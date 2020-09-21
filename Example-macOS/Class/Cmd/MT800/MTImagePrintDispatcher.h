//
//  MTImagePrintDispatcher.h
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

OBJC_EXTERN NSErrorDomain MTImagePrintDispatcherErrorDomain;

typedef NS_ENUM(NSUInteger, MTImagePrintDispatcherErrorCode) {
    MTImagePrintDispatcherErrorCodeTimeoutTooMuch,
};
//图片分包发送调度器，基本流程是先发第一包，ACK正常后，后续分包缓存区最多保留两包的数据
@interface MTImagePrintDispatcher : NSObject

@property (nonatomic, copy) void (^ completeBlock)(NSError * _Nullable);

@property (nonatomic, weak) id<RYAccessory> transmitter;

@property (nonatomic, assign) NSInteger maxResendCount;

- (void)start;

- (void)stop;

- (void)readSliceAck:(MTResolverModel *)model;

- (instancetype)initWithBitmap:(NSData *)bitmap height:(uint16_t)height transmitter:(id<RYAccessory>)transmitter;

@end

NS_ASSUME_NONNULL_END
