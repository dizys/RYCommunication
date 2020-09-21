//
//  RYUSB.h
//  USBExample
//
//  Created by ldc on 2019/11/21.
//  Copyright © 2019 Xiamen Hanin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "base.h"

typedef NSString * RYUSBPredicateKey;

NS_ASSUME_NONNULL_BEGIN

OBJC_EXTERN RYUSBPredicateKey RYUSBVendorIdKey;

OBJC_EXTERN RYUSBPredicateKey RYUSBProductIdKey;

OBJC_EXTERN NSErrorDomain RYUSBConnectErrorDomain;

typedef NS_ENUM(NSUInteger, RYUSBConnectErrorCode) {
    RYUSBConnectErrorCodeDidConnect,
    RYUSBConnectErrorCodeCreatePlugInInterface,
    RYUSBConnectErrorCodeQueryInterface,
    RYUSBConnectErrorCodeInterfaceOpen,
    RYUSBConnectErrorCodeGetNumEndpoints,
    RYUSBConnectErrorCodeOutPipeNotFound,
    RYUSBConnectErrorCodeInPipeNotFound,
    RYUSBConnectErrorCodeCreateAsyncEventSource,
    RYUSBConnectErrorCodeBeginReadPipe,
    RYUSBConnectErrorCodeInterfaceinterfaceServiceNotFound,
    RYUSBConnectErrorCodeAuthTimeout,
    RYUSBConnectErrorCodeAuthFail,
};

@interface RYUSBAccessory : NSObject <RYAccessory>

/*!
 *  \~chinese
 *
 *  厂商ID
 *
 *  \~english
 *
 *  Vendor ID
 *
 */
@property (nonatomic, assign) UInt16 vendorId;

/*!
 *  \~chinese
 *
 *  产品ID
 *
 *  \~english
 *
 *  Product ID
 *
 */
@property (nonatomic, assign) UInt16 productId;

@end

@interface RYUSBBrowser : NSObject

@property (nonatomic, assign) BOOL isScanning;

+ (instancetype)share;

/*!
 *  \~chinese
 *
 *  已扫描到的接口列表
 *
 *  \~english
 *
 *
 *
 */
@property (nonatomic, strong) NSMutableArray<RYUSBAccessory *> *interfaces;

/*!
 *  \~chinese
 *
 *  发现新设备接口回调
 *
 *  \~english
 *
 *
 *
 */
@property (nonatomic, copy) void (^ _Nullable interfaceAddBlock)(RYUSBAccessory *);

/*!
 *  \~chinese
 *
 *   设备接口被移除回调
 *
 *  \~english
 *
 *
 *
 */
@property (nonatomic, copy) void (^ _Nullable interfaceRemoveBlock)(RYUSBAccessory *);

/*!
 *  \~chinese
 *
 *  根据选项搜索设备
 *
 *  @param predicate 搜索条件
 *
 *  \~english
 *
 *
 *
 */
- (BOOL)scanInterfaces:(NSDictionary<RYUSBPredicateKey, id> * _Nullable) predicate;

/*
 *  \~chinese
 *
 *  停止搜索设备
 *
 *  @note 当有USB设备已连接时，建议不停止扫描，在此情况下如停止扫描，可能导致USB设备某些情况监听不到断开消息
 *
 *  \~english
 *
 *
 *
 */
- (void)stopScanInterfaces;

@end

NS_ASSUME_NONNULL_END
