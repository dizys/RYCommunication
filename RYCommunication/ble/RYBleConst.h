//
//  RYBleConst.h
//  HYEditor
//
//  Created by ldc on 2019/12/18.
//  Copyright © 2019 swiftHY. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

OBJC_EXTERN NSErrorDomain RYBleConnectErrorDomain;

typedef NS_ENUM(NSInteger, RYBleConnectErrorCode) {
    RYBleConnectErrorCodeSystemError,
    RYBleConnectErrorCodeTimeout,
    RYBleConnectErrorCodeServiceNotFound,
    RYBleConnectErrorCodeCharacteristicNotFound,
    RYBleConnectErrorCodeAuthFail,
    RYBleConnectErrorCodeAuthTimeout,
};

NS_ASSUME_NONNULL_END
