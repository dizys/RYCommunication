//
//  HBluetoothBrowser.h
//  Bluetooth
//
//  Created by ldc on 2019/11/26.
//  Copyright © 2019 Xiamen Hanin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "base.h"

NS_ASSUME_NONNULL_BEGIN

OBJC_EXTERN NSErrorDomain HBluetoothConnectErrorDomain;

typedef NS_ENUM(NSUInteger, HBluetoothConnectErrorCode) {
    HBluetoothConnectErrorCodeDidConnect,
    HBluetoothConnectErrorCodeOpenBaseband,
    HBluetoothConnectErrorCodeSDPQuery,
    HBluetoothConnectErrorCodeSDPServiceNotFound,
    HBluetoothConnectErrorCodeGetRFCOMMChannel,
    HBluetoothConnectErrorCodeOpenRFCOMMChannel,
    HBluetoothConnectErrorCodeAuthTimeout,
    HBluetoothConnectErrorCodeAuthFail,
};

@interface HBluetoothDevice : NSObject <RYAccessory>

@end

@interface HBluetoothBrowser : NSObject

/*!
 *  \~chinese
 *
 *  扫描发现的设备列表
 *
 *  \~english
 *
 *
 *
 */
@property (nonatomic, strong, readonly) NSArray<HBluetoothDevice *> *devices;

/*!
 *  \~chinese
 *
 *  开始扫描设备.
 *
 *  @note 一段时间后,自动结束扫描,调用completeBlock.如果没有发现需要的设备,继续调用本接口.
 *
 *  @param clearFoundDevice 是否清除已发现的设备
 *  @param completeBlock 扫描完成回调
 *
 *  \~english
 *
 *
 *
 */
- (void)startScan:(BOOL)clearFoundDevice complete:(void(^)(void))completeBlock;

/*!
 *  \~chinese
 *
 *  提前结束扫描.
 *
 *  @param clearFoundDevice 是否清除已发现的设备
 *
 *  \~english
 *
 *
 *
 */
- (void)stopScan:(BOOL)clearFoundDevice;

@end

NS_ASSUME_NONNULL_END
