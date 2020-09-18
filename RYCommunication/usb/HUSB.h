//
//  HUSB.h
//  USBExample
//
//  Created by ldc on 2019/11/21.
//  Copyright © 2019 Xiamen Hanin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "base.h"

typedef NSString * HUSBPredicateKey;

NS_ASSUME_NONNULL_BEGIN

OBJC_EXTERN HUSBPredicateKey HUSBVendorIdKey;

OBJC_EXTERN HUSBPredicateKey HUSBProductIdKey;

OBJC_EXTERN NSErrorDomain HUSBConnectErrorDomain;

typedef NS_ENUM(NSUInteger, HUSBConnectErrorCode) {
    HUSBConnectErrorCodeDidConnect,
    HUSBConnectErrorCodeCreatePlugInInterface,
    HUSBConnectErrorCodeQueryInterface,
    HUSBConnectErrorCodeInterfaceOpen,
    HUSBConnectErrorCodeGetNumEndpoints,
    HUSBConnectErrorCodeOutPipeNotFound,
    HUSBConnectErrorCodeInPipeNotFound,
    HUSBConnectErrorCodeCreateAsyncEventSource,
    HUSBConnectErrorCodeBeginReadPipe,
    HUSBConnectErrorCodeInterfaceinterfaceServiceNotFound,
    HUSBConnectErrorCodeAuthTimeout,
    HUSBConnectErrorCodeAuthFail,
};

@interface HUSBDevice : NSObject <RYAccessory>

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

@interface HUSBBrowser : NSObject

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
@property (nonatomic, strong) NSMutableArray<HUSBDevice *> *interfaces;

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
@property (nonatomic, copy) void (^ _Nullable interfaceAddBlock)(HUSBDevice *);

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
@property (nonatomic, copy) void (^ _Nullable interfaceRemoveBlock)(HUSBDevice *);

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
- (BOOL)scanInterfaces:(NSDictionary<HUSBPredicateKey, id> * _Nullable) predicate;

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
